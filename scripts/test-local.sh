#!/bin/bash
# Local Test Runner with Session Isolation
# Provides safe local testing with proper cleanup

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$HOME/.zellij-utils-test-backup"
RESTORE_NEEDED=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Local test runner with session isolation for Zellij Utils

COMMANDS:
    run                Run all tests with session isolation
    backup             Backup current zellij configuration
    restore            Restore zellij configuration from backup
    clean              Clean up test artifacts
    status             Show current test environment status
    help               Show this help message

OPTIONS:
    -v, --verbose      Enable verbose output
    -s, --skip-backup  Skip configuration backup (risky)
    -f, --force        Force operations without confirmation
    --docker-only      Recommend using Docker instead (safer)

EXAMPLES:
    $0 run                    # Run tests with full isolation
    $0 backup                 # Backup current configuration
    $0 restore                # Restore from backup
    $0 clean                  # Clean up test artifacts

SAFETY WARNING:
    Local testing may interfere with active Zellij sessions.
    Consider using 'scripts/test-docker.sh' for complete isolation.

EOF
}

# Parse command line options
VERBOSE=false
SKIP_BACKUP=false
FORCE=false
DOCKER_ONLY=false

parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                ;;
            -s|--skip-backup)
                SKIP_BACKUP=true
                ;;
            -f|--force)
                FORCE=true
                ;;
            --docker-only)
                DOCKER_ONLY=true
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
        shift
    done
}

# Check if Docker is available and recommend it
check_docker_availability() {
    if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
        log_warning "Docker is available on your system"
        log_info "For complete session isolation, consider using:"
        log_info "  ./scripts/test-docker.sh run"
        echo ""
        
        if [[ "$DOCKER_ONLY" == "true" ]]; then
            log_info "Switching to Docker-based testing..."
            exec "$PROJECT_ROOT/scripts/test-docker.sh" run
        fi
        
        if [[ "$FORCE" != "true" ]]; then
            echo -n "Continue with local testing? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Switching to Docker-based testing..."
                exec "$PROJECT_ROOT/scripts/test-docker.sh" run
            fi
        fi
    else
        log_warning "Docker not available, proceeding with local testing"
    fi
}

# Backup current Zellij configuration
backup_zellij_config() {
    if [[ "$SKIP_BACKUP" == "true" ]]; then
        log_warning "Skipping configuration backup (risky)"
        return 0
    fi
    
    log_header "Backing Up Zellij Configuration"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Backup configuration files
    local backed_up=false
    
    if [[ -d "$HOME/.config/zellij" ]]; then
        log_info "Backing up ~/.config/zellij"
        cp -r "$HOME/.config/zellij" "$BACKUP_DIR/config-zellij"
        backed_up=true
    fi
    
    if [[ -d "$HOME/.cache/zellij" ]]; then
        log_info "Backing up ~/.cache/zellij"
        cp -r "$HOME/.cache/zellij" "$BACKUP_DIR/cache-zellij"
        backed_up=true
    fi
    
    if [[ -f "$HOME/.config/shell/zellij-utils.sh" ]]; then
        log_info "Backing up ~/.config/shell/zellij-utils.sh"
        mkdir -p "$BACKUP_DIR/shell"
        cp "$HOME/.config/shell/zellij-utils.sh" "$BACKUP_DIR/shell/"
        backed_up=true
    fi
    
    if [[ "$backed_up" == "true" ]]; then
        RESTORE_NEEDED=true
        log_success "Configuration backed up to: $BACKUP_DIR"
    else
        log_info "No existing configuration found to backup"
    fi
}

# Restore Zellij configuration from backup
restore_zellij_config() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "No backup directory found: $BACKUP_DIR"
        return 0
    fi
    
    log_header "Restoring Zellij Configuration"
    
    # Restore configuration files
    local restored=false
    
    if [[ -d "$BACKUP_DIR/config-zellij" ]]; then
        log_info "Restoring ~/.config/zellij"
        rm -rf "$HOME/.config/zellij"
        cp -r "$BACKUP_DIR/config-zellij" "$HOME/.config/zellij"
        restored=true
    fi
    
    if [[ -d "$BACKUP_DIR/cache-zellij" ]]; then
        log_info "Restoring ~/.cache/zellij"
        rm -rf "$HOME/.cache/zellij"
        cp -r "$BACKUP_DIR/cache-zellij" "$HOME/.cache/zellij"
        restored=true
    fi
    
    if [[ -f "$BACKUP_DIR/shell/zellij-utils.sh" ]]; then
        log_info "Restoring ~/.config/shell/zellij-utils.sh"
        mkdir -p "$HOME/.config/shell"
        cp "$BACKUP_DIR/shell/zellij-utils.sh" "$HOME/.config/shell/"
        restored=true
    fi
    
    if [[ "$restored" == "true" ]]; then
        log_success "Configuration restored from backup"
    else
        log_info "No backup found to restore"
    fi
    
    # Clean up backup directory
    rm -rf "$BACKUP_DIR"
    RESTORE_NEEDED=false
}

