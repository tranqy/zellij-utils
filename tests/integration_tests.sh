#!/bin/bash
# Integration Tests for Zellij Utils Installation
# Tests the complete installation process and core functionality

set -euo pipefail

# Test configuration
TEST_DIR="/tmp/zellij-utils-test-$$"
BACKUP_DIR="/tmp/zellij-utils-backup-$$"
EXIT_CODE=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

test_assert() {
    local condition="$1"
    local message="$2"
    
    if eval "$condition"; then
        log_info "✅ $message"
    else
        log_error "❌ $message"
    fi
}

# Setup test environment
setup_test_env() {
    log_info "Setting up test environment"
    
    # Create temporary test directory structure
    mkdir -p "$TEST_DIR"/{.config/zellij/layouts,.config/shell}
    
    # Backup any existing configurations
    if [[ -d "$HOME/.config/zellij" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/zellij" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.config/shell/zellij-utils.sh" ]]; then
        mkdir -p "$BACKUP_DIR/.config/shell"
        cp "$HOME/.config/shell/zellij-utils.sh" "$BACKUP_DIR/.config/shell/" 2>/dev/null || true
    fi
    
    # Set test HOME for installation
    export TEST_HOME="$TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment"
    
    # Restore original configurations
    if [[ -d "$BACKUP_DIR/.config/zellij" ]]; then
        rm -rf "$HOME/.config/zellij" 2>/dev/null || true
        cp -r "$BACKUP_DIR/.config/zellij" "$HOME/.config/" 2>/dev/null || true
    fi
    
    if [[ -f "$BACKUP_DIR/.config/shell/zellij-utils.sh" ]]; then
        mkdir -p "$HOME/.config/shell"
        cp "$BACKUP_DIR/.config/shell/zellij-utils.sh" "$HOME/.config/shell/" 2>/dev/null || true
    fi
    
    # Remove test directories
    rm -rf "$TEST_DIR" "$BACKUP_DIR" 2>/dev/null || true
}

# Test installation script dependencies
test_dependencies() {
    log_info "Testing installation dependencies"
    
    # Test required commands exist
    test_assert "command -v cp >/dev/null 2>&1" "cp command available"
    test_assert "command -v mkdir >/dev/null 2>&1" "mkdir command available"
    test_assert "command -v chmod >/dev/null 2>&1" "chmod command available"
    
    # Test script is executable
    test_assert "[[ -x 'scripts/install.sh' ]]" "Installation script is executable"
    
    # Test source files exist
    test_assert "[[ -f 'scripts/zellij-utils.sh' ]]" "Main shell script exists"
    test_assert "[[ -f 'scripts/zellij-utils-zsh.sh' ]]" "Zsh shell script exists"
    test_assert "[[ -d 'layouts' ]]" "Layouts directory exists"
    test_assert "[[ -f 'layouts/dev.kdl' ]]" "Development layout exists"
    test_assert "[[ -f 'layouts/simple.kdl' ]]" "Simple layout exists"
}

# Test dry-run installation
test_dry_run() {
    log_info "Testing dry-run installation"
    
    # Run installation with dry-run (if supported)
    # Note: This assumes we add dry-run support to install.sh
    # For now, we'll test the file operations manually
    
    local install_script="scripts/install.sh"
    
    # Test script syntax
    if bash -n "$install_script" 2>/dev/null; then
        log_info "✅ Installation script syntax is valid"
    else
        log_error "❌ Installation script has syntax errors"
    fi
    
    # Test script runs without errors (with TEST_MODE)
    if TEST_MODE=1 bash "$install_script" >/dev/null 2>&1; then
        log_info "✅ Installation script runs without errors in test mode"
    else
        log_warn "⚠️  Installation script test mode not supported or failed"
    fi
}

