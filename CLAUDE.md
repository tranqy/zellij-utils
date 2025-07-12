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
- Session management functions (`zj`, `zjl`, `zjk`, `zjd`, `zjka`, `zjs`)
- Quick navigation helpers (`zjgit`)
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
5. **IMPORTANT**: Commit changes after completing each task or significant feature

### Git Commit Guidelines

**ALWAYS commit changes after completing tasks.** Use descriptive commit messages that explain:
- What functionality was added/changed
- Why the changes were made
- Any breaking changes or important notes

Example commit workflow:
```bash
git add .
git commit -m "feat: add interactive session deletion with zjd function

- Implement zjd function with force, pattern, and all flags
- Add safety confirmations and current session protection
- Include fzf integration for interactive selection
- Update tests and documentation"
```

**Commit after every completed task** to maintain clear development history and enable easy rollbacks if needed.

## Key Functions Reference

**Session Management:**
- `zj [name] [layout]` - Create/attach to session with smart naming
- `zjl` - List active sessions
- `zjk <name>` - Kill specific session
- `zjd [name] [--force] [--pattern] [--all]` - Delete session with interactive selection
- `zjs <name>` - Switch to session

**Development:**
- `zjwork [name]` - Create development workspace with multiple panes
- `zjdev [name] [layout]` - Development session with specific layout

**Navigation:**
- `zjgit` - Session for current git repository
- `zjf` - Fuzzy session selection (requires fzf)

## Testing

The project includes a modern hybrid testing system with both local Docker isolation and fast native CI:

### Hybrid Testing Architecture

The testing system provides **two complementary approaches**:

1. **Local Docker Testing** - Complete isolation for development
2. **Native CI Testing** - Fast, reliable GitHub Actions

### Test Structure

- **tests/shared/** - Environment-agnostic test logic
- **tests/utils/** - Common test framework and utilities  
- **tests/local/** - Docker-specific setup and cleanup
- **tests/ci/** - GitHub Actions and native environment setup
- **tests/run-tests.sh** - Universal test runner (auto-detects environment)

### Local Development Testing (Docker)

**Recommended for local development** - provides complete isolation from your running zellij sessions:

```bash
# Quick start - run main tests in Docker
./scripts/test-local.sh

# Run specific test types
./scripts/test-local.sh -t alpine         # Alpine Linux tests
./scripts/test-local.sh -t both           # Both Ubuntu and Alpine

# Development workflow
./scripts/test-local.sh --build           # Force rebuild containers
./scripts/test-local.sh --shell           # Interactive debugging shell
./scripts/test-local.sh --verbose         # Detailed output

# No cleanup (for debugging)
./scripts/test-local.sh --no-cleanup
```

### Native Testing (CI and Local)

**Used by GitHub Actions** - fast execution without Docker overhead:

```bash
# Run tests natively (detects environment automatically)
./tests/run-tests.sh                      # Full test suite
./tests/run-tests.sh --quick              # Quick validation only
./tests/run-tests.sh --verbose            # Detailed output

# Force specific environment
./tests/run-tests.sh --env native         # Local native testing
./tests/run-tests.sh --env github-actions # GitHub Actions mode
```

### Key Benefits

**Local Docker Testing:**
- ✅ **Complete Session Isolation** - Zero interference with your running zellij sessions
- ✅ **Multi-Environment Testing** - Ubuntu and Alpine Linux containers
- ✅ **Debugging Friendly** - Interactive shells and persistent containers
- ✅ **Reproducible** - Identical environment every time

**Native CI Testing:**  
- ⚡ **5x Faster** - No Docker build/startup overhead
- 🔒 **Zero Hanging** - No container process management issues
- 📊 **Clear Reporting** - Detailed test results and GitHub integration
- 🎯 **Multi-Shell** - Tests both bash and zsh compatibility

### GitHub Actions Integration

The project now uses **Native CI** for fast, reliable automated testing:

- **Lint and Validation** - Shell syntax and style checking
- **Quick Tests** - Fast validation and core functionality
- **Full Test Suite** - Comprehensive testing across bash/zsh
- **Security Scanning** - Input validation and security checks
- **Compatibility Testing** - Installation and integration workflow

### Environment Variables

- `ZJ_TEST_MODE=1` - Enable test mode (disables production features)
- `ZJ_DISABLE_AUTO=1` - Disable auto-start during testing
- `TEST_VERBOSE=true` - Enable detailed test output
- `TEST_OUTPUT_DIR` - Custom test results directory
- `ZELLIJ_CONFIG_DIR` - Custom config directory for isolation

### Migration from Old Testing

The new system **replaces** the previous Docker-only CI while **preserving** local Docker testing:

- ✅ **Local Development**: Use `./scripts/test-local.sh` (Docker isolation)  
- ✅ **CI/CD**: Uses native GitHub Actions (fast, reliable)
- ✅ **Shared Logic**: Same test scripts work in both environments
- ✅ **Better Debugging**: Interactive shells and clear error reporting

The project has no build system or linting - it's pure shell scripting focused on Zellij terminal multiplexer enhancement.