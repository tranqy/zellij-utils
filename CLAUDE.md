# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Zellij utilities project that provides shell functions and configurations for enhanced terminal multiplexer workflows. It's a pure shell script collection with no compilation or build process required.

## Installation and Setup

The project uses an installation script to set up the utilities:

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

This copies files to appropriate system locations:
- `scripts/zellij-utils.sh` → `~/.config/shell/zellij-utils.sh`
- `layouts/*.kdl` → `~/.config/zellij/layouts/`
- `config-examples/config.kdl` → `~/.config/zellij/config.kdl` (if not exists)

## Core Architecture

### Main Components

**scripts/zellij-utils.sh** - The primary utility script containing:
- Session management functions (`zj`, `zjl`, `zjk`, `zjka`, `zjs`)
- Quick navigation helpers (`zjh`, `zjc`, `zjd`, `zjgit`, `zjdot`)
- Development workflow functions (`zjwork`, `zjdev`)
- Monitoring utilities (`zjinfo`, `zjstatus`)
- Auto-start configuration (`zj_auto`)

**layouts/** - Zellij layout definitions:
- `dev.kdl` - Development layout with editor, terminal, logs, server, and git tabs
- `simple.kdl` - Basic two-pane layout

**config-examples/** - Configuration templates:
- `config.kdl` - Example Zellij configuration with keybinds and themes
- `bashrc-additions.sh` - Shell configuration examples
- `vscode-settings.json` - VS Code integration settings

### Smart Session Naming Logic

The `zj` function automatically determines session names using this priority:
1. Git repository name (if in git repo)
2. Project detection (package.json, Cargo.toml, go.mod present)
3. Special directories:
   - `$HOME` → "home"
   - `$HOME/.config/*` → "config" 
   - `$HOME/Documents/*` → "docs"
4. Current directory basename as fallback

### Environment Variables

- `ZJ_NO_AUTO` - Disable auto-start in SSH sessions
- `ZJ_DISABLE_AUTO` - Completely disable auto-start
- `DOTFILES_DIR` - Custom dotfiles directory (default: `~/.dotfiles`)
- `EDITOR` - Editor for layouts (default: nvim)

## Development Workflow

Since this is a shell script collection, development involves:
1. Edit shell functions in `scripts/zellij-utils.sh`
2. Test manually by sourcing the script: `source scripts/zellij-utils.sh`
3. Modify layouts in `layouts/*.kdl` files
4. Test installation with `./scripts/install.sh`

## Key Functions Reference

**Session Management:**
- `zj [name] [layout]` - Create/attach to session with smart naming
- `zjl` - List active sessions
- `zjk <name>` - Kill specific session
- `zjs <name>` - Switch to session

**Development:**
- `zjwork [name]` - Create development workspace with multiple panes
- `zjdev [name] [layout]` - Development session with specific layout
- `zjgit` - Session for current git repository

**Navigation:**
- `zjh` - Home directory session
- `zjc` - Config directory session  
- `zjdot` - Dotfiles management session
- `zjf` - Fuzzy session selection (requires fzf)

The project has no build system, tests, or linting - it's pure shell scripting focused on Zellij terminal multiplexer enhancement.