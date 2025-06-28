#!/bin/bash
# Manual test runner for debugging

echo "=== Zellij Utils Manual Test Run ==="
echo "Date: $(date)"
echo "Environment: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Zellij: $(zellij --version)"
echo ""

cd /app/zellij-utils

# Test counters
total_tests=0
passed_tests=0
failed_tests=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name ... "
    ((total_tests++))
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((passed_tests++))
    else
        echo "❌ FAIL"
        ((failed_tests++))
        echo "  Command: $test_command"
        eval "$test_command" 2>&1 | head -5 | sed 's/^/  /'
    fi
}

echo "=== Configuration Tests ==="
run_test "Config loading" "source scripts/config-loader.sh && zj_load_config"
run_test "Config validation" "source scripts/config-validator.sh && zj_validate_session_name 'valid-name'"
run_test "Invalid session name rejection" "source scripts/config-validator.sh && ! zj_validate_session_name 'invalid@name'"

echo ""
echo "=== Session Naming Tests ==="
run_test "Session naming basic" "source scripts/session-naming.sh && zj_generate_session_name >/dev/null"
run_test "Session name sanitization" "source scripts/session-naming.sh && name=\$(echo 'invalid@name' | sed 's/[^a-zA-Z0-9_-]/_/g') && [[ \$name =~ ^[a-zA-Z0-9_-]+$ ]]"

echo ""
echo "=== Core Function Tests ==="
run_test "Main script loading" "source scripts/zellij-utils.sh && type zj >/dev/null"
run_test "Navigation functions" "source scripts/zellij-utils.sh && type zjh >/dev/null && type zjc >/dev/null"

echo ""
echo "=== Security Tests ==="
run_test "Path traversal prevention" "source scripts/config-validator.sh && ! zj_validate_path '../../../etc/passwd'"
run_test "Command injection prevention" "source scripts/config-validator.sh && ! zj_validate_session_name 'test; rm -rf /'"

echo ""
echo "=== File System Tests ==="
run_test "Script permissions" "[[ -x scripts/zellij-utils.sh ]]"
run_test "Config files exist" "[[ -f config/zellij-utils.conf ]] && [[ -f config/session-naming.conf ]]"
run_test "Layout files exist" "[[ -f layouts/dev.kdl ]] && [[ -f layouts/simple.kdl ]]"

echo ""
echo "=== Results ==="
echo "Total Tests: $total_tests"
echo "Passed: $passed_tests" 
echo "Failed: $failed_tests"
echo "Success Rate: $(( passed_tests * 100 / total_tests ))%"

if [[ $failed_tests -eq 0 ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi