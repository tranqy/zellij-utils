#!/bin/bash

# Security Tests for Zellij Utils
# Tests for shell injection vulnerabilities and input validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Source the main script
source "$PROJECT_DIR/scripts/zellij-utils.sh"

# Test counter
tests_run=0
tests_passed=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo "Testing: $test_name"
    tests_run=$((tests_run + 1))
    
    if eval "$test_command" 2>/dev/null; then
        if [[ "$expected_result" == "pass" ]]; then
            echo "✅ PASS: $test_name"
            tests_passed=$((tests_passed + 1))
        else
            echo "❌ FAIL: $test_name (expected failure but passed)"
        fi
    else
        if [[ "$expected_result" == "fail" ]]; then
            echo "✅ PASS: $test_name (correctly failed)"
            tests_passed=$((tests_passed + 1))
        else
            echo "❌ FAIL: $test_name (expected pass but failed)"
        fi
    fi
}

echo "🔒 Running Security Tests for Zellij Utils"
echo "================================================"

# Test 1: Shell injection in session names
run_test "Shell injection prevention" \
    "zj 'test; rm -rf /tmp/test' 2>&1 | grep -q 'invalid characters'" \
    "pass"

# Test 2: Empty session name validation
run_test "Empty session name validation" \
    "zj '' 2>&1 | grep -q 'cannot be empty'" \
    "pass"

# Test 3: Long session name validation  
run_test "Long session name validation" \
    "zj 'aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeeeffffffffff' 2>&1 | grep -q 'too long'" \
    "pass"

# Test 4: Valid session name should work
run_test "Valid session name acceptance" \
    "zj 'valid-session_123' --help 2>&1 | grep -q 'Error:'" \
    "fail"

# Test 5: Special characters in session names
run_test "Special characters prevention" \
    "zj 'test\$(whoami)' 2>&1 | grep -q 'invalid characters'" \
    "pass"

# Test 6: Backtick injection prevention
run_test "Backtick injection prevention" \
    "zj 'test\`id\`' 2>&1 | grep -q 'invalid characters'" \
    "pass"

# Test 7: Delete function injection prevention
run_test "Delete function injection prevention" \
    "zjd 'test; rm -rf /tmp/test' --force 2>&1 | grep -q 'invalid characters'" \
    "pass"

# Test 8: Delete function invalid options
run_test "Delete function invalid options" \
    "zjd --invalid-option 2>&1 | grep -q 'Unknown option'" \
    "pass"

# Test 9: Delete function current session protection
run_test "Delete function current session protection" \
    "ZELLIJ_SESSION_NAME='test' zjd 'test' 2>&1 | grep -q 'Cannot delete current session'" \
    "pass"

# Test 10: Delete function empty session name handling
run_test "Delete function empty session name handling" \
    "zjd '' 2>&1 | grep -q 'No sessions to delete'" \
    "pass"

echo "================================================"
echo "Security Tests Complete"
echo "Tests run: $tests_run"
echo "Tests passed: $tests_passed"
echo "Success rate: $((tests_passed * 100 / tests_run))%"

if [[ $tests_passed -eq $tests_run ]]; then
    echo "🎉 All security tests passed!"
    exit 0
else
    echo "⚠️  Some security tests failed!"
    exit 1
fi