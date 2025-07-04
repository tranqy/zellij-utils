---
title: "Zellij Utils"
description: "Supercharge your Zellij terminal multiplexer workflows"
---

# Zellij Utils

A collection of powerful, configuration-driven shell utilities to streamline your [Zellij](https://github.com/zellij-org/zellij) workflows.

## Why use Zellij Utils?

- **Smart Session Management**: Automatically name sessions based on your current project, git repository, or directory
- **Persistent & Remote Workflows**: Keep your sessions alive on remote machines for seamless disconnection/reconnection
- **Effortless Workspaces**: Jump directly into pre-defined development layouts with a single command
- **Safety and Control**: Interactive session deletion with confirmations to prevent accidental data loss
- **Highly Configurable**: Customize everything from session naming to auto-start behavior

Stop thinking about managing your multiplexer and start focusing on your work.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/tranqy/zellij-utils.git
cd zellij-utils

# 2. Run the installer
chmod +x scripts/install.sh
./scripts/install.sh

# 3. Add to your shell configuration
echo 'source ~/.config/shell/zellij-utils.sh' >> ~/.bashrc
source ~/.bashrc
```

## Core Features

### Smart Session Attachment (`zj`)

The `zj` command intelligently creates or attaches to sessions:

- **In a git repository?** Uses the repo name
- **In a project directory?** Uses the directory name  
- **In special directories?** Uses contextual names (`home`, `config`, `docs`)

### Development Workflows

- `zjwork [name]` - Create development workspace with multiple panes
- `zjdev [name] [layout]` - Development session with specific layout
- `zjgit` - Session for current git repository

### Session Management

- `zjl` - List active sessions
- `zjk <name>` - Kill specific session
- `zjd [name]` - Interactive session deletion
- `zjs <name>` - Switch to session

## Example Use Case: Persistent & Mobile Workflows

Perfect for long-running processes like AI agents, development servers, or complex builds. Start a session on your desktop, disconnect, and seamlessly re-attach from anywhere via SSH.

[Get Started →](/guides/quick-start/)
[View Examples →](/guides/examples/)
[GitHub Repository →](https://github.com/tranqy/zellij-utils)