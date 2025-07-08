#!/bin/bash
# Test Runner for Zellij Utils
# Runs all available tests and provides a comprehensive report

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXIT_CODE=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test results tracking
declare -A TEST_RESULTS=()
declare -A TEST_TIMES=()

# Utilities
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    EXIT_CODE=1
}

log_header() {
    echo ""
    echo -e "${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

# Run a single test suite
run_test() {
    local test_name="$1"
    local test_script="$2"
    local description="$3"
    
    log_header "Running $test_name"
    echo "Description: $description"
    echo ""
    
    if [[ ! -f "$test_script" ]]; then
        log_error "Test script not found: $test_script"
        TEST_RESULTS["$test_name"]="MISSING"
        return 1
    fi
    
    if [[ ! -x "$test_script" ]]; then
        log_error "Test script not executable: $test_script"
        TEST_RESULTS["$test_name"]="NOT_EXECUTABLE"
        return 1
    fi
    
    local start_time=$(date +%s)
    local temp_log="/tmp/zellij-test-$test_name-$$.log"
    
    if bash "$test_script" >"$temp_log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        TEST_RESULTS["$test_name"]="PASSED"
        TEST_TIMES["$test_name"]="$duration"
        
        log_info "$test_name completed successfully in ${duration}s"
        
        # Show test output
        if [[ -s "$temp_log" ]]; then
            echo ""
            echo "Test Output:"
            echo "------------"
            cat "$temp_log"
        fi
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        TEST_RESULTS["$test_name"]="FAILED"
        TEST_TIMES["$test_name"]="$duration"
        EXIT_CODE=1
        
        log_error "$test_name failed after ${duration}s"
        
        # Show failure output
        if [[ -s "$temp_log" ]]; then
            echo ""
            echo "Failure Output:"
            echo "---------------"
            cat "$temp_log"
        fi
    fi
    
    # Cleanup
    rm -f "$temp_log"
    echo ""
}

# Run all test suites
run_all_tests() {
    log_header "Zellij Utils - Complete Test Suite"
    echo "Running all available tests for production readiness"
    echo ""
    
    # Ensure we're in the right directory
    cd "$PROJECT_ROOT"
    
    # Run each test suite
    run_test "Integration Tests" \
             "$SCRIPT_DIR/integration_tests.sh" \
             "Tests installation process and core functionality"
    
    run_test "Compatibility Tests" \
             "$SCRIPT_DIR/compatibility_tests.sh" \
             "Tests compatibility across shells, systems, and configurations"
}

# Generate test report
generate_report() {
    log_header "Test Results Summary"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local missing_tests=0
    local total_time=0
    
    for test_name in "${!TEST_RESULTS[@]}"; do
        local result="${TEST_RESULTS[$test_name]}"
        local time="${TEST_TIMES[$test_name]:-0}"
        
        total_tests=$((total_tests + 1))
        total_time=$((total_time + time))
        
        case "$result" in
            "PASSED")
                echo -e "${GREEN}✅ $test_name${NC} (${time}s)"
                passed_tests=$((passed_tests + 1))
                ;;
            "FAILED")
                echo -e "${RED}❌ $test_name${NC} (${time}s)"
                failed_tests=$((failed_tests + 1))
                ;;
            "MISSING"|"NOT_EXECUTABLE")
                echo -e "${YELLOW}⚠️  $test_name${NC} ($result)"
                missing_tests=$((missing_tests + 1))
                ;;
        esac
    done
    
    echo ""
    echo -e "${BOLD}Overall Results:${NC}"
    echo "  Total Tests: $total_tests"
    echo "  Passed: $passed_tests"
    echo "  Failed: $failed_tests"
    echo "  Missing/Issues: $missing_tests"
    echo "  Total Time: ${total_time}s"
    echo ""
    
    # Production readiness assessment
    if [[ $failed_tests -eq 0 ]] && [[ $missing_tests -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 PRODUCTION READY${NC}"
        echo "All tests passed! The project is ready for production deployment."
    elif [[ $failed_tests -eq 0 ]] && [[ $missing_tests -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}⚠️  PRODUCTION READY WITH WARNINGS${NC}"
        echo "Core functionality works but some test issues were found."
    else
        echo -e "${RED}${BOLD}❌ NOT PRODUCTION READY${NC}"
        echo "Critical test failures detected. Address issues before production deployment."
    fi
}

# Generate detailed report file
generate_file_report() {
    local report_file="test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Zellij Utils - Test Report"
        echo "=========================="
        echo "Generated: $(date)"
        echo "Project: $(pwd)"
        echo ""
        
        echo "Environment Information:"
        echo "  OS: $(uname -s) $(uname -r)"
        echo "  Shell: $SHELL"
        echo "  User: $USER"
        echo "  Home: $HOME"
        echo ""
        
        echo "Test Results:"
        for test_name in "${!TEST_RESULTS[@]}"; do
            local result="${TEST_RESULTS[$test_name]}"
            local time="${TEST_TIMES[$test_name]:-0}"
            echo "  $test_name: $result (${time}s)"
        done
        echo ""
        
        echo "Exit Code: $EXIT_CODE"
        
    } > "$report_file"
    
    log_info "Detailed report saved to: $report_file"
}

# Clean up any test artifacts
cleanup() {
    log_info "Cleaning up test artifacts..."
    
    # Remove any temporary files
    rm -f /tmp/zellij-test-* 2>/dev/null || true
    
    # Remove any test directories that might have been left
    rm -rf /tmp/zellij-utils-test-* 2>/dev/null || true
    rm -rf /tmp/zellij-utils-backup-* 2>/dev/null || true
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run comprehensive test suite for Zellij Utils

OPTIONS:
    -h, --help         Show this help message
    -q, --quiet        Run tests quietly (less output)
    -r, --report-only  Generate report from previous test run
    --cleanup          Clean up test artifacts and exit

EXAMPLES:
    $0                 Run all tests
    $0 --quiet         Run tests with minimal output
    $0 --cleanup       Clean up test files

EOF
}

# Parse command line options
parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -q|--quiet)
                exec 1>/dev/null  # Redirect stdout to suppress output
                ;;
            --cleanup)
                cleanup
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

# Main execution
main() {
    # Parse command line options
    parse_options "$@"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run all tests
    run_all_tests
    
    # Generate reports
    generate_report
    generate_file_report
    
    # Final exit
    exit $EXIT_CODE
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi