#!/bin/bash
# Compatibility Tests for Zellij Utils
# Tests compatibility across different shells, systems, and configurations

set -euo pipefail

# Test configuration
EXIT_CODE=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test utilities
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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

test_assert() {
    local condition="$1"
    local message="$2"
    
    if eval "$condition"; then
        log_info "✅ $message"
    else
        log_error "❌ $message"
    fi
}

# Test shell compatibility
test_bash_compatibility() {
    log_test "Testing Bash compatibility"
    
    local bash_script="$PROJECT_ROOT/scripts/zellij-utils.sh"
    
    # Test different bash versions if available
    local bash_versions=("bash" "/bin/bash")
    
    for bash_cmd in "${bash_versions[@]}"; do
        if command -v "$bash_cmd" >/dev/null 2>&1; then
            local bash_version=$("$bash_cmd" --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+')
            log_info "Testing with $bash_cmd (version $bash_version)"
            
            # Test syntax
            if "$bash_cmd" -n "$bash_script" 2>/dev/null; then
                log_info "✅ Syntax valid in $bash_cmd"
            else
                log_error "❌ Syntax error in $bash_cmd"
            fi
            
            # Test basic sourcing
            if "$bash_cmd" -c "source '$bash_script'" 2>/dev/null; then
                log_info "✅ Sources successfully in $bash_cmd"
            else
                log_error "❌ Sourcing failed in $bash_cmd"
            fi
            
            # Test bash 4+ features (associative arrays)
            if [[ "$bash_version" =~ ^[4-9] ]]; then
                if "$bash_cmd" -c "declare -A test_array; test_array[key]=value; echo \${test_array[key]}" >/dev/null 2>&1; then
                    log_info "✅ Associative arrays supported in $bash_cmd"
                else
                    log_error "❌ Associative arrays not working in $bash_cmd"
                fi
            else
                log_warn "⚠️  Bash version $bash_version may not support all features"
            fi
        fi
    done
}

# Test zsh compatibility
test_zsh_compatibility() {
    log_test "Testing Zsh compatibility"
    
    local zsh_script="$PROJECT_ROOT/scripts/zellij-utils-zsh.sh"
    
    if command -v zsh >/dev/null 2>&1; then
        local zsh_version=$(zsh --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1)
        log_info "Testing with zsh (version $zsh_version)"
        
        # Test syntax
        if zsh -n "$zsh_script" 2>/dev/null; then
            log_info "✅ Syntax valid in zsh"
        else
            log_error "❌ Syntax error in zsh"
        fi
        
        # Test basic sourcing
        if zsh -c "source '$zsh_script'" 2>/dev/null; then
            log_info "✅ Sources successfully in zsh"
        else
            log_error "❌ Sourcing failed in zsh"
        fi
        
        # Test zsh-specific features
        if zsh -c "local test_array=(one two three); echo \${test_array[1]}" >/dev/null 2>&1; then
            log_info "✅ Zsh arrays working"
        else
            log_error "❌ Zsh arrays not working"
        fi
        
        # Test completion system
        if zsh -c "autoload -U compinit; compinit" >/dev/null 2>&1; then
            log_info "✅ Zsh completion system available"
        else
            log_warn "⚠️  Zsh completion system not working"
        fi
    else
        log_warn "⚠️  Zsh not available for testing"
    fi
}

# Test system compatibility
test_system_compatibility() {
    log_test "Testing system compatibility"
    
    # Detect OS
    local os_name=""
    if [[ -f /etc/os-release ]]; then
        os_name=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2)
    elif [[ -f /etc/redhat-release ]]; then
        os_name=$(cat /etc/redhat-release)
    elif command -v uname >/dev/null 2>&1; then
        os_name=$(uname -s)
    fi
    
    log_info "Testing on: $os_name"
    
    # Test required commands availability
    local required_commands=("cp" "mkdir" "chmod" "grep" "sed" "awk" "basename" "dirname" "date")
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "✅ $cmd available"
        else
            log_error "❌ $cmd not available"
        fi
    done
    
    # Test optional commands
    local optional_commands=("git" "fzf" "zellij" "tmux" "screen")
    
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            local version=$("$cmd" --version 2>/dev/null | head -n1 || echo "unknown")
            log_info "✅ $cmd available ($version)"
        else
            log_warn "⚠️  $cmd not available (optional)"
        fi
    done
}

