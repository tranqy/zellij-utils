#!/bin/bash
# Cleanup script for Zellij sessions before running tests
# Ensures complete session isolation in Docker containers

set -euo pipefail

echo "🧹 Cleaning up any existing zellij sessions..."

# Kill all zellij processes
pkill -f zellij 2>/dev/null || true
pkill -f "zellij.*" 2>/dev/null || true

# Wait for processes to fully terminate
sleep 3

# Clean up zellij cache and temporary files
rm -rf ~/.cache/zellij/* 2>/dev/null || true
rm -rf /tmp/zellij-* 2>/dev/null || true
rm -rf /tmp/*zellij* 2>/dev/null || true

# Ensure clean socket directory for current user
USER_ID=$(id -u)
rm -rf "/tmp/zellij-$USER_ID/" 2>/dev/null || true

# Clean up any session files that might exist
find /tmp -name "*zellij*" -type f -delete 2>/dev/null || true
find /tmp -name "*zellij*" -type d -exec rm -rf {} + 2>/dev/null || true

# Final wait to ensure cleanup completion
sleep 2

echo "✅ Session cleanup complete"