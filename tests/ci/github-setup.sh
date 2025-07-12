#!/bin/bash
# GitHub Actions environment specific setup

# GitHub Actions specific setup
github_setup() {
    log_info "Setting up GitHub Actions test environment"
    
    # Set GitHub Actions specific environment variables
    export GITHUB_ACTIONS_ENV=1
    export CI=true
    export DEBIAN_FRONTEND=noninteractive
    
    # GitHub Actions has a clean environment, minimal cleanup needed
    log_info "GitHub Actions: Basic cleanup"
    # Only kill test sessions in case of local usage with --env github-actions
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        # In real GitHub Actions, we can kill all zellij processes
        pkill -f zellij 2>/dev/null || true
        rm -rf /tmp/zellij-* 2>/dev/null || true
    else
        # When running locally with --env github-actions, be safe
        zellij list-sessions 2>/dev/null | grep -E "(test-|ci-)" | cut -d' ' -f1 | xargs -I{} zellij kill-session {} 2>/dev/null || true
        rm -rf /tmp/zellij-*test* 2>/dev/null || true
    fi
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    
    # Set up test directories with proper permissions
    mkdir -p ~/.config/zellij
    mkdir -p ~/.config/shell
    
    # Set up git config for tests
    if ! git config --global user.name >/dev/null 2>&1; then
        git config --global user.name "GitHub Actions"
        git config --global user.email "actions@github.com"
    fi
    
    log_success "GitHub Actions environment setup complete"
}

# GitHub Actions specific cleanup
github_cleanup() {
    log_info "GitHub Actions: Cleanup"
    
    # Safe cleanup for GitHub Actions
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        # In real GitHub Actions, we can kill all zellij processes
        pkill -f zellij 2>/dev/null || true
        rm -rf /tmp/zellij-* 2>/dev/null || true
    else
        # When running locally with --env github-actions, be safe
        zellij list-sessions 2>/dev/null | grep -E "(test-|ci-)" | cut -d' ' -f1 | xargs -I{} zellij kill-session {} 2>/dev/null || true
        rm -rf /tmp/zellij-*test* 2>/dev/null || true
    fi
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    
    log_info "GitHub Actions cleanup complete"
}

# Alias for native cleanup
native_cleanup() {
    github_cleanup
}

# Run GitHub setup
github_setup