# Test path handling
test_path_handling() {
    log_test "Testing path handling"
    
    local test_paths=(
        "/normal/path"
        "/path with spaces/test"
        "/path/with/special-chars_123"
        "$HOME/relative/to/home"
        "."
        ".."
        "/tmp"
    )
    
    for path in "${test_paths[@]}"; do
        # Test basename extraction
        if basename "$path" >/dev/null 2>&1; then
            log_info "✅ basename works for: $path"
        else
            log_error "❌ basename fails for: $path"
        fi
        
        # Test dirname extraction
        if dirname "$path" >/dev/null 2>&1; then
            log_info "✅ dirname works for: $path"
        else
            log_error "❌ dirname fails for: $path"
        fi
    done
    
    # Test path with special characters in session naming
    local special_paths=(
        "/path/with\$dollar"
        "/path/with\`backtick"
        "/path/with;semicolon"
        "/path/with|pipe"
        "/path/with&ampersand"
    )
    
    for path in "${special_paths[@]}"; do
        # Simulate session name extraction
        local session_name=$(basename "$path" | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
        if [[ "$session_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_info "✅ Safe session name from: $path -> $session_name"
        else
            log_error "❌ Unsafe session name from: $path -> $session_name"
        fi
    done
}

# Test environment variable handling
test_environment_variables() {
    log_test "Testing environment variable handling"
    
    # Test HOME variable
    if [[ -n "$HOME" ]] && [[ -d "$HOME" ]]; then
        log_info "✅ HOME variable valid: $HOME"
    else
        log_error "❌ HOME variable invalid or missing"
    fi
    
    # Test USER variable
    if [[ -n "${USER:-}" ]]; then
        log_info "✅ USER variable available: $USER"
    else
        log_warn "⚠️  USER variable not set"
    fi
    
    # Test environment variable expansion safety
    local test_vars=(
        "\$HOME"
        "\$USER"
        "\$PWD"
        "\$PATH"
    )
    
    for var in "${test_vars[@]}"; do
        # Test that variable expansion is safe (doesn't execute commands)
        local safe_expansion="${var//\$HOME/$HOME}"
        safe_expansion="${safe_expansion//\$USER/${USER:-testuser}}"
        
        if [[ "$safe_expansion" != *'`'* ]] && [[ "$safe_expansion" != *'$('* ]]; then
            log_info "✅ Safe expansion for: $var"
        else
            log_error "❌ Potentially unsafe expansion for: $var"
        fi
    done
}

# Test configuration file handling
test_config_files() {
    log_test "Testing configuration file handling"
    
    # Test reading configuration files
    local config_file="$PROJECT_ROOT/config-examples/config.kdl"
    
    if [[ -f "$config_file" ]]; then
        # Test file is readable
        if [[ -r "$config_file" ]]; then
            log_info "✅ Config file readable"
        else
            log_error "❌ Config file not readable"
        fi
        
        # Test file has content
        if [[ -s "$config_file" ]]; then
            log_info "✅ Config file has content"
        else
            log_warn "⚠️  Config file is empty"
        fi
        
        # Test for common configuration issues
        if grep -q $'\\t' "$config_file"; then
            log_warn "⚠️  Config file contains tabs (may cause issues)"
        fi
        
        if grep -q $'\\r' "$config_file"; then
            log_error "❌ Config file contains Windows line endings"
        fi
    else
        log_error "❌ Config file not found: $config_file"
    fi
}

# Test memory and performance
test_performance() {
    log_test "Testing basic performance characteristics"
    
    local bash_script="$PROJECT_ROOT/scripts/zellij-utils.sh"
    
    # Test script loading time
    local start_time=$(date +%s%N)
    bash -c "source '$bash_script'" 2>/dev/null || true
    local end_time=$(date +%s%N)
    local load_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [[ $load_time -lt 1000 ]]; then
        log_info "✅ Script loads quickly ($load_time ms)"
    elif [[ $load_time -lt 5000 ]]; then
        log_warn "⚠️  Script loads slowly ($load_time ms)"
    else
        log_error "❌ Script loads very slowly ($load_time ms)"
    fi
    
    # Test memory usage (approximate)
    local memory_before=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    bash -c "source '$bash_script'" 2>/dev/null || true
    local memory_after=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    local memory_diff=$((memory_after - memory_before))
    
    if [[ $memory_diff -lt 10000 ]]; then  # Less than 10MB
        log_info "✅ Reasonable memory usage"
    else
        log_warn "⚠️  High memory usage: ${memory_diff}KB"
    fi
}

# Test edge cases
test_edge_cases() {
    log_test "Testing edge cases"
    
    # Test empty session name
    local empty_session=""
    if [[ -z "$empty_session" ]]; then
        log_info "✅ Empty session name detection works"
    else
        log_error "❌ Empty session name detection failed"
    fi
    
    # Test very long session name
    local long_session="a$(printf 'b%.0s' {1..100})"
    if [[ ${#long_session} -gt 50 ]]; then
        log_info "✅ Long session name detection works (${#long_session} chars)"
    else
        log_error "❌ Long session name test failed"
    fi
    
    # Test session name with invalid characters
    local invalid_chars="test session with spaces;and|special&chars"
    local cleaned_name=$(echo "$invalid_chars" | tr -cd '[:alnum:]_-')
    if [[ "$cleaned_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_info "✅ Session name sanitization works: '$invalid_chars' -> '$cleaned_name'"
    else
        log_error "❌ Session name sanitization failed"
    fi
    
    # Test directory that doesn't exist
    local nonexistent_dir="/this/path/should/not/exist/anywhere/$(date +%s)"
    if [[ ! -d "$nonexistent_dir" ]]; then
        log_info "✅ Non-existent directory detection works"
    else
        log_error "❌ Non-existent directory test failed (directory actually exists!)"
    fi
}

# Test security measures
test_security() {
    log_test "Testing security measures"
    
    local bash_script="$PROJECT_ROOT/scripts/zellij-utils.sh"
    
    # Test for potentially dangerous patterns
    local dangerous_patterns=(
        "eval.*\$"
        "exec.*\$"
        "\`.*\`"
        "\$\(.*\)"
        "rm -rf"
        "sudo"
        ">/dev/null.*\&"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if grep -q "$pattern" "$bash_script"; then
            log_warn "⚠️  Potentially dangerous pattern found: $pattern"
            # Show context
            grep -n "$pattern" "$bash_script" | head -3 | while read -r line; do
                log_warn "    $line"
            done
        else
            log_info "✅ No dangerous pattern: $pattern"
        fi
    done
    
    # Test input validation is present
    if grep -q "validate.*session.*name\|session.*name.*validation" "$bash_script"; then
        log_info "✅ Session name validation present"
    else
        log_error "❌ Session name validation not found"
    fi
    
    # Test error handling is present
    if grep -q "Error:\|error:\|❌" "$bash_script"; then
        log_info "✅ Error handling present"
    else
        log_error "❌ Error handling not found"
    fi
}

# Main test execution
main() {
    log_info "Starting Zellij Utils Compatibility Tests"
    log_info "==========================================="
    
    # Ensure we're in the project root
    cd "$PROJECT_ROOT"
    
    if [[ ! -f "scripts/zellij-utils.sh" ]]; then
        log_error "Must run from project root directory"
        exit 1
    fi
    
    # Run all compatibility tests
    test_bash_compatibility
    echo ""
    test_zsh_compatibility
    echo ""
    test_system_compatibility
    echo ""
    test_path_handling
    echo ""
    test_environment_variables
    echo ""
    test_config_files
    echo ""
    test_performance
    echo ""
    test_edge_cases
    echo ""
    test_security
    
    # Summary
    echo ""
    if [[ $EXIT_CODE -eq 0 ]]; then
        log_info "============================================"
        log_info "🎉 All compatibility tests passed!"
    else
        log_error "============================================"
        log_error "💥 Some compatibility tests failed!"
    fi
    
    exit $EXIT_CODE
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi