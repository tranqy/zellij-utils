#!/bin/bash
# Docker Test Runner Script
# Provides convenient commands for running containerized tests

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker/docker-compose.yml"

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

Container-based test runner for Zellij Utils

COMMANDS:
    run [ENV]          Run tests in container (default: ubuntu)
    build [ENV]        Build test container image
    clean              Clean up containers and images
    shell [ENV]        Start interactive shell in test container
    logs [ENV]         Show test container logs
    results [ENV]      Extract and display test results
    status             Show container status
    help               Show this help message

ENVIRONMENTS:
    ubuntu (default)   Ubuntu-based test environment
    alpine             Alpine-based test environment

OPTIONS:
    -v, --verbose      Enable verbose output
    -f, --force        Force rebuild of containers
    -d, --detach       Run tests in background
    --no-cleanup       Don't clean up containers after test

EXAMPLES:
    $0 run                    # Run tests in Ubuntu container
    $0 run alpine             # Run tests in Alpine container
    $0 build --force          # Force rebuild of test images
    $0 shell ubuntu           # Start interactive shell
    $0 results alpine         # Show Alpine test results
    $0 clean                  # Clean up all containers

EOF
}

# Parse command line options
VERBOSE=false
FORCE=false
DETACH=false
NO_CLEANUP=false

parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                ;;
            -f|--force)
                FORCE=true
                ;;
            -d|--detach)
                DETACH=true
                ;;
            --no-cleanup)
                NO_CLEANUP=true
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

# Validate environment
validate_environment() {
    local env="${1:-ubuntu}"
    
    case "$env" in
        ubuntu|main)
            echo "zellij-utils-test"
            ;;
        alpine)
            echo "zellij-utils-test-alpine"
            ;;
        *)
            log_error "Invalid environment: $env"
            log_info "Valid environments: ubuntu, alpine"
            exit 1
            ;;
    esac
}

# Build test container
build_container() {
    local env="${1:-ubuntu}"
    local service_name
    service_name=$(validate_environment "$env")
    
    log_header "Building $env Test Container"
    
    cd "$PROJECT_ROOT"
    
    local build_args=""
    if [[ "$FORCE" == "true" ]]; then
        build_args="--no-cache"
    fi
    
    if [[ "$env" == "alpine" ]]; then
        docker compose build $build_args --profile alpine-test "$service_name"
    else
        docker compose -f "$COMPOSE_FILE" build $build_args "$service_name"
    fi
    
    log_success "Container built successfully"
}

# Run tests in container
run_tests() {
    local env="${1:-ubuntu}"
    local service_name
    service_name=$(validate_environment "$env")
    
    log_header "Running Tests in $env Container"
    
    cd "$PROJECT_ROOT"
    
    # Clean up any existing containers
    if [[ "$NO_CLEANUP" != "true" ]]; then
        docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
    fi
    
    # Run tests
    local compose_args=""
    if [[ "$DETACH" == "true" ]]; then
        compose_args="-d"
    else
        compose_args="--abort-on-container-exit"
    fi
    
    if [[ "$env" == "alpine" ]]; then
        docker compose -f "$COMPOSE_FILE" --profile alpine-test up $compose_args "$service_name"
    else
        docker compose -f "$COMPOSE_FILE" up $compose_args "$service_name"
    fi
    
    # Extract results if not in detached mode
    if [[ "$DETACH" != "true" ]]; then
        extract_results "$env"
    fi
    
    log_success "Tests completed"
}

# Start interactive shell
start_shell() {
    local env="${1:-ubuntu}"
    local service_name
    service_name=$(validate_environment "$env")
    
    log_header "Starting Interactive Shell in $env Container"
    
    cd "$PROJECT_ROOT"
    
    # Build if needed
    if ! docker image inspect "$service_name" >/dev/null 2>&1; then
        log_info "Container image not found, building..."
        build_container "$env"
    fi
    
    # Start shell
    if [[ "$env" == "alpine" ]]; then
        docker compose -f "$COMPOSE_FILE" --profile alpine-test run --rm "$service_name" /bin/bash
    else
        docker compose -f "$COMPOSE_FILE" run --rm "$service_name" /bin/bash
    fi
}

# Extract test results
extract_results() {
    local env="${1:-ubuntu}"
    local service_name
    service_name=$(validate_environment "$env")
    
    log_header "Extracting Test Results from $env Container"
    
    # Create results directory
    local results_dir="$PROJECT_ROOT/test-results-$env"
    mkdir -p "$results_dir"
    
    # Copy results from container
    if docker cp "$service_name:/app/test-results/." "$results_dir/" 2>/dev/null; then
        log_success "Results extracted to: $results_dir"
        
        # Show summary if available
        if [[ -f "$results_dir/test_plan_results.md" ]]; then
            log_info "Test results summary:"
            echo ""
            head -30 "$results_dir/test_plan_results.md"
            echo ""
            log_info "Full results available in: $results_dir/test_plan_results.md"
        fi
    else
        log_warning "Could not extract results from container"
    fi
}

# Show container logs
show_logs() {
    local env="${1:-ubuntu}"
    local service_name
    service_name=$(validate_environment "$env")
    
    log_header "Container Logs for $env"
    
    cd "$PROJECT_ROOT"
    docker compose -f "$COMPOSE_FILE" logs "$service_name"
}

# Show container status
show_status() {
    log_header "Container Status"
    
    cd "$PROJECT_ROOT"
    
    log_info "Running containers:"
    docker compose -f "$COMPOSE_FILE" ps
    
    log_info "Docker images:"
    docker images | grep zellij-utils || log_warning "No zellij-utils images found"
    
    log_info "Docker volumes:"
    docker volume ls | grep zellij-utils || log_warning "No zellij-utils volumes found"
}

# Clean up containers and images
cleanup() {
    log_header "Cleaning Up Containers and Images"
    
    cd "$PROJECT_ROOT"
    
    # Stop and remove containers
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
    
    # Remove images
    docker rmi zellij-utils-test 2>/dev/null || true
    docker rmi zellij-utils-test-alpine 2>/dev/null || true
    
    # Clean up Docker system
    docker system prune -f
    
    # Remove local test results
    rm -rf "$PROJECT_ROOT/test-results-"* 2>/dev/null || true
    
    log_success "Cleanup completed"
}

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
            run_tests "$@"
            ;;
        build)
            build_container "$@"
            ;;
        shell)
            start_shell "$@"
            ;;
        logs)
            show_logs "$@"
            ;;
        results)
            extract_results "$@"
            ;;
        status)
            show_status
            ;;
        clean)
            cleanup
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