# Dockerfile for Zellij Utils Test Environment
FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Basic tools
    curl \
    wget \
    git \
    bash \
    zsh \
    # Build tools
    build-essential \
    pkg-config \
    # Required for zellij
    libssl-dev \
    # Test utilities
    bc \
    inotify-tools \
    # Text processing
    sed \
    grep \
    gawk \
    # Network tools for downloads
    ca-certificates \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install Rust and Cargo (required for zellij)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install zellij from source for latest version
RUN git clone https://github.com/zellij-org/zellij.git /tmp/zellij \
    && cd /tmp/zellij \
    && cargo build --release \
    && cp target/release/zellij /usr/local/bin/ \
    && chmod +x /usr/local/bin/zellij \
    && rm -rf /tmp/zellij

# Install fzf for fuzzy finding features
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/fzf \
    && /usr/local/fzf/install --bin \
    && ln -s /usr/local/fzf/bin/fzf /usr/local/bin/fzf

# Create test user (non-root for realistic testing)
RUN useradd -m -s /bin/bash testuser \
    && usermod -aG sudo testuser \
    && echo "testuser:testuser" | chpasswd

# Set up test environment directories
RUN mkdir -p /home/testuser/.config/zellij \
    && mkdir -p /home/testuser/.config/shell \
    && mkdir -p /home/testuser/test-workspace \
    && mkdir -p /app/test-results \
    && chown -R testuser:testuser /home/testuser \
    && chown -R testuser:testuser /app

# Copy project files to container
COPY . /app/zellij-utils
RUN chown -R testuser:testuser /app/zellij-utils

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Set up shell environment with better isolation
RUN echo 'export EDITOR=nano' >> ~/.bashrc \
    && echo 'export SHELL=/bin/bash' >> ~/.bashrc \
    && echo 'export ZELLIJ_CONFIG_DIR=/home/testuser/.config/zellij' >> ~/.bashrc \
    && echo 'export ZJ_DISABLE_AUTO=1' >> ~/.bashrc \
    && echo 'export ZJ_TEST_MODE=1' >> ~/.bashrc

# Create test git configuration
RUN git config --global user.name "Test User" \
    && git config --global user.email "test@example.com" \
    && git config --global init.defaultBranch main

# Verify installations
RUN zellij --version \
    && git --version \
    && fzf --version

# Set working directory to project
WORKDIR /app/zellij-utils

# Add session cleanup on container start
RUN echo '#!/bin/bash' > /usr/local/bin/cleanup-sessions.sh \
    && echo 'pkill -f zellij 2>/dev/null || true' >> /usr/local/bin/cleanup-sessions.sh \
    && echo 'rm -rf ~/.cache/zellij/* 2>/dev/null || true' >> /usr/local/bin/cleanup-sessions.sh \
    && echo 'rm -rf /tmp/zellij-* 2>/dev/null || true' >> /usr/local/bin/cleanup-sessions.sh \
    && chmod +x /usr/local/bin/cleanup-sessions.sh

# Default command runs the test suite with cleanup
CMD ["/bin/bash", "-c", "cleanup-sessions.sh && ./docker/run_tests.sh"]