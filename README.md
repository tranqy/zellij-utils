# Zellij Utils

A collection of powerful, configuration-driven shell utilities to streamline your [Zellij](https://github.com/zellij-org/zellij) workflows.

**Why use Zellij Utils?**

-   **Smart Session Management**: Automatically name sessions based on your current project, git repository, or directory. No more `zellij attach` followed by hunting for the right session.
-   **Persistent & Remote Workflows**: Keep your sessions alive on a remote machine, allowing you to disconnect and reconnect from anywhere without interrupting your work. Perfect for long-running tasks, AI agent pairs, and development servers.
-   **Effortless Workspaces**: Jump directly into pre-defined development layouts (`editor`, `git`, `logs`, etc.) with a single command.
-   **Safety and Control**: Interactively delete sessions with confirmations, preventing accidental data loss.
-   **Highly Configurable**: Customize everything from session naming conventions to auto-start behavior.

Stop thinking about managing your multiplexer and start focusing on your work.

### 💡 Example Use Case: Persistent & Mobile Workflows

Are you working with long-running processes like AI agents, development servers, or complex builds? Zellij Utils helps you maintain persistent sessions that you can access from anywhere.

Imagine you start an "agentic pair" chat session from your desktop IDE. With Zellij and these utilities, that session lives on your machine (or a remote server) independently of your IDE. You can close your laptop, head out, and then seamlessly re-attach to the exact same session from your phone or another computer via SSH. Your agents, chats, and processes will be exactly as you left them.

This workflow is ideal for:
-   **AI and Agent Development**: Keep your models running and chats active 24/7.
-   **Remote Development**: Start a build on your work machine and check its progress from home.
-   **Mobile Productivity**: Quickly access your terminal sessions on the go to issue commands or check logs.

## 🚀 Installation

### Quick Install (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tranqy/zellij-utils/main/scripts/install.sh)
```

### Manual Install

```bash
# 1. Clone the repository
git clone https://github.com/tranqy/zellij-utils.git
cd zellij-utils

# 2. Run the installer
chmod +x scripts/install.sh
./scripts/install.sh
```

The installer automatically:
- Downloads and installs all necessary files
- Sets up shell integration for bash/zsh
- Copies layouts and configurations
- Does not overwrite existing configurations without permission

After installation, restart your terminal or run `source ~/.bashrc` (or `~/.zshrc` for zsh).

## ✨ Core Features

### Smart Session Attachment (`zj`)

The `zj` command is the heart of Zellij Utils. It intelligently creates or attaches to a session with a sensible name, so you don't have to.

-   **In a git repository?** It uses the repo name (`my-project`).
-   **In a project directory?** It uses the directory name (`api-server`).
-   **In directories with dots?** It converts them to hyphens (`test.example.com` → `test-example-com`).
-   **In your home directory?** It names the session `home`.

```bash
# Navigate to your project and start a session
cd ~/work/my-cool-project
zj # Attaches to or creates a session named "my-cool-project"

# Create a session with a custom name
zj my-session

# Create a session with a specific layout
zj my-session dev
```

### Development Layouts (`zjdev`)

Instantly create a development workspace with a pre-defined layout.

```bash
# Start a dev session for the current project
zjdev # Creates a session with editor, terminal, and git panes

# Specify a project name and layout
zjdev my-api dev
```

### Session Management

-   `zjl`: List all active Zellij sessions.
-   `zjk <name>`: Kill a session by name.
-   `zjd`: Interactively delete sessions using `fzf` (if installed).
-   `zjd <name>`: Delete a specific session with a confirmation prompt.
-   `zjd --all`: Delete all sessions except the one you're in.
-   `zjs <name>`: Switch to a running session.

## 🔧 Configuration

Zellij Utils is designed to be highly configurable. After running the installer, you can modify the configuration files located in `~/.config/zellij-utils/`.

-   `zellij-utils.conf`: Controls core behavior like auto-starting, session name sanitization, and caching.
-   `session-naming.conf`: Defines the rules for how smart session naming works, including project markers (e.g., `package.json`) and custom directory mappings.

For detailed configuration options, see the comments within the generated configuration files.

## 🔬 Quality & Testing

Zellij Utils is thoroughly tested and production-ready:

- **🚀 Automated CI/CD**: GitHub Actions with containerized testing in Ubuntu and Alpine Linux
- **🛡️ Security Testing**: Input validation, injection prevention, and dependency safety checks  
- **🔧 Integration Testing**: Complete installation and functionality validation
- **🌐 Compatibility Testing**: Multi-shell (Bash/Zsh) and cross-platform support
- **📊 Performance Testing**: Caching optimization and scalability validation

All tests run in isolated Docker containers to ensure consistency and prevent interference with your local environment.

## 🛠 For Developers

Interested in contributing or understanding the technical details? Please see the [**Local Development and Testing Guide**](DEVELOPMENT.md).

## 📢 Marketing & Community

This project includes comprehensive marketing materials and community engagement strategy. See the [**marketing/**](marketing/) directory for:

- Ready-to-publish blog posts and articles
- Community-specific post templates 
- Launch strategy and success metrics
- Community engagement guidelines

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
