---
title: "Frequently Asked Questions"
date: 2025-07-04
draft: false
weight: 10
---

# Frequently Asked Questions

## General Questions

### What is Zellij Utils?

Zellij Utils is a collection of shell functions and utilities designed to enhance your Zellij terminal multiplexer experience. It provides smart session management, automated workflows, and powerful utilities for developers who use Zellij.

### How is this different from tmux utilities?

While tmux utilities focus on tmux-specific features, Zellij Utils is built specifically for Zellij's architecture and features. We take advantage of Zellij's layout system, session management, and modern terminal capabilities.

### Do I need to know Zellij to use this?

Basic Zellij knowledge is helpful, but Zellij Utils is designed to make Zellij easier to use. If you're new to terminal multiplexers, this might actually be a great way to get started with Zellij.

## Installation & Setup

### What are the system requirements?

- **Zellij**: Version 0.32.0 or higher
- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Optional**: `fzf` for fuzzy session selection
- **Operating System**: Linux, macOS, or WSL

### The installation script didn't work. What should I do?

Common issues and solutions:

1. **Permission denied**: Make sure the script is executable:
   ```bash
   chmod +x scripts/install.sh
   ```

2. **Directory doesn't exist**: The script creates directories automatically, but if you get errors:
   ```bash
   mkdir -p ~/.config/shell
   mkdir -p ~/.config/zellij/layouts
   ```

3. **Zellij not found**: Install Zellij first:
   ```bash
   # Using cargo
   cargo install zellij
   
   # Using package manager (examples)
   brew install zellij        # macOS
   apt install zellij         # Ubuntu/Debian
   ```

### Can I install this without the installer script?

Yes! Manual installation:

```bash
# Copy the main script
cp scripts/zellij-utils.sh ~/.config/shell/

# Copy layouts
cp layouts/*.kdl ~/.config/zellij/layouts/

# Copy example config (if needed)
cp config-examples/config.kdl ~/.config/zellij/config.kdl

# Add to your shell config
echo 'source ~/.config/shell/zellij-utils.sh' >> ~/.bashrc
```

## Usage Questions

### How does smart session naming work?

The `zj` command determines session names using this priority:

1. **Git repository name** (if in a git repo)
2. **Project detection** (package.json, Cargo.toml, go.mod present)
3. **Special directories**:
   - `$HOME` → "home"
   - `$HOME/.config/*` → "config"
   - `$HOME/Documents/*` → "docs"
4. **Current directory basename** as fallback

### Can I customize the session naming logic?

Yes! You can modify the `_zj_get_session_name` function in the script or set environment variables:

```bash
# Custom dotfiles directory
export DOTFILES_DIR="$HOME/my-dotfiles"

# Disable auto-start
export ZJ_DISABLE_AUTO=1
```

### What layouts are available?

Default layouts included:

- **dev**: Development layout with editor, terminal, logs, server, and git tabs
- **simple**: Basic two-pane layout

You can create custom layouts in `~/.config/zellij/layouts/` and use them with:
```bash
zj myproject mylayout
```

### How do I delete sessions safely?

The `zjd` command provides multiple options:

```bash
# Interactive selection with fzf
zjd

# Delete specific session (with confirmation)
zjd myproject

# Delete with pattern matching
zjd --pattern "temp-*"

# Force delete (skip confirmations)
zjd --force myproject

# Delete all sessions except current
zjd --all
```

## Troubleshooting

### Functions not found after installation

Make sure you've sourced the script:

```bash
source ~/.config/shell/zellij-utils.sh
```

Add this line to your shell configuration file:
- **Bash**: `~/.bashrc`
- **Zsh**: `~/.zshrc`

### Sessions not auto-starting

Check these environment variables:

```bash
# Disable auto-start completely
export ZJ_DISABLE_AUTO=1

# Disable auto-start in SSH sessions only
export ZJ_NO_AUTO=1
```

### Zellij layouts not found

Ensure layouts are in the correct directory:

```bash
ls ~/.config/zellij/layouts/
```

If missing, copy them:
```bash
cp layouts/*.kdl ~/.config/zellij/layouts/
```

### Performance issues with large repositories

For large git repositories, you might want to disable git repo detection:

```bash
# Add to your shell config
export ZJ_NO_GIT_DETECTION=1
```

### Shell compatibility issues

If you encounter issues with specific shells:

1. **Zsh**: Make sure you're using Zsh 5.0+
2. **Bash**: Ensure Bash 4.0+ (check with `bash --version`)
3. **Fish**: Currently not supported, but we're working on it

### Session conflicts with existing tools

If you have conflicts with other session managers:

```bash
# Disable auto-start
export ZJ_DISABLE_AUTO=1

# Use full command names
source ~/.config/shell/zellij-utils.sh
```

## Advanced Usage

### Can I use this with remote servers?

Absolutely! This is one of the main use cases. Install on your remote server and:

1. SSH into your server
2. Run `zj` to create/attach to sessions
3. Disconnect and reconnect anytime
4. Your sessions persist across connections

### How do I share layouts with my team?

1. Create custom layouts in your project:
   ```bash
   mkdir .zellij-layouts
   # Create .kdl files
   ```

2. Copy to team members' systems:
   ```bash
   cp .zellij-layouts/*.kdl ~/.config/zellij/layouts/
   ```

### Can I integrate with my IDE?

Yes! Many IDEs support terminal integration:

- **VS Code**: Use the integrated terminal
- **Neovim**: Terminal mode works great
- **Emacs**: Terminal emulation support

## Getting Help

### Where can I report bugs?

Please use our GitHub issue templates:
- **Bug Report**: For reproducible issues
- **Feature Request**: For new functionality
- **Question**: For usage questions

### How can I contribute?

We welcome contributions! See our [Contributing Guide](https://github.com/tranqy/zellij-utils/blob/main/CONTRIBUTING.md) for:
- Code contributions
- Documentation improvements
- Bug reports and testing
- Feature ideas

### Is there a community chat?

We're setting up community channels:
- **GitHub Discussions**: For longer-form discussions
- **Discord**: For real-time chat (coming soon)
- **Matrix**: For open-source community members

---

**Didn't find your question?** [Open an issue on GitHub](https://github.com/tranqy/zellij-utils/issues/new/choose) and we'll help you out!