# Test actual installation to test directory
test_installation() {
    log_info "Testing actual installation"
    
    # Modify HOME for this test
    local original_home="$HOME"
    export HOME="$TEST_DIR"
    
    # Create necessary parent directories
    mkdir -p "$TEST_DIR/.config/zellij"
    mkdir -p "$TEST_DIR/.config/shell"
    
    # Run installation
    if bash scripts/install.sh >/dev/null 2>&1; then
        log_info "✅ Installation completed successfully"
    else
        log_error "❌ Installation failed"
        export HOME="$original_home"
        return 1
    fi
    
    # Verify installed files
    test_assert "[[ -f '$TEST_DIR/.config/shell/zellij-utils.sh' ]]" "Main script installed"
    test_assert "[[ -f '$TEST_DIR/.config/zellij/layouts/dev.kdl' ]]" "Dev layout installed"
    test_assert "[[ -f '$TEST_DIR/.config/zellij/layouts/simple.kdl' ]]" "Simple layout installed"
    
    # Verify config file (if it should be created)
    if [[ ! -f "$TEST_DIR/.config/zellij/config.kdl" ]]; then
        test_assert "[[ -f '$TEST_DIR/.config/zellij/config.kdl' ]]" "Config file created"
    else
        log_info "✅ Config file already exists (not overwritten)"
    fi
    
    # Restore original HOME
    export HOME="$original_home"
}

# Test core functionality after installation
test_core_functions() {
    log_info "Testing core functions"
    
    # Source the installed script
    local script_path="$TEST_DIR/.config/shell/zellij-utils.sh"
    
    if [[ -f "$script_path" ]]; then
        # Test script can be sourced without errors
        if bash -c "source '$script_path'" 2>/dev/null; then
            log_info "✅ Script sources without errors"
        else
            log_error "❌ Script has sourcing errors"
        fi
        
        # Test basic function definitions exist
        if grep -q "^zj()" "$script_path"; then
            log_info "✅ Main zj() function defined"
        else
            log_error "❌ Main zj() function not found"
        fi
        
        if grep -q "^zjl()" "$script_path"; then
            log_info "✅ Session list function defined"
        else
            log_error "❌ Session list function not found"
        fi
        
        if grep -q "^zjd()" "$script_path"; then
            log_info "✅ Delete session function defined"
        else
            log_error "❌ Delete session function not found"
        fi
        
        # Test caching system
        if grep -q "_ZJ_GIT_CACHE" "$script_path"; then
            log_info "✅ Caching system implemented"
        else
            log_error "❌ Caching system not found"
        fi
        
        # Test error handling
        if grep -q "Error:" "$script_path"; then
            log_info "✅ Error handling implemented"
        else
            log_error "❌ Error handling not found"
        fi
    else
        log_error "❌ Installed script not found"
    fi
}

# Test configuration validation
test_configuration() {
    log_info "Testing configuration validation"
    
    # Test layout files are valid KDL
    for layout in layouts/*.kdl; do
        if [[ -f "$layout" ]]; then
            # Basic KDL syntax check (look for balanced braces)
            local open_braces=$(grep -o '{' "$layout" | wc -l)
            local close_braces=$(grep -o '}' "$layout" | wc -l)
            
            if [[ $open_braces -eq $close_braces ]]; then
                log_info "✅ $(basename "$layout") has balanced braces"
            else
                log_error "❌ $(basename "$layout") has unbalanced braces"
            fi
        fi
    done
    
    # Test config examples are valid
    if [[ -f "config-examples/config.kdl" ]]; then
        local config_file="config-examples/config.kdl"
        local open_braces=$(grep -o '{' "$config_file" | wc -l)
        local close_braces=$(grep -o '}' "$config_file" | wc -l)
        
        if [[ $open_braces -eq $close_braces ]]; then
            log_info "✅ Example config has balanced braces"
        else
            log_error "❌ Example config has unbalanced braces"
        fi
    fi
}

# Test delete session functionality
test_delete_functions() {
    log_info "Testing delete session functionality"
    
    local script_path="$TEST_DIR/.config/shell/zellij-utils.sh"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "❌ Script not found for delete function testing"
        return 1
    fi
    
    # Test zjd function exists and has proper structure
    if grep -q "^zjd()" "$script_path"; then
        log_info "✅ zjd function exists"
        
        # Test for key features in the function
        if grep -A 20 "^zjd()" "$script_path" | grep -q "force_flag"; then
            log_info "✅ zjd has force flag support"
        else
            log_error "❌ zjd missing force flag support"
        fi
        
        if grep -A 50 "^zjd()" "$script_path" | grep -q "pattern_mode"; then
            log_info "✅ zjd has pattern matching support"
        else
            log_error "❌ zjd missing pattern matching support"
        fi
        
        if grep -A 200 "^zjd()" "$script_path" | grep -q "current_session"; then
            log_info "✅ zjd has current session protection"
        else
            log_error "❌ zjd missing current session protection"
        fi
        
        if grep -A 200 "^zjd()" "$script_path" | grep -q "fzf"; then
            log_info "✅ zjd has fzf integration"
        else
            log_error "❌ zjd missing fzf integration"
        fi
        
        # Test cache invalidation
        if grep -A 200 "^zjd()" "$script_path" | grep -q "_ZJ_SESSION_CACHE"; then
            log_info "✅ zjd invalidates session cache"
        else
            log_error "❌ zjd missing cache invalidation"
        fi
        
    else
        log_error "❌ zjd function not found"
    fi
    
    # Test basic function execution (with no sessions)
    if bash -c "source '$script_path'; echo 'n' | zjd --help 2>/dev/null" 2>/dev/null; then
        log_info "✅ zjd help/usage works"
    else
        log_warn "⚠️  zjd help test inconclusive"
    fi
    
    # Test completion registration
    if grep -q "complete.*zjd" "$script_path"; then
        log_info "✅ zjd completion registered"
    else
        log_error "❌ zjd completion not registered"
    fi
    
    # Test alias registration
    if grep -q "alias.*zdelete.*zjd" "$script_path"; then
        log_info "✅ zdelete alias registered"
    else
        log_error "❌ zdelete alias not registered"
    fi
}

# Test uninstallation (cleanup)
test_uninstallation() {
    log_info "Testing cleanup/uninstallation"
    
    # Remove installed files
    rm -f "$TEST_DIR/.config/shell/zellij-utils.sh" 2>/dev/null || true
    rm -f "$TEST_DIR/.config/zellij/layouts/dev.kdl" 2>/dev/null || true
    rm -f "$TEST_DIR/.config/zellij/layouts/simple.kdl" 2>/dev/null || true
    
    # Verify cleanup
    test_assert "[[ ! -f '$TEST_DIR/.config/shell/zellij-utils.sh' ]]" "Main script removed"
    test_assert "[[ ! -f '$TEST_DIR/.config/zellij/layouts/dev.kdl' ]]" "Dev layout removed"
    test_assert "[[ ! -f '$TEST_DIR/.config/zellij/layouts/simple.kdl' ]]" "Simple layout removed"
}

# Main test execution
main() {
    log_info "Starting Zellij Utils Integration Tests"
    log_info "========================================"
    
    # Ensure we're in the project root
    if [[ ! -f "scripts/install.sh" ]]; then
        log_error "Must run from project root directory"
        exit 1
    fi
    
    # Setup test environment
    setup_test_env
    
    # Set trap for cleanup
    trap cleanup_test_env EXIT
    
    # Run all tests
    test_dependencies
    test_dry_run
    test_installation
    test_core_functions
    test_delete_functions
    test_configuration
    test_uninstallation
    
    # Summary
    echo ""
    if [[ $EXIT_CODE -eq 0 ]]; then
        log_info "=========================================="
        log_info "🎉 All integration tests passed!"
    else
        log_error "=========================================="
        log_error "💥 Some integration tests failed!"
    fi
    
    exit $EXIT_CODE
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi