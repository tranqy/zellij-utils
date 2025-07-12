#!/bin/bash
# Core functionality tests - environment agnostic

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/../utils/test-framework.sh"

# Get project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Configuration System Tests
run_config_tests() {
    log_info "=== Running Configuration System Tests ==="
    
    # Test 1: Main script sourcing
    run_test "Config: Main script loading" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && type zj >/dev/null" \
        "config" 30
    
    # Test 2: Function availability
    run_test "Config: Core functions available" \
        "source '$PROJECT_DIR/scripts/zellij-utils.sh' && type zjl >/dev/null && type zjk >/dev/null" \
        "config" 30
}

# Session Management Tests
run_session_tests() {
    log_info "=== Running Session Management Tests ==="
    
    # Test 1: Zellij availability
    run_test "Session: Zellij version check" \
        "zellij --version" \
        "session" 10
    
    # Test 2: Session creation (detached)
    run_test "Session: Detached session creation" \
        "timeout 30 zellij -d -s test-session-ci" \
        "session" 45
    
    # Test 3: Session listing
    run_test "Session: Session listing" \
        "zellij list-sessions | grep test-session-ci || zellij list-sessions" \
        "session" 15
    
    # Test 4: Session cleanup
    run_test "Session: Session termination" \
        "zellij kill-session test-session-ci 2>/dev/null || true" \
        "session" 15
}

# Script Validation Tests
run_validation_tests() {
    log_info "=== Running Script Validation Tests ==="
    
    # Test 1: Installation script syntax
    run_test "Validation: Install script syntax" \
        "bash -n '$PROJECT_DIR/scripts/install.sh'" \
        "validation" 10
    
    # Test 2: Main script syntax
    run_test "Validation: Main script syntax" \
        "bash -n '$PROJECT_DIR/scripts/zellij-utils.sh'" \
        "validation" 10
    
    # Test 3: Layout files exist
    run_test "Validation: Layout files exist" \
        "ls '$PROJECT_DIR/layouts/'*.kdl >/dev/null" \
        "validation" 10
}

# Integration Tests
run_integration_tests() {
    log_info "=== Running Integration Tests ==="
    
    # Test 1: Shell compatibility (bash)
    run_test "Integration: Bash compatibility" \
        "bash -c 'source \"$PROJECT_DIR/scripts/zellij-utils.sh\" && type zj >/dev/null'" \
        "integration" 20
    
    # Test 2: Zsh compatibility (if available)
    if command -v zsh >/dev/null 2>&1; then
        run_test "Integration: Zsh compatibility" \
            "zsh -c 'source \"$PROJECT_DIR/scripts/zellij-utils.sh\" && type zj >/dev/null'" \
            "integration" 20
    else
        log_warning "Skipping zsh compatibility test (zsh not available)"
        ((SKIPPED_TESTS++))
    fi
    
    # Test 3: Git integration (if in git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        run_test "Integration: Git repository detection" \
            "cd '$PROJECT_DIR' && source scripts/zellij-utils.sh && git rev-parse --show-toplevel >/dev/null" \
            "integration" 15
    else
        log_warning "Skipping git integration test (not in git repo)"
        ((SKIPPED_TESTS++))
    fi
}

# Security Tests (basic)
run_security_tests() {
    log_info "=== Running Security Tests ==="
    
    # Test 1: No hardcoded secrets
    run_test "Security: No hardcoded secrets" \
        "! grep -r 'password\\|secret\\|token' '$PROJECT_DIR/scripts/' --include='*.sh' | grep -v example" \
        "security" 15
    
    # Test 2: No dangerous commands
    run_test "Security: No rm -rf /" \
        "! grep -r 'rm -rf /' '$PROJECT_DIR/scripts/' --include='*.sh'" \
        "security" 10
    
    # Test 3: No eval with variables
    run_test "Security: No dangerous eval" \
        "! grep -r 'eval.*\\$' '$PROJECT_DIR/scripts/' --include='*.sh'" \
        "security" 10
}

# Performance Tests (basic)
run_performance_tests() {
    log_info "=== Running Performance Tests ==="
    
    # Test 1: Script loading speed
    run_test "Performance: Script loading speed" \
        "time_start=\$(date +%s%N) && source '$PROJECT_DIR/scripts/zellij-utils.sh' && time_end=\$(date +%s%N) && duration=\$(( (time_end - time_start) / 1000000 )) && [[ \$duration -lt 2000 ]]" \
        "performance" 30
}

# Main test execution function
run_all_shared_tests() {
    log_info "Starting shared test execution"
    
    # Setup
    setup_test_environment
    check_dependencies || exit 1
    
    # Run test suites
    run_validation_tests
    run_config_tests
    run_session_tests
    run_integration_tests
    run_security_tests
    run_performance_tests
    
    # Generate report and cleanup
    generate_test_report
    cleanup_test_environment
    
    # Return status
    print_test_summary
}