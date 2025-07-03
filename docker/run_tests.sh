#!/bin/bash
# Main test runner for Docker environment
set -euo pipefail

# Configuration
TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-/app/test-results}"
TEST_VERBOSE="${TEST_VERBOSE:-false}"
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"  # 5 minutes per test category
START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0
declare -a FAILED_TEST_NAMES=()
declare -a TEST_RESULTS=()

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

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create output directories with proper permissions
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$TEST_OUTPUT_DIR/logs"
    mkdir -p "$TEST_OUTPUT_DIR/artifacts"
    chmod 755 "$TEST_OUTPUT_DIR"
    chmod 755 "$TEST_OUTPUT_DIR/logs"
    chmod 755 "$TEST_OUTPUT_DIR/artifacts"
    
    # Initialize log file
    echo "Zellij Utils Test Execution Log - $START_TIME" > "$TEST_OUTPUT_DIR/test.log" 2>/dev/null || {
        echo "Zellij Utils Test Execution Log - $START_TIME" > /tmp/test.log
        TEST_OUTPUT_DIR="/tmp"
        log_warning "Using /tmp for test output due to permission issues"
    }
    
    # Set up test user environment with complete isolation
    export HOME="/home/testuser"
    export USER="testuser"
    export SHELL="/bin/bash"
    export ZELLIJ_CONFIG_DIR="/home/testuser/.config/zellij"
    export ZJ_DISABLE_AUTO=1
    export ZJ_TEST_MODE=1
    
    # Comprehensive session cleanup for complete isolation
    log_info "Cleaning up any existing zellij sessions..."
    pkill -f zellij 2>/dev/null || true
    pkill -f "zellij.*" 2>/dev/null || true
    sleep 3
    
    # Clean zellij cache and temporary files
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    rm -rf /tmp/zellij-* 2>/dev/null || true
    rm -rf /tmp/*zellij* 2>/dev/null || true
    
    # Ensure clean socket directory
    rm -rf /tmp/zellij-$(id -u)/ 2>/dev/null || true
    
    # Wait for complete cleanup
    sleep 2
    
    # Verify required tools
    check_dependencies
    
    log_success "Test environment setup complete"
}

# Check required dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local deps=("zellij" "git" "bash" "bc")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    # Check zellij version
    local zellij_version="$(zellij --version)"
    log_info "Zellij version: $zellij_version"
    
    log_success "All dependencies available"
}

# Run a single test with timeout and error handling
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_category="${3:-general}"
    local test_timeout="${4:-60}"
    
    ((TOTAL_TESTS++))
    
    log_info "Running test: $test_name"
    
    local test_start_time="$(date +%s)"
    local test_log="$TEST_OUTPUT_DIR/logs/${test_category}_${TOTAL_TESTS}.log"
    local test_result="UNKNOWN"
    local test_output=""
    
    # Run test with timeout
    if timeout "$test_timeout" bash -c "$test_command" >"$test_log" 2>&1; then
        test_result="PASS"
        ((PASSED_TESTS++))
        log_success "✓ $test_name"
    else
        local exit_code=$?
        test_result="FAIL"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
        
        if [[ $exit_code -eq 124 ]]; then
            log_error "✗ $test_name (TIMEOUT after ${test_timeout}s)"
            test_result="TIMEOUT"
        else
            log_error "✗ $test_name (EXIT CODE: $exit_code)"
        fi
        
        # Show error details if verbose
        if [[ "$TEST_VERBOSE" == "true" ]]; then
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

# Configuration System Tests
run_config_tests() {
    log_info "=== Running Configuration System Tests ==="
    
    # Test 1: Default configuration loading
    run_test "Config: Default loading" \
        "cd '$PROJECT_DIR' && source scripts/config-loader.sh && zj_load_config && [[ '\$ZJ_AUTO_START_ENABLED' == 'true' ]]" \
        "config" 30
    
    # Test 2: Configuration validation
    run_test "Config: Validation system" \
        "cd '$PROJECT_DIR' && source scripts/config-validator.sh && zj_validate_session_name 'valid-name'" \
        "config" 30
    
    # Test 3: Session name validation (should fail)
    run_test "Config: Invalid session name rejection" \
        "cd '$PROJECT_DIR' && source scripts/config-validator.sh && ! zj_validate_session_name 'invalid@name'" \
        "config" 30
    
    # Test 4: Configuration migration
    run_test "Config: Migration system" \
        "cd '$PROJECT_DIR' && source scripts/config-migration.sh && zj_backup_config >/dev/null" \
        "config" 60
    
    # Test 5: Runtime reload
    run_test "Config: Runtime reload" \
        "cd '$PROJECT_DIR' && source scripts/config-loader.sh && zj_load_config && zj_reload_config >/dev/null" \
        "config" 30
}

# Session Naming Tests
run_session_naming_tests() {
    log_info "=== Running Session Naming Tests ==="
    
    # Test 1: Git repository naming
    run_test "Naming: Git repository detection" \
        "cd /tmp && git init test-repo && cd test-repo && source '$PROJECT_DIR/scripts/session-naming.sh' && name=\$(zj_generate_session_name) && [[ '\$name' == 'test-repo' ]] && cd .. && rm -rf test-repo" \
        "naming" 45
    
    # Test 2: Project marker detection
    run_test "Naming: Project marker detection" \
        "mkdir -p /tmp/test-project && cd /tmp/test-project && touch package.json && source '$PROJECT_DIR/scripts/session-naming.sh' && name=\$(zj_generate_session_name) && [[ '\$name' == 'test-project' ]] && cd /tmp && rm -rf test-project" \
        "naming" 45
    
    # Test 3: Session name sanitization
    run_test "Naming: Name sanitization" \
        "mkdir -p '/tmp/invalid@name' && cd '/tmp/invalid@name' && source '$PROJECT_DIR/scripts/session-naming.sh' && name=\$(zj_generate_session_name) && [[ '\$name' =~ ^[a-zA-Z0-9_-]+$ ]] && cd /tmp && rm -rf 'invalid@name'" \
        "naming" 45
    
    # Test 4: Special directory patterns
    run_test "Naming: Special directory patterns" \
        "cd '\$HOME' && source '$PROJECT_DIR/scripts/session-naming.sh' && name=\$(zj_generate_session_name) && [[ '\$name' == 'home' ]]" \
        "naming" 30
}

# Core Functionality Tests
run_core_tests() {
    log_info "=== Running Core Functionality Tests ==="
    
    # Test 1: Session creation with smart naming
    run_test "Core: Smart session creation" \
        "cd /tmp && git init test-session && cd test-session && source '$PROJECT_DIR/scripts/zellij-utils.sh' && timeout 10 zellij -d -s test-session-manual && zellij list-sessions | grep test-session-manual && zellij kill-session test-session-manual && cd /tmp && rm -rf test-session" \
        "core" 60
    
    # Test 2: Session listing
    run_test "Core: Session listing" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && zellij -d -s test-list-1 && zellij -d -s test-list-2 && zjl | grep test-list && zellij kill-session test-list-1 && zellij kill-session test-list-2" \
        "core" 60
    
    # Test 3: Layout validation
    run_test "Core: Layout validation" \
        "source '$PROJECT_DIR/scripts/config-validator.sh' && zj_validate_layout 'dev'" \
        "core" 30
    
    # Test 4: Navigation functions basic check
    run_test "Core: Navigation function loading" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && type zjh >/dev/null && type zjc >/dev/null" \
        "core" 30
}

# Security Tests
run_security_tests() {
    log_info "=== Running Security Tests ==="
    
    # Test 1: Session name injection prevention
    run_test "Security: Session name injection prevention" \
        "source '$PROJECT_DIR/scripts/config-validator.sh' && ! zj_validate_session_name 'session; rm -rf /'" \
        "security" 30
    
    # Test 2: Path traversal prevention
    run_test "Security: Path traversal prevention" \
        "source '$PROJECT_DIR/scripts/config-validator.sh' && ! zj_validate_path '../../../etc/passwd'" \
        "security" 30
    
    # Test 3: Configuration injection prevention
    run_test "Security: Config injection prevention" \
        "echo 'ZJ_SESSION_NAME_PATTERN=\".*; rm -rf /\"' > /tmp/bad-config.conf && source /tmp/bad-config.conf && source '$PROJECT_DIR/scripts/config-validator.sh' && ! zj_validate_full_config >/dev/null 2>&1; rm /tmp/bad-config.conf" \
        "security" 45
    
    # Test 4: Command execution safety
    run_test "Security: Safe command execution" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && ! echo 'zj \"session\$(cat /etc/passwd)\"' | bash 2>/dev/null" \
        "security" 30
}

# Performance Tests
run_performance_tests() {
    log_info "=== Running Performance Tests ==="
    
    # Test 1: Configuration loading speed
    run_test "Performance: Config loading speed" \
        "time_start=\$(date +%s%N) && source '$PROJECT_DIR/scripts/config-loader.sh' && zj_load_config && time_end=\$(date +%s%N) && duration=\$(( (time_end - time_start) / 1000000 )) && [[ \$duration -lt 1000 ]]" \
        "performance" 30
    
    # Test 2: Session name generation speed
    run_test "Performance: Session name generation speed" \
        "cd /tmp && git init perf-test && cd perf-test && time_start=\$(date +%s%N) && source '$PROJECT_DIR/scripts/session-naming.sh' && zj_generate_session_name >/dev/null && time_end=\$(date +%s%N) && duration=\$(( (time_end - time_start) / 1000000 )) && [[ \$duration -lt 500 ]] && cd /tmp && rm -rf perf-test" \
        "performance" 45
    
    # Test 3: Multiple session handling
    run_test "Performance: Multiple session handling" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && for i in {1..5}; do zellij -d -s \"perf-test-\$i\"; done && time zjl >/dev/null && for i in {1..5}; do zellij kill-session \"perf-test-\$i\"; done" \
        "performance" 90
}

# Integration Tests
run_integration_tests() {
    log_info "=== Running Integration Tests ==="
    
    # Test 1: Installation script (dry run)
    run_test "Integration: Installation script validation" \
        "cd '$PROJECT_DIR' && bash -n scripts/install.sh" \
        "integration" 30
    
    # Test 2: Shell compatibility (bash)
    run_test "Integration: Bash compatibility" \
        "bash -c 'source \"$PROJECT_DIR/scripts/zellij-utils.sh\" && type zj >/dev/null'" \
        "integration" 30
    
    # Test 3: Zsh compatibility (if available)
    if command -v zsh >/dev/null 2>&1; then
        run_test "Integration: Zsh compatibility" \
            "zsh -c 'source \"$PROJECT_DIR/scripts/zellij-utils.sh\" && type zj >/dev/null'" \
            "integration" 30
    else
        log_warning "Skipping zsh compatibility test (zsh not available)"
        ((SKIPPED_TESTS++))
    fi
    
    # Test 4: Error handling
    run_test "Integration: Error handling" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && zj_validate_session_name '' 2>/dev/null; [[ \$? -ne 0 ]]" \
        "integration" 30
}

# Edge Case Tests
run_edge_case_tests() {
    log_info "=== Running Edge Case Tests ==="
    
    # Test 1: Spaces in paths
    run_test "Edge: Spaces in paths" \
        "mkdir -p '/tmp/path with spaces' && cd '/tmp/path with spaces' && source '$PROJECT_DIR/scripts/session-naming.sh' && zj_generate_session_name >/dev/null && cd /tmp && rm -rf 'path with spaces'" \
        "edge" 45
    
    # Test 2: Very long paths
    run_test "Edge: Long paths handling" \
        "long_path=\"/tmp/\$(printf 'very-long-directory-name%.0s' {1..5})\" && mkdir -p \"\$long_path\" && cd \"\$long_path\" && source '$PROJECT_DIR/scripts/session-naming.sh' && zj_generate_session_name >/dev/null && cd /tmp && rm -rf \"\$long_path\"" \
        "edge" 60
    
    # Test 3: Empty directories
    run_test "Edge: Empty directory handling" \
        "mkdir -p /tmp/empty-dir && cd /tmp/empty-dir && source '$PROJECT_DIR/scripts/session-naming.sh' && name=\$(zj_generate_session_name) && [[ -n \"\$name\" ]] && cd /tmp && rm -rf empty-dir" \
        "edge" 45
    
    # Test 4: Non-existent path handling
    run_test "Edge: Non-existent path handling" \
        "source '$PROJECT_DIR/scripts/config-validator.sh' && ! zj_validate_path '/nonexistent/path' true" \
        "edge" 30
}

# Generate test results markdown
generate_results_report() {
    log_info "Generating test results report..."
    
    local end_time="$(date '+%Y-%m-%d %H:%M:%S')"
    local total_duration="$(( $(date +%s) - $(date -d "$START_TIME" +%s) ))"
    local success_rate=0
    
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        success_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    fi
    
    # Generate markdown report
    cat > "$TEST_OUTPUT_DIR/test_plan_results.md" << EOF
# Zellij Utils Test Plan Results

## Test Execution Summary

- **Start Time:** $START_TIME
- **End Time:** $end_time
- **Total Duration:** ${total_duration}s
- **Environment:** Docker Container ($(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2))
- **Zellij Version:** $(zellij --version)

## Results Overview

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Tests** | $TOTAL_TESTS | 100% |
| **Passed** | $PASSED_TESTS | ${success_rate}% |
| **Failed** | $FAILED_TESTS | $(( FAILED_TESTS * 100 / TOTAL_TESTS ))% |
| **Skipped** | $SKIPPED_TESTS | $(( SKIPPED_TESTS * 100 / TOTAL_TESTS ))% |

## Test Status: $(if [[ $FAILED_TESTS -eq 0 ]]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)

$(if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 **All tests passed!** The system is ready for production deployment."
else
    echo "⚠️ **Some tests failed.** Review the failures below before production deployment."
fi)

## Detailed Results

EOF

    # Add detailed results by category
    local categories=("config" "naming" "core" "security" "performance" "integration" "edge")
    
    for category in "${categories[@]}"; do
        echo "### $(echo ${category^} | sed 's/config/Configuration/' | sed 's/naming/Session Naming/' | sed 's/core/Core Functionality/' | sed 's/security/Security/' | sed 's/performance/Performance/' | sed 's/integration/Integration/' | sed 's/edge/Edge Cases/') Tests" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
        echo "" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
        
        local category_tests=0
        local category_passed=0
        local category_failed=0
        
        for result in "${TEST_RESULTS[@]}"; do
            local test_name="$(echo "$result" | cut -d'|' -f1)"
            local test_result="$(echo "$result" | cut -d'|' -f2)"
            local test_duration="$(echo "$result" | cut -d'|' -f3)"
            local test_category="$(echo "$result" | cut -d'|' -f4)"
            local test_log="$(echo "$result" | cut -d'|' -f5)"
            
            if [[ "$test_category" == "$category" ]]; then
                ((category_tests++))
                local status_icon="❓"
                case "$test_result" in
                    "PASS") status_icon="✅"; ((category_passed++)) ;;
                    "FAIL") status_icon="❌"; ((category_failed++)) ;;
                    "TIMEOUT") status_icon="⏰"; ((category_failed++)) ;;
                esac
                
                echo "- $status_icon **$test_name** (${test_duration}s)" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                
                if [[ "$test_result" != "PASS" && -f "$test_log" ]]; then
                    echo "  <details><summary>Error Details</summary>" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                    echo "" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                    echo "  \`\`\`" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                    tail -20 "$test_log" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                    echo "  \`\`\`" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                    echo "  </details>" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
                fi
            fi
        done
        
        if [[ $category_tests -gt 0 ]]; then
            echo "" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
            echo "**Category Summary:** $category_passed/$category_tests passed" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
        fi
        echo "" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
    done
    
    # Add failed tests summary if any
    if [[ $FAILED_TESTS -gt 0 ]]; then
        cat >> "$TEST_OUTPUT_DIR/test_plan_results.md" << EOF
## Failed Tests Summary

The following tests failed and need attention:

EOF
        for failed_test in "${FAILED_TEST_NAMES[@]}"; do
            echo "- ❌ $failed_test" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
        done
        echo "" >> "$TEST_OUTPUT_DIR/test_plan_results.md"
    fi
    
    # Add recommendations
    cat >> "$TEST_OUTPUT_DIR/test_plan_results.md" << EOF
## Recommendations

$(if [[ $FAILED_TESTS -eq 0 ]]; then
    cat << 'REC_EOF'
✅ **Production Ready:** All tests passed successfully.

**Next Steps:**
1. Deploy to staging environment for integration testing
2. Perform user acceptance testing
3. Plan production rollout
4. Set up monitoring and alerting

**Post-Deployment Checklist:**
- [ ] Monitor session creation success rates
- [ ] Track configuration migration statistics
- [ ] Watch for error patterns in logs
- [ ] Collect user feedback on reliability
REC_EOF
else
    cat << 'REC_EOF'
⚠️ **Not Production Ready:** Address failed tests before deployment.

**Required Actions:**
1. Fix all failing tests
2. Re-run test suite to verify fixes
3. Perform additional manual testing for failed areas
4. Review security implications of any failures

**Priority Areas:**
- Security test failures require immediate attention
- Core functionality failures block deployment
- Configuration issues need resolution before migration
REC_EOF
fi)

## Test Artifacts

- **Full Test Log:** \`test.log\`
- **Individual Test Logs:** \`logs/\` directory
- **Test Configuration:** Docker environment
- **Generated At:** $(date '+%Y-%m-%d %H:%M:%S UTC')

---

*This report was automatically generated by the Zellij Utils test suite.*
EOF

    log_success "Test results report generated: $TEST_OUTPUT_DIR/test_plan_results.md"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    
    # Kill any remaining zellij processes with comprehensive cleanup
    pkill -f zellij 2>/dev/null || true
    pkill -f "zellij.*" 2>/dev/null || true
    sleep 2
    
    # Clean up zellij-specific temporary files and caches
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    rm -rf /tmp/zellij-* 2>/dev/null || true
    rm -rf /tmp/*zellij* 2>/dev/null || true
    rm -rf /tmp/zellij-$(id -u)/ 2>/dev/null || true
    
    # Clean up general test temporary files
    rm -rf /tmp/test-* /tmp/*-test* 2>/dev/null || true
    
    # Ensure no leftover session files
    find /tmp -name "*zellij*" -type f -delete 2>/dev/null || true
    find /tmp -name "*zellij*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    log_info "Cleanup complete"
}

# Signal handlers (simplified for Docker environment)
trap cleanup EXIT

# Main test execution
main() {
    log_info "Starting Zellij Utils Test Suite"
    log_info "Docker environment: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    log_info "Test output directory: $TEST_OUTPUT_DIR"
    
    # Setup
    setup_test_environment
    
    # Run test categories
    run_config_tests
    run_session_naming_tests
    run_core_tests
    run_security_tests
    run_performance_tests
    run_integration_tests
    run_edge_case_tests
    
    # Generate report
    generate_results_report
    
    # Final summary
    log_info "=== Test Execution Complete ==="
    log_info "Total Tests: $TOTAL_TESTS"
    log_info "Passed: $PASSED_TESTS"
    log_info "Failed: $FAILED_TESTS"
    log_info "Skipped: $SKIPPED_TESTS"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 All tests passed! System is production ready."
        exit 0
    else
        log_error "❌ $FAILED_TESTS test(s) failed. System needs fixes before production."
        exit 1
    fi
}

# Execute main function
main "$@"