# Clean up active Zellij sessions
cleanup_zellij_sessions() {
    log_header "Cleaning Up Zellij Sessions"
    
    # Check for active sessions
    local active_sessions=""
    if command -v zellij >/dev/null 2>&1; then
        active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "No active sessions" || true)
    fi
    
    if [[ -n "$active_sessions" ]]; then
        log_warning "Active Zellij sessions detected:"
        echo "$active_sessions"
        
        if [[ "$FORCE" != "true" ]]; then
            echo -n "Kill all active sessions? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_error "Cannot run tests with active sessions"
                return 1
            fi
        fi
        
        # Kill all active sessions
        log_info "Killing all active Zellij sessions..."
        pkill -f zellij 2>/dev/null || true
        sleep 2
    fi
    
    # Clean up session files
    rm -rf /tmp/zellij-* 2>/dev/null || true
    rm -rf "$HOME/.cache/zellij/"* 2>/dev/null || true
    
    log_success "Zellij sessions cleaned up"
}

# Set up test environment
setup_test_environment() {
    log_header "Setting Up Test Environment"
    
    # Set environment variables for testing
    export ZJ_TEST_MODE=1
    export ZJ_DISABLE_AUTO=1
    export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
    
    # Create test configuration directory
    mkdir -p "$HOME/.config/zellij"
    mkdir -p "$HOME/.config/shell"
    
    log_success "Test environment set up"
}

# Run local tests with isolation
run_local_tests() {
    log_header "Running Local Tests with Session Isolation"
    
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    # Set up test environment
    setup_test_environment
    
    # Run the test suite
    if [[ -f "$PROJECT_ROOT/tests/run_all_tests.sh" ]]; then
        log_info "Running test suite..."
        bash "$PROJECT_ROOT/tests/run_all_tests.sh"
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            log_success "All tests passed!"
        else
            log_error "Some tests failed (exit code: $exit_code)"
        fi
        
        return $exit_code
    else
        log_error "Test suite not found: $PROJECT_ROOT/tests/run_all_tests.sh"
        return 1
    fi
}

# Show test environment status
show_status() {
    log_header "Test Environment Status"
    
    # Check for active sessions
    if command -v zellij >/dev/null 2>&1; then
        log_info "Active Zellij sessions:"
        zellij list-sessions 2>/dev/null || log_info "No active sessions"
    else
        log_warning "Zellij not installed"
    fi
    
    # Check for backup
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backup directory exists: $BACKUP_DIR"
    else
        log_info "No backup directory found"
    fi
    
    # Check for test artifacts
    if [[ -d "$PROJECT_ROOT/test-results-local" ]]; then
        log_info "Local test results available: $PROJECT_ROOT/test-results-local"
    else
        log_info "No local test results found"
    fi
    
    # Check Docker availability
    if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
        log_info "Docker available for safer testing"
    else
        log_warning "Docker not available"
    fi
}

# Clean up test artifacts
cleanup_test_artifacts() {
    log_header "Cleaning Up Test Artifacts"
    
    # Remove test results
    rm -rf "$PROJECT_ROOT/test-results-local" 2>/dev/null || true
    
    # Remove temporary test files
    rm -rf /tmp/zellij-test-* 2>/dev/null || true
    rm -rf /tmp/zellij-utils-test-* 2>/dev/null || true
    
    # Remove backup if it exists
    if [[ -d "$BACKUP_DIR" ]]; then
        rm -rf "$BACKUP_DIR"
    fi
    
    log_success "Test artifacts cleaned up"
}

# Cleanup handler
cleanup_handler() {
    log_info "Cleaning up test environment..."
    
    # Restore configuration if needed
    if [[ "$RESTORE_NEEDED" == "true" ]]; then
        restore_zellij_config
    fi
    
    # Clean up any remaining test processes
    pkill -f zellij 2>/dev/null || true
    
    log_info "Cleanup complete"
}

# Set up signal handlers
trap cleanup_handler EXIT INT TERM

# Main execution
main() {
    # Change to project directory
    cd "$PROJECT_ROOT"
    
    # Parse options
    parse_options "$@"
    
    # Get command
    local command="${1:-help}"
    shift || true
    
    # Execute command
    case "$command" in
        run)
            check_docker_availability
            backup_zellij_config
            cleanup_zellij_sessions
            run_local_tests
            ;;
        backup)
            backup_zellij_config
            ;;
        restore)
            restore_zellij_config
            ;;
        clean)
            cleanup_test_artifacts
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi