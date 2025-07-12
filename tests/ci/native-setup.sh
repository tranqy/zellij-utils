#!/bin/bash
# Native environment specific setup (for local non-Docker testing)

# Native environment setup
native_setup() {
    log_info "Setting up native test environment"
    
    # Set native environment variables
    export NATIVE_ENV=1
    
    # Create test-specific directories to avoid conflicts
    export TEST_HOME="${TEST_HOME:-$HOME/.zellij-utils-test}"
    export ZELLIJ_CONFIG_DIR="$TEST_HOME/.config/zellij"
    
    mkdir -p "$TEST_HOME/.config/zellij"
    mkdir -p "$TEST_HOME/.config/shell"
    
    # Gentle cleanup for native environment
    log_info "Native: Cleaning test-specific sessions"
    
    # Only kill test sessions, not user's actual sessions
    zellij list-sessions 2>/dev/null | grep -E "(test-|ci-)" | cut -d' ' -f1 | xargs -I{} zellij kill-session {} 2>/dev/null || true
    
    # Clean only test-related temporary files
    rm -rf /tmp/zellij-*test* 2>/dev/null || true
    rm -rf /tmp/test-* 2>/dev/null || true
    
    log_success "Native environment setup complete"
}

# Native environment cleanup
native_cleanup() {
    log_info "Native: Cleanup test environment"
    
    # Only clean test-specific sessions and files
    zellij list-sessions 2>/dev/null | grep -E "(test-|ci-)" | cut -d' ' -f1 | xargs -I{} zellij kill-session {} 2>/dev/null || true
    
    # Clean test-specific temporary files
    rm -rf /tmp/zellij-*test* 2>/dev/null || true
    rm -rf /tmp/test-* 2>/dev/null || true
    rm -rf "$TEST_HOME" 2>/dev/null || true
    
    log_info "Native cleanup complete"
}

# Run native setup
native_setup