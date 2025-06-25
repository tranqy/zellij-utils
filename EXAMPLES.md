# Zellij Utils - Usage Examples

This file contains practical examples of how to use zellij-utils in different scenarios.

## Basic Session Management

```bash
# Start a session based on current directory
cd ~/projects/my-app
zj  # Creates/attaches to "my-app" session

# Start a named session
zj work  # Creates/attaches to "work" session

# Start session with specific layout
zj my-project dev  # Uses the "dev" layout

# List all sessions
zjl

# Switch between sessions
zjs work
zjs my-app

# Kill specific session
zjk old-project

# Kill all sessions except current
zjka
```

## Directory-Based Workflows

```bash
# Home directory always creates "home" session
cd ~
zj  # → "home" session

# Git repositories use repo name
cd ~/projects/awesome-app
zj  # → "awesome-app" session (git repo name)

# Config files get "config" session
cd ~/.config/nvim
zj  # → "config" session

# Documents get "docs" session
cd ~/Documents/reports
zj  # → "docs" session
```

## Development Workflows

```bash
# Quick development setup
cd ~/projects/web-app
zjwork  # Creates multi-pane development environment

# Start development session with specific layout
zjdev backend-api dev

# Work on git project
cd ~/projects/some-repo
zjgit  # Goes to repo root and starts session

# Manage dotfiles
zjdot  # Goes to $DOTFILES_DIR and starts "dotfiles" session
```

## Advanced Usage

```bash
# Fuzzy find sessions (requires fzf)
zjf

# Get session information
zjinfo

# View system status
zjstatus

# Save current session layout
zjsave

# List saved sessions
zjsaved
```

## Integration Examples

### With VS Code

1. Open VS Code in a project directory
2. Open terminal (Ctrl+`)
3. Automatically attached to project session
4. Work persists even if you close VS Code

### With Git Workflows

```bash
# Working on feature branch
cd ~/projects/my-app
git checkout -b feature/new-feature
zj  # Still uses "my-app" session (repo name)

# Switching between projects
zjs backend-api  # Switch to backend work
zjs frontend     # Switch to frontend work
```

### With Different Project Types

```bash
# Node.js project
cd ~/projects/node-app  # Has package.json
zj  # → "node-app" session

# Rust project  
cd ~/projects/rust-app  # Has Cargo.toml
zj  # → "rust-app" session

# Go project
cd ~/projects/go-app    # Has go.mod
zj  # → "go-app" session

# Regular directory
cd ~/projects/scripts
zj  # → "scripts" session
```

## Common Patterns

### Daily Workflow

```bash
# Morning: Start main sessions
zjh          # Home session for general tasks
zjwork blog  # Development session for blog
zj notes     # Session for note-taking

# During day: Switch as needed
zjs blog     # Work on blog
zjs notes    # Take notes
zjs home     # General tasks

# Evening: Clean up
zjka         # Kill all except current
```

### Project Management

```bash
# Start new project
mkdir ~/projects/new-project
cd ~/projects/new-project
git init
zj  # Automatically creates "new-project" session

# Work on multiple projects
zjs project-a
zjs project-b
zjs project-c

# Check what's running
zjl
```

### SSH and Remote Work

```bash
# Disable auto-start for SSH sessions
export ZJ_NO_AUTO=1
ssh user@remote-host

# Or manually start sessions on remote
ssh user@remote-host
zj remote-work
```

## Layout Examples

### Using the dev layout
```bash
cd ~/projects/web-app
zj web-app dev
# Creates session with:
# - Main tab with editor (70%) and terminal/logs (30%)
# - Server tab for running development server
# - Git tab with status and log views
```

### Using the simple layout
```bash
zj meeting-notes simple
# Creates session with:
# - Main tab with two panes (75%/25%)
# - Scratch tab for temporary work
```

## Customization Examples

### Environment Variables

```bash
# In your .bashrc/.zshrc
export DOTFILES_DIR="$HOME/dotfiles"      # Custom dotfiles location
export ZJ_NO_AUTO=1                       # Disable auto-start in SSH
export ZJ_DISABLE_AUTO=1                  # Disable auto-start completely
export EDITOR="code --wait"               # Use VS Code as editor
```

### Custom Aliases

```bash
# Add to your shell config
alias dev='zjwork'           # Quick development setup
alias notes='zj notes'       # Quick notes session  
alias config='zjc'           # Quick config session
alias dots='zjdot'           # Quick dotfiles session
```

### Project-Specific Setup

```bash
# In a project directory, create a setup script
#!/bin/bash
# setup-dev.sh
zj $(basename "$PWD") dev
zellij action new-tab --name "server"
zellij action new-tab --name "tests"
zellij action go-to-tab 1
```

## Troubleshooting Examples

### Session not found
```bash
# Check what sessions exist
zjl

# Create new session if needed
zj my-session

# Or switch to existing one
zjs existing-session
```

### Layout not working
```bash
# Check if layout exists
ls ~/.config/zellij/layouts/

# Use session without layout first
zj test-session

# Then try with layout
zj test-session dev
```

### Auto-start issues
```bash
# Check if already in zellij
echo $ZELLIJ_SESSION_NAME

# Check environment variables
echo $ZJ_DISABLE_AUTO
echo $ZJ_NO_AUTO

# Manual start if needed
zj manual-session
```

## Pro Tips

1. **Session Naming**: Use consistent naming patterns for easier management
2. **Layout Usage**: Start with simple layouts and gradually customize
3. **VS Code Integration**: Use separate terminal profiles for zellij and regular terminals
4. **Git Integration**: Let zellij auto-detect git repos for consistent naming
5. **Persistence**: Sessions survive computer reboots, so clean up regularly with `zjka`

These examples should help you get the most out of zellij-utils! Adjust the patterns to fit your specific workflow.