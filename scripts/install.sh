#!/bin/bash
# Zellij Utils Installation Script
# This script sets up zellij-utils on your system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SHELL_CONFIG_DIR="$HOME/.config/shell"
ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

print_info "Installing Zellij Utils..."

# Check if zellij is installed
if ! command -v zellij >/dev/null 2>&1; then
    print_error "Zellij is not installed. Please install zellij first:"
    echo "  Visit: https://zellij.dev/documentation/installation"
    echo "  Or run: cargo install --locked zellij"
    exit 1
fi

print_success "Zellij found: $(zellij --version)"

# Create directories
print_info "Creating configuration directories..."
mkdir -p "$SHELL_CONFIG_DIR"
mkdir -p "$ZELLIJ_CONFIG_DIR/layouts"
mkdir -p "$ZELLIJ_CONFIG_DIR/saved-sessions"

# Copy appropriate script based on shell
print_info "Installing zellij-utils script..."
SHELL_NAME=$(basename "$SHELL")
if [[ "$SHELL_NAME" == "zsh" ]]; then
    cp "$PROJECT_DIR/scripts/zellij-utils-zsh.sh" "$SHELL_CONFIG_DIR/zellij-utils.sh"
    print_success "Zsh-compatible script installed to $SHELL_CONFIG_DIR/zellij-utils.sh"
else
    cp "$PROJECT_DIR/scripts/zellij-utils.sh" "$SHELL_CONFIG_DIR/"
    print_success "Bash script installed to $SHELL_CONFIG_DIR/zellij-utils.sh"
fi
chmod +x "$SHELL_CONFIG_DIR/zellij-utils.sh"

# Copy layouts
print_info "Installing layouts..."
cp "$PROJECT_DIR/layouts/"* "$ZELLIJ_CONFIG_DIR/layouts/"
print_success "Layouts installed to $ZELLIJ_CONFIG_DIR/layouts/"

# Copy session naming configuration
print_info "Installing session naming configuration..."
cp "$PROJECT_DIR/config/session-naming.conf" "$ZELLIJ_CONFIG_DIR/"
print_success "Session naming config installed to $ZELLIJ_CONFIG_DIR/session-naming.conf"

# Copy config if it doesn't exist
if [[ ! -f "$ZELLIJ_CONFIG_DIR/config.kdl" ]]; then
    print_info "Installing default zellij config..."
    cp "$PROJECT_DIR/config-examples/config.kdl" "$ZELLIJ_CONFIG_DIR/"
    print_success "Config installed to $ZELLIJ_CONFIG_DIR/config.kdl"
else
    print_warning "Zellij config already exists, skipping..."
    print_info "Example config available at: $PROJECT_DIR/config-examples/config.kdl"
fi

# Detect shell and provide instructions
print_info "Detecting shell configuration..."

SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    bash)
        SHELL_RC="$HOME/.bashrc"
        ;;
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    fish)
        SHELL_RC="$HOME/.config/fish/config.fish"
        print_warning "Fish shell detected. Manual configuration required."
        ;;
    *)
        SHELL_RC="$HOME/.profile"
        print_warning "Unknown shell: $SHELL_NAME"
        ;;
esac

# Add to shell configuration
SOURCE_LINE="source $SHELL_CONFIG_DIR/zellij-utils.sh"

if [[ -f "$SHELL_RC" ]] && ! grep -q "zellij-utils.sh" "$SHELL_RC"; then
    print_info "Adding zellij-utils to $SHELL_RC..."
    echo "" >> "$SHELL_RC"
    echo "# Zellij utilities" >> "$SHELL_RC"
    echo "$SOURCE_LINE" >> "$SHELL_RC"
    print_success "Added to $SHELL_RC"
elif grep -q "zellij-utils.sh" "$SHELL_RC"; then
    print_warning "Already configured in $SHELL_RC"
else
    print_warning "Shell config file not found: $SHELL_RC"
    print_info "Please add this line to your shell configuration:"
    echo "  $SOURCE_LINE"
fi

print_info "Installation complete! 🎉"
echo ""
print_info "Next steps:"
echo "1. Restart your terminal or run: source $SHELL_RC"
echo "2. Try the 'zj' command to create your first session"
echo "3. Use 'zjl' to list sessions, 'zjk' to kill sessions"
echo ""
print_info "Available commands:"
echo "  zj [name] [layout] - Create/attach session"
echo "  zjl                - List sessions"
echo "  zjk <name>         - Kill session"
echo "  zjwork [name]      - Development workspace"
echo "  zjinfo             - Session info"
echo ""
print_info "For more help, check the README.md file"