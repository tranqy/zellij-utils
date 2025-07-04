---
title: "Quick Start Guide"
date: 2025-07-04
draft: false
weight: 5
---

# Quick Start Guide

Get up and running with Zellij Utils in under 5 minutes.

## Prerequisites

- **Zellij** 0.32.0 or higher
- **Bash** 4.0+ or **Zsh** 5.0+
- **Git** (for cloning the repository)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/tranqy/zellij-utils.git
cd zellij-utils
```

### 2. Run the Installer

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

The installer will:
- Copy utilities to `~/.config/shell/zellij-utils.sh`
- Copy layouts to `~/.config/zellij/layouts/`
- Set up example configuration (if needed)

### 3. Configure Your Shell

Add to your shell configuration:

**For Bash** (`~/.bashrc`):
```bash
source ~/.config/shell/zellij-utils.sh
```

**For Zsh** (`~/.zshrc`):
```bash
source ~/.config/shell/zellij-utils.sh
```

### 4. Reload Your Shell

```bash
source ~/.bashrc  # or ~/.zshrc
```

## Basic Usage

### Smart Session Management

The `zj` command is your main entry point:

```bash
# In any directory
zj              # Creates/attaches to contextually-named session

# In a git repository called "my-project"
zj              # Creates/attaches to "my-project" session

# Specify a name
zj work         # Creates/attaches to "work" session

# Use a specific layout
zj work dev     # Uses the "dev" layout
```

### List and Navigate Sessions

```bash
# List all sessions
zjl

# Switch to a session
zjs my-project

# Interactive session selection (requires fzf)
zjf
```

### Session Management

```bash
# Kill a specific session
zjk my-project

# Interactive session deletion
zjd

# Delete sessions matching a pattern
zjd --pattern "temp-*"
```

### Development Workflows

```bash
# Create a development workspace
zjwork my-project

# Create a development session with specific layout
zjdev my-project dev

# Quick git repository session
zjgit
```

## Your First Session

Let's create your first session:

1. **Navigate to a project directory**:
   ```bash
   cd ~/your-project
   ```

2. **Create a smart session**:
   ```bash
   zj
   ```

3. **Explore the interface**:
   - Sessions are named based on your directory/git repo
   - Use `Ctrl+p` followed by `d` to detach
   - Use `zj` again to re-attach

4. **Try different layouts**:
   ```bash
   zj dev          # Development layout with multiple panes
   zj simple       # Simple two-pane layout
   ```

## Common Workflows

### Daily Development

```bash
# Start your day
cd ~/projects/my-app
zj dev                    # Jump into development layout

# Work on different projects
cd ~/projects/api-server
zj                        # Smart session for API work

# Quick tasks
zj scratch               # Temporary session for experiments
```

### Remote Development

```bash
# SSH into your server
ssh user@server

# Continue your remote work
zj my-remote-project     # Session persists across SSH disconnections
```

### Team Collaboration

```bash
# Consistent session naming across team
cd ~/shared-project
zj                       # Everyone gets "shared-project" session

# Use shared layouts
zj team-layout           # Custom layout for team workflows
```

## Customization

### Environment Variables

```bash
# Disable auto-start
export ZJ_DISABLE_AUTO=1

# Custom dotfiles directory
export DOTFILES_DIR="$HOME/my-dotfiles"

# Disable auto-start in SSH only
export ZJ_NO_AUTO=1
```

### Custom Layouts

Create your own layouts in `~/.config/zellij/layouts/`:

```kdl
// ~/.config/zellij/layouts/my-layout.kdl
layout {
    tab name="main" {
        pane size=1 borderless=true {
            plugin location="tab-bar"
        }
        pane
    }
    tab name="logs" {
        pane command="tail" {
            args "-f" "/var/log/app.log"
        }
    }
}
```

Use it with:
```bash
zj my-project my-layout
```

## Next Steps

### Learn More

- [Examples](/guides/examples/) - See real-world usage patterns
- [FAQ](/guides/faq/) - Common questions and answers
- [Troubleshooting](/guides/troubleshooting/) - Fix common issues

### Join the Community

- **GitHub**: [Report issues and contribute](https://github.com/tranqy/zellij-utils)
- **Discussions**: Share workflows and get help
- **Discord**: Real-time community chat (coming soon)

### Advanced Features

- **Session Templates**: Create reusable session configurations
- **Multi-Machine Sync**: Synchronize sessions across machines
- **Plugin Integration**: Extend functionality with Zellij plugins

---

**Ready to supercharge your workflow?** Start with `zj` and explore the features that make your daily development more productive!