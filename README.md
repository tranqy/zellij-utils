# Zellij Utils

A comprehensive collection of utilities and configurations for [Zellij](https://zellij.dev/), the terminal multiplexer. This toolkit provides smart session management, auto-attach functionality, development workflows, and seamless integration with VS Code and other tools.

## ✨ Features

- **Smart Session Management**: Auto-create sessions based on directory names, git repositories, or custom names
- **Home Directory Support**: Automatically creates/joins a "home" session when in your home directory
- **Project Detection**: Recognizes git repositories, Node.js projects, Rust projects, and Go modules
- **VS Code Integration**: Seamlessly work with Zellij inside VS Code terminals
- **Development Workflows**: Pre-configured layouts and workspace setups
- **Fuzzy Finding**: Optional fzf integration for session selection
- **Auto-attach**: Automatically attach to sessions when opening terminals

## 📋 Prerequisites

- [Zellij](https://zellij.dev/) (latest version recommended)
- Bash or Zsh shell
- Optional: [fzf](https://github.com/junegunn/fzf) for fuzzy session selection
- Optional: [Neovim](https://neovim.io/) for the development layout

## 🚀 Quick Start

### Automatic Installation

```bash
# Clone or download this repository
git clone <repository-url> ~/projects/zellij-utils
cd ~/projects/zellij-utils

# Run the installation script
chmod +x scripts/install.sh
./scripts/install.sh

# Restart your terminal or reload your shell config
source ~/.bashrc  # or ~/.zshrc
```

### Manual Installation

1. **Copy the main script**:
   ```bash
   mkdir -p ~/.config/shell
   cp scripts/zellij-utils.sh ~/.config/shell/
   chmod +x ~/.config/shell/zellij-utils.sh
   ```

2. **Add to your shell configuration** (`~/.bashrc` or `~/.zshrc`):
   ```bash
   # Zellij utilities
   source ~/.config/shell/zellij-utils.sh
   ```

3. **Copy layouts**:
   ```bash
   mkdir -p ~/.config/zellij/layouts
   cp layouts/* ~/.config/zellij/layouts/
   ```

4. **Optional: Copy example config**:
   ```bash
   cp config-examples/config.kdl ~/.config/zellij/
   ```

## 📖 Usage

### Basic Commands

| Command | Description |
|---------|-------------|
| `zj` | Create/attach to session based on current directory |
| `zj <name>` | Create/attach to named session |
| `zj <name> <layout>` | Create session with specific layout |
| `zjl` | List all active sessions |
| `zjk <name>` | Kill specific session |
| `zjs <name>` | Switch to another session |
| `zjinfo` | Show current session information |

### Quick Navigation

| Command | Description |
|---------|-------------|
| `zjh` | Go to home directory and start "home" session |
| `zjc` | Go to ~/.config and start "config" session |
| `zjd` | Go to ~/Documents and start "docs" session |
| `zjgit` | Attach to session for current git repository |
| `zjdot` | Go to dotfiles directory and start "dotfiles" session |

### Development Workflows

| Command | Description |
|---------|-------------|
| `zjwork [name]` | Start development workspace with multiple panes |
| `zjdev [name] [layout]` | Start development session with specific layout |
| `zjf` | Fuzzy find and switch sessions (requires fzf) |

### Session Management

| Command | Description |
|---------|-------------|
| `zjka` | Kill all sessions except current |
| `zjstatus` | Show comprehensive status overview |
| `zjsave` | Save current session layout |
| `zjsaved` | List saved session configurations |

## 🎯 Smart Session Naming

The `zj` command automatically determines session names based on:

1. **Git repositories**: Uses the repository name
2. **Project directories**: Detects package.json, Cargo.toml, go.mod
3. **Home directory**: Creates "home" session
4. **Special directories**: 
   - `~/.config/*` → "config" session
   - `~/Documents/*` → "docs" session
5. **Fallback**: Uses current directory name

## 📁 Directory Structure

```
zellij-utils/
├── scripts/
│   ├── zellij-utils.sh     # Main utility functions
│   └── install.sh          # Installation script
├── layouts/
│   ├── dev.kdl            # Development layout with editor, terminal, logs
│   └── simple.kdl         # Simple two-pane layout
├── config-examples/
│   ├── config.kdl         # Example zellij configuration
│   ├── bashrc-additions.sh # Shell configuration examples
│   └── vscode-settings.json # VS Code integration settings
└── README.md              # This file
```

## ⚙️ Configuration

### Environment Variables

Add these to your shell configuration for customization:

```bash
# Disable auto-start in SSH sessions
export ZJ_NO_AUTO=1

# Set dotfiles directory for zjdot command
export DOTFILES_DIR="$HOME/.dotfiles"

# Disable auto-start completely
export ZJ_DISABLE_AUTO=1

# Set default editor for layouts
export EDITOR="nvim"  # or "code --wait"
```

### VS Code Integration

To integrate with VS Code, add the settings from `config-examples/vscode-settings.json` to your VS Code settings.json file. This will:

- Automatically start zellij when opening VS Code terminals
- Create separate profiles for zellij and regular terminals
- Optimize terminal experience for zellij

### Custom Layouts

Create custom layouts in `~/.config/zellij/layouts/`. Examples are provided in the `layouts/` directory. Use them with:

```bash
zj my-project my-custom-layout
```

## 🔧 Advanced Usage

### Project-Specific Sessions

For projects, `zj` will automatically:
- Use git repository name if in a git repo
- Detect project types (Node.js, Rust, Go) and use directory name
- Remember sessions even after closing terminals

### Fuzzy Session Selection

With fzf installed, use `zjf` for interactive session selection:

```bash
# Install fzf first
sudo apt install fzf  # Ubuntu/Debian
brew install fzf      # macOS

# Then use fuzzy selection
zjf
```

### Development Workspace

The `zjwork` command creates a development environment with:
- Main terminal tab
- Editor tab
- Server tab
- Additional panes for logs and git status

### Integration with Other Tools

#### tmux Migration
If you're coming from tmux, there's an alias for familiarity:
```bash
alias mux='zjwork'  # Use like tmuxinator
```

#### direnv Integration
Add to your `.envrc` files:
```bash
layout zellij session-name
```

## 🔍 Troubleshooting

### Common Issues

1. **"zj: command not found"**
   - Ensure you've sourced the script in your shell config
   - Restart your terminal or run `source ~/.bashrc`

2. **Auto-start not working**
   - Check that you're in an interactive shell
   - Verify `ZJ_DISABLE_AUTO` is not set
   - Make sure you're not already in a zellij session

3. **Sessions not persisting**
   - Zellij sessions persist until explicitly killed
   - Use `zjl` to see active sessions
   - Sessions survive terminal and VS Code restarts

4. **Layout not found**
   - Ensure layouts are in `~/.config/zellij/layouts/`
   - Check layout file syntax with `zellij setup --check`

### Debug Mode

For troubleshooting, you can enable debug output:

```bash
# Add to your session for debugging
export ZELLIJ_DEBUG=1
zj debug-session
```

## 🤝 Contributing

Contributions are welcome! Here are some ways to help:

- Add new utility functions
- Create additional layouts
- Improve documentation
- Add integration with other tools
- Report bugs or suggest features

## 📄 License

This project is open source. Feel free to use, modify, and distribute as needed.

## 🔗 Related Links

- [Zellij Documentation](https://zellij.dev/documentation/)
- [Zellij GitHub Repository](https://github.com/zellij-org/zellij)
- [KDL Language (for layouts)](https://kdl.dev/)

## 📝 Changelog

### v1.0.0
- Initial release with core functionality
- Smart session management
- VS Code integration
- Development layouts
- Auto-attach functionality

---

Happy multiplexing! 🚀