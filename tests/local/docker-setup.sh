#!/bin/bash
# Docker environment specific setup

# Docker-specific environment setup
docker_setup() {
    log_info "Setting up Docker test environment"
    
    # Set Docker-specific environment variables
    export DOCKER_CONTAINER=1
    export HOME="/home/testuser"
    export USER="testuser"
    export SHELL="/bin/bash"
    export ZELLIJ_CONFIG_DIR="/home/testuser/.config/zellij"
    
    # Docker-specific comprehensive cleanup
    log_info "Docker: Comprehensive session cleanup"
    pkill -f zellij 2>/dev/null || true
    pkill -f "zellij.*" 2>/dev/null || true
    sleep 2
    
    # Clean Docker-specific paths
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    rm -rf /tmp/zellij-* 2>/dev/null || true
    rm -rf /tmp/*zellij* 2>/dev/null || true
    rm -rf /tmp/zellij-$(id -u)/ 2>/dev/null || true
    
    log_success "Docker environment setup complete"
}

# Docker-specific cleanup
docker_cleanup() {
    log_info "Docker: Comprehensive cleanup"
    
    # Kill all zellij processes
    pkill -f zellij 2>/dev/null || true
    pkill -f "zellij.*" 2>/dev/null || true
    sleep 2
    
    # Clean all temporary files
    rm -rf ~/.cache/zellij/* 2>/dev/null || true
    rm -rf /tmp/zellij-* 2>/dev/null || true
    rm -rf /tmp/*zellij* 2>/dev/null || true
    rm -rf /tmp/zellij-$(id -u)/ 2>/dev/null || true
    rm -rf /tmp/test-* /tmp/*-test* 2>/dev/null || true
    
    # More comprehensive cleanup for Docker
    find /tmp -name "*zellij*" -type f -delete 2>/dev/null || true
    find /tmp -name "*zellij*" -type d -exec rm -rf {} + 2>/dev/null || true
    
    log_info "Docker cleanup complete"
}

# Run Docker setup
docker_setup