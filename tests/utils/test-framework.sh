#!/bin/bash
# Shared test framework utilities for both Docker and native environments

# Test result tracking
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0
declare -a FAILED_TEST_NAMES=()
declare -a TEST_RESULTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Environment detection
detect_environment() {
    if [[ -n "${DOCKER_CONTAINER:-}" ]] || [[ -f /.dockerenv ]]; then
        echo "docker"
    elif [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
        echo "github-actions"
    else
        echo "native"
    fi
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${TEST_OUTPUT_DIR:-/tmp}/test.log" 2>/dev/null || echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${TEST_OUTPUT_DIR:-/tmp}/test.log" 2>/dev/null || echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${TEST_OUTPUT_DIR:-/tmp}/test.log" 2>/dev/null || echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${TEST_OUTPUT_DIR:-/tmp}/test.log" 2>/dev/null || echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Environment-specific setup
setup_test_environment() {
    local env=$(detect_environment)
    log_info "Setting up test environment: $env"
    
    # Common setup
    export ZJ_DISABLE_AUTO=1
    export ZJ_TEST_MODE=1
    export TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-$(pwd)/test-results}"
    
    # Initialize test counters explicitly
    TOTAL_TESTS=0
    PASSED_TESTS=0  
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    FAILED_TEST_NAMES=()
    TEST_RESULTS=()
    
    # Create output directories
    mkdir -p "$TEST_OUTPUT_DIR/logs"
    mkdir -p "$TEST_OUTPUT_DIR/artifacts"
    
    # Environment-specific setup
    case "$env" in
        "docker")
            source "$(dirname "${BASH_SOURCE[0]}")/../local/docker-setup.sh"
            ;;
        "github-actions")
            source "$(dirname "${BASH_SOURCE[0]}")/../ci/github-setup.sh"
            ;;
        "native")
            source "$(dirname "${BASH_SOURCE[0]}")/../ci/native-setup.sh"
            ;;
    esac
    
    log_success "Test environment setup complete for $env"
}

# Run a single test with timeout and error handling
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_category="${3:-general}"
    local test_timeout="${4:-60}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Running test: $test_name"
    
    local test_start_time="$(date +%s)"
    local test_log="$TEST_OUTPUT_DIR/logs/${test_category}_${TOTAL_TESTS}.log"
    local test_result="UNKNOWN"
    
    # Run test with timeout (disable set -e for this test execution)
    set +e  # Temporarily disable set -e for test execution
    timeout "$test_timeout" bash -c "$test_command" >"$test_log" 2>&1
    local test_exit_code=$?
    set -e  # Re-enable set -e
    
    if [[ $test_exit_code -eq 0 ]]; then
        test_result="PASS"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✓ $test_name"
    else
        test_result="FAIL"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        
        if [[ $test_exit_code -eq 124 ]]; then
            log_error "✗ $test_name (TIMEOUT after ${test_timeout}s)"
            test_result="TIMEOUT"
        else
            log_error "✗ $test_name (EXIT CODE: $test_exit_code)"
        fi
        
        # Show error details if verbose
        if [[ "${TEST_VERBOSE:-false}" == "true" ]]; then
            echo "--- Test Output ---"
            cat "$test_log" | head -20
            echo "--- End Output ---"
        fi
    fi
    
    local test_end_time="$(date +%s)"
    local test_duration=$((test_end_time - test_start_time))
    
    # Store test result
    TEST_RESULTS+=("$test_name|$test_result|$test_duration|$test_category|$test_log")
    
    return 0
}

# Check required dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local deps=("zellij" "git" "bash")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    # Check zellij version
    local zellij_version
    zellij_version="$(zellij --version)"
    log_info "Zellij version: $zellij_version"
    
    log_success "All dependencies available"
    return 0
}

# Environment-specific cleanup
cleanup_test_environment() {
    local env=$(detect_environment)
    log_info "Cleaning up test environment: $env"
    
    # SAFETY: Only clean test-specific processes and files in native environment
    if [[ "$env" == "native" ]]; then
        # Only kill test sessions, NEVER kill user's actual zellij sessions
        zellij list-sessions 2>/dev/null | grep -E "(test-|ci-)" | cut -d' ' -f1 | xargs -I{} zellij kill-session {} 2>/dev/null || true
        rm -rf /tmp/zellij-*test* 2>/dev/null || true
        rm -rf /tmp/test-* 2>/dev/null || true
    else
        # Docker/CI environments can be more aggressive
        pkill -f zellij 2>/dev/null || true
        rm -rf /tmp/zellij-* 2>/dev/null || true
    fi
    
    # Environment-specific cleanup
    case "$env" in
        "docker")
            if type docker_cleanup >/dev/null 2>&1; then
                docker_cleanup
            fi
            ;;
        "github-actions"|"native")
            if type native_cleanup >/dev/null 2>&1; then
                native_cleanup
            fi
            ;;
    esac
    
    log_info "Cleanup complete"
}

# Generate test results report
generate_test_report() {
    log_info "Generating test results report..."
    
    local env=$(detect_environment)
    local end_time="$(date '+%Y-%m-%d %H:%M:%S')"
    local success_rate=0
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    fi
    
    # Generate markdown report
    cat > "$TEST_OUTPUT_DIR/test_results.md" << EOF
# Zellij Utils Test Results

## Test Execution Summary

- **Environment:** $env
- **End Time:** $end_time
- **Total Tests:** $TOTAL_TESTS
- **Passed:** $PASSED_TESTS (${success_rate}%)
- **Failed:** $FAILED_TESTS
- **Skipped:** $SKIPPED_TESTS

## Status: $(if [[ $FAILED_TESTS -eq 0 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)

EOF

    # Add detailed results
    for result in "${TEST_RESULTS[@]}"; do
        local test_name="$(echo "$result" | cut -d'|' -f1)"
        local test_result="$(echo "$result" | cut -d'|' -f2)"
        local test_duration="$(echo "$result" | cut -d'|' -f3)"
        
        local status_icon="❓"
        case "$test_result" in
            "PASS") status_icon="✅" ;;
            "FAIL") status_icon="❌" ;;
            "TIMEOUT") status_icon="⏰" ;;
        esac
        
        echo "- $status_icon **$test_name** (${test_duration}s)" >> "$TEST_OUTPUT_DIR/test_results.md"
    done
    
    log_success "Test report generated: $TEST_OUTPUT_DIR/test_results.md"
}

# Final test summary
print_test_summary() {
    log_info "=== Test Execution Complete ==="
    log_info "Environment: $(detect_environment)"
    log_info "Total Tests: $TOTAL_TESTS"
    log_info "Passed: $PASSED_TESTS"
    log_info "Failed: $FAILED_TESTS"
    log_info "Skipped: $SKIPPED_TESTS"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 All tests passed!"
        return 0
    else
        log_error "❌ $FAILED_TESTS test(s) failed."
        return 1
    fi
}