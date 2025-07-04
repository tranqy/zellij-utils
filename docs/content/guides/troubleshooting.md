---
title: "Troubleshooting Guide"
date: 2025-07-04
draft: false
weight: 20
---

# Troubleshooting Guide

This guide helps you diagnose and fix common issues with Zellij Utils.

## Installation Issues

### Installation Script Fails

**Problem**: The installation script fails with permission or directory errors.

**Solution**:
```bash
# Make script executable
chmod +x scripts/install.sh

# Create directories manually if needed
mkdir -p ~/.config/shell
mkdir -p ~/.config/zellij/layouts

# Run with verbose output
bash -x scripts/install.sh
```

### Zellij Not Found

**Problem**: Error message "zellij: command not found"

**Diagnosis**:
```bash
which zellij
zellij --version
```

**Solution**:
```bash
# Install Zellij using cargo
cargo install zellij

# Or use package manager
# macOS
brew install zellij

# Ubuntu/Debian
apt install zellij

# Arch Linux
pacman -S zellij

# Add to PATH if needed
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Functions Not Available

**Problem**: Commands like `zj`, `zjl` not found after installation.

**Diagnosis**:
```bash
# Check if script exists
ls -la ~/.config/shell/zellij-utils.sh

# Check if sourced
type zj
```

**Solution**:
```bash
# Source the script manually
source ~/.config/shell/zellij-utils.sh

# Add to shell config permanently
echo 'source ~/.config/shell/zellij-utils.sh' >> ~/.bashrc
source ~/.bashrc

# For Zsh users
echo 'source ~/.config/shell/zellij-utils.sh' >> ~/.zshrc
source ~/.zshrc
```

## Session Management Issues

### Sessions Not Auto-Starting

**Problem**: Sessions don't start automatically in SSH or new terminals.

**Diagnosis**:
```bash
# Check environment variables
echo $ZJ_DISABLE_AUTO
echo $ZJ_NO_AUTO
echo $SSH_CONNECTION
```

**Solution**:
```bash
# Enable auto-start
unset ZJ_DISABLE_AUTO
unset ZJ_NO_AUTO

# Or modify in shell config
# Remove these lines if present:
# export ZJ_DISABLE_AUTO=1
# export ZJ_NO_AUTO=1

# Force auto-start in SSH
export ZJ_NO_AUTO=0
```

### Session Naming Issues

**Problem**: Sessions get generic names instead of smart names.

**Diagnosis**:
```bash
# Check current directory context
pwd
git remote -v
ls -la | grep -E "(package\.json|Cargo\.toml|go\.mod)"
```

**Solution**:
```bash
# Navigate to project root
cd /path/to/your/project

# Check git repository
git status

# Manually specify session name
zj myproject

# Debug session naming
bash -x ~/.config/shell/zellij-utils.sh
```

### Cannot Delete Sessions

**Problem**: `zjd` command fails or doesn't show sessions.

**Diagnosis**:
```bash
# Check active sessions
zellij list-sessions

# Check if fzf is installed (for interactive selection)
which fzf
```

**Solution**:
```bash
# Install fzf for interactive selection
# macOS
brew install fzf

# Ubuntu/Debian
apt install fzf

# Manual deletion
zellij delete-session session-name

# Force delete all sessions
zellij delete-all-sessions
```

## Layout and Configuration Issues

### Layouts Not Found

**Problem**: Error "Layout not found" when using custom layouts.

**Diagnosis**:
```bash
# Check layout directory
ls -la ~/.config/zellij/layouts/

# Check Zellij config
zellij --help
```

**Solution**:
```bash
# Copy layouts manually
cp layouts/*.kdl ~/.config/zellij/layouts/

# Verify layout files
ls ~/.config/zellij/layouts/
cat ~/.config/zellij/layouts/dev.kdl

# Use absolute path
zj myproject ~/.config/zellij/layouts/dev.kdl
```

### Config File Conflicts

**Problem**: Existing Zellij config conflicts with Zellij Utils.

**Diagnosis**:
```bash
# Check existing config
ls -la ~/.config/zellij/
cat ~/.config/zellij/config.kdl
```

**Solution**:
```bash
# Backup existing config
cp ~/.config/zellij/config.kdl ~/.config/zellij/config.kdl.backup

# Merge configurations manually
# Or use the example config
cp config-examples/config.kdl ~/.config/zellij/config.kdl
```

## Performance Issues

### Slow Session Creation

**Problem**: Sessions take a long time to create.

**Diagnosis**:
```bash
# Time session creation
time zj test-session

# Check for large git repositories
du -sh .git/
```

**Solution**:
```bash
# Disable git detection for large repos
export ZJ_NO_GIT_DETECTION=1

# Use specific session names
zj specific-name

# Clean up git repository
git gc
git prune
```

### High Memory Usage

**Problem**: Zellij or utils consuming excessive memory.

**Diagnosis**:
```bash
# Check running processes
ps aux | grep zellij
top -p $(pgrep zellij)
```

**Solution**:
```bash
# Kill unused sessions
zjd --all

# Restart Zellij server
zellij kill-all-sessions
pkill zellij

# Check for memory leaks
valgrind zellij
```

## Shell Compatibility Issues

### Bash Version Problems

**Problem**: Functions don't work in older Bash versions.

**Diagnosis**:
```bash
bash --version
echo $BASH_VERSION
```

**Solution**:
```bash
# Update Bash (macOS)
brew install bash

# Update Bash (Linux)
# Use your package manager

# Add new Bash to /etc/shells
echo /usr/local/bin/bash >> /etc/shells
chsh -s /usr/local/bin/bash
```

### Zsh Compatibility

**Problem**: Functions behave differently in Zsh.

**Diagnosis**:
```bash
echo $ZSH_VERSION
echo $SHELL
```

**Solution**:
```bash
# Add to .zshrc
echo 'source ~/.config/shell/zellij-utils.sh' >> ~/.zshrc

# Set shell options if needed
setopt BASH_REMATCH
```

### Fish Shell Issues

**Problem**: Functions not available in Fish shell.

**Solution**:
```bash
# Fish shell support is planned but not yet available
# Use Bash or Zsh for now

# Or create Fish-specific functions
# (Community contributions welcome!)
```

## Network and Remote Issues

### SSH Connection Problems

**Problem**: Functions don't work over SSH.

**Diagnosis**:
```bash
# Check SSH environment
echo $SSH_CLIENT
echo $SSH_CONNECTION
printenv | grep SSH
```

**Solution**:
```bash
# Enable SSH support
unset ZJ_NO_AUTO

# Forward necessary environment variables
ssh -A -t user@host 'source ~/.config/shell/zellij-utils.sh; zj'

# Set up SSH config
# In ~/.ssh/config:
# Host myserver
#   ForwardAgent yes
#   RequestTTY yes
```

### Session Persistence Issues

**Problem**: Sessions don't persist across SSH disconnections.

**Diagnosis**:
```bash
# Check if sessions are running
zellij list-sessions

# Check Zellij server status
ps aux | grep zellij
```

**Solution**:
```bash
# Ensure Zellij server is running
zellij list-sessions

# Create detached session
zj --detached mysession

# Use nohup for critical sessions
nohup zellij attach mysession &
```

## Advanced Troubleshooting

### Debug Mode

Enable debug output for detailed troubleshooting:

```bash
# Enable debug mode
export ZJ_DEBUG=1

# Run with verbose output
bash -x ~/.config/shell/zellij-utils.sh

# Check function execution
set -x
zj debug-session
set +x
```

### Log Analysis

```bash
# Check Zellij logs
tail -f ~/.cache/zellij/zellij.log

# Check system logs
journalctl -u zellij
```

### Environment Reset

If all else fails, reset your environment:

```bash
# Kill all Zellij processes
pkill zellij

# Remove cache
rm -rf ~/.cache/zellij

# Reset configuration
mv ~/.config/zellij ~/.config/zellij.backup
mkdir ~/.config/zellij

# Reinstall
./scripts/install.sh
```

## Getting More Help

### Diagnostic Information

When reporting issues, include:

```bash
# System information
uname -a
echo $SHELL
bash --version || zsh --version

# Zellij information
zellij --version
zellij list-sessions

# Environment variables
env | grep ZJ
env | grep ZELLIJ

# Function availability
type zj
type zjl
```

### Creating Bug Reports

1. **Use the issue template** on GitHub
2. **Include diagnostic information** (see above)
3. **Provide steps to reproduce** the issue
4. **Include error messages** and logs
5. **Mention your environment** (OS, shell, Zellij version)

### Community Support

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and help
- **Discord**: For real-time support (coming soon)

---

**Still having issues?** [Open a detailed issue on GitHub](https://github.com/tranqy/zellij-utils/issues/new/choose) with the diagnostic information above.