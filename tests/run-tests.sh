#!/bin/bash
# Universal test runner - works in Docker, GitHub Actions, or native environments

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the test framework
source "$SCRIPT_DIR/utils/test-framework.sh"

# Configuration
TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-$PWD/test-results}"
TEST_VERBOSE="${TEST_VERBOSE:-false}"
START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# Help function
show_help() {
    cat << EOF
Zellij Utils Test Runner

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -o, --output DIR    Set output directory (default: ./test-results)
    -e, --env TYPE      Force environment type (docker|github-actions|native)
    --quick             Run only quick tests (validation, config)
    --full              Run all test suites (default)

ENVIRONMENT:
    The test runner automatically detects the environment:
    - Docker: When running in a container
    - GitHub Actions: When CI environment is detected
    - Native: When running on local machine

EXAMPLES:
    $0                  # Run all tests, auto-detect environment
    $0 --quick          # Run only quick tests
    $0 --verbose        # Run with verbose output
    $0 --env native     # Force native environment
    
EOF
}

# Parse command line arguments
FORCE_ENV=""
TEST_SUITE="full"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            export TEST_VERBOSE=true
            ;;
        -o|--output)
            TEST_OUTPUT_DIR="$2"
            shift
            ;;
        -e|--env)
            FORCE_ENV="$2"
            shift
            ;;
        --quick)
            TEST_SUITE="quick"
            ;;
        --full)
            TEST_SUITE="full"
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Override environment detection if forced
if [[ -n "$FORCE_ENV" ]]; then
    detect_environment() {
        echo "$FORCE_ENV"
    }
fi

# Main execution
main() {
    local env=$(detect_environment)
    
    # Safety warning for native environment
    if [[ "$env" == "native" ]] && [[ -z "${FORCE_NATIVE:-}" ]]; then
        echo "⚠️  WARNING: Running tests in native environment!"
        echo "   This may interfere with your active zellij sessions."
        echo "   For safe local testing, use: ./scripts/test-local.sh"
        echo ""
        echo "   Continue anyway? Set FORCE_NATIVE=1 to skip this warning."
        echo "   Press Ctrl+C to cancel, or Enter to continue..."
        read -r
    fi
    
    echo "============================================"
    echo "   Zellij Utils Test Suite"
    echo "============================================"
    echo "Environment: $env"
    echo "Test Suite: $TEST_SUITE"
    echo "Output Dir: $TEST_OUTPUT_DIR"
    echo "Start Time: $START_TIME"
    echo "============================================"
    echo
    
    # Create output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    export TEST_OUTPUT_DIR
    
    # Initialize log
    echo "Zellij Utils Test Execution Log - $START_TIME" > "$TEST_OUTPUT_DIR/test.log"
    echo "Environment: $env" >> "$TEST_OUTPUT_DIR/test.log"
    echo "Test Suite: $TEST_SUITE" >> "$TEST_OUTPUT_DIR/test.log"
    echo "----------------------------------------" >> "$TEST_OUTPUT_DIR/test.log"
    
    # Source and run the shared tests
    source "$SCRIPT_DIR/shared/core-tests.sh"
    
    # Set up signal handlers
    trap 'cleanup_test_environment; exit 130' INT TERM
    trap 'cleanup_test_environment' EXIT
    
    # Run tests based on suite selection
    case "$TEST_SUITE" in
        "quick")
            log_info "Running quick test suite"
            setup_test_environment
            check_dependencies || exit 1
            run_validation_tests
            run_config_tests
            ;;
        "full")
            log_info "Running full test suite"
            run_all_shared_tests
            ;;
        *)
            log_error "Unknown test suite: $TEST_SUITE"
            exit 1
            ;;
    esac
    
    # Generate final report
    generate_test_report
    
    # Summary
    echo
    echo "============================================"
    echo "   Test Execution Complete"
    echo "============================================"
    print_test_summary
    local exit_code=$?
    echo "Results: $TEST_OUTPUT_DIR/test_results.md"
    echo "============================================"
    
    exit $exit_code
}

# Run main function
main "$@"