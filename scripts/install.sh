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
SHELL_CONFIG_DIR="$HOME/.config/shell"
ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

# Detect if running remotely (piped from curl) or locally
if [[ -n "${BASH_SOURCE[0]}" && -f "${BASH_SOURCE[0]}" ]]; then
    # Running locally
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    REMOTE_INSTALL=false
    print_info "Running local installation from $PROJECT_DIR"
else
    # Running remotely
    REMOTE_INSTALL=true
    TEMP_DIR="$(mktemp -d)"
    PROJECT_DIR="$TEMP_DIR/zellij-utils"
    GITHUB_RAW_URL="https://raw.githubusercontent.com/tranqy/zellij-utils/main"
    print_info "Running remote installation, downloading files..."
    
    # Cleanup function
    cleanup() {
        if [[ -d "$TEMP_DIR" ]]; then
            rm -rf "$TEMP_DIR"
        fi
    }
    trap cleanup EXIT
fi

print_info "Installing Zellij Utils..."

# Check if zellij is installed
if ! command -v zellij >/dev/null 2>&1; then
    print_error "Zellij is not installed. Please install zellij first:"
    echo "  Visit: https://zellij.dev/documentation/installation"
    echo "  Or run: cargo install --locked zellij"
    exit 1
fi

print_success "Zellij found: $(zellij --version)"

# Download files if running remotely
if [[ "$REMOTE_INSTALL" == true ]]; then
    print_info "Downloading zellij-utils files..."
    
    # Create temp project structure
    mkdir -p "$PROJECT_DIR/scripts"
    mkdir -p "$PROJECT_DIR/layouts"
    mkdir -p "$PROJECT_DIR/config-examples"
    mkdir -p "$PROJECT_DIR/config"
    
    # Download main script
    if ! curl -fsSL "$GITHUB_RAW_URL/scripts/zellij-utils.sh" -o "$PROJECT_DIR/scripts/zellij-utils.sh"; then
        print_error "Failed to download zellij-utils.sh"
        exit 1
    fi
    
    # Download zsh script if it exists
    curl -fsSL "$GITHUB_RAW_URL/scripts/zellij-utils-zsh.sh" -o "$PROJECT_DIR/scripts/zellij-utils-zsh.sh" 2>/dev/null || true
    
    # Download layouts
    for layout in dev.kdl simple.kdl; do
        if ! curl -fsSL "$GITHUB_RAW_URL/layouts/$layout" -o "$PROJECT_DIR/layouts/$layout"; then
            print_error "Failed to download layout: $layout"
            exit 1
        fi
    done
    
    # Download config examples
    if ! curl -fsSL "$GITHUB_RAW_URL/config-examples/config.kdl" -o "$PROJECT_DIR/config-examples/config.kdl"; then
        print_error "Failed to download config.kdl"
        exit 1
    fi
    
    # Download session naming config if it exists
    curl -fsSL "$GITHUB_RAW_URL/config/session-naming.conf" -o "$PROJECT_DIR/config/session-naming.conf" 2>/dev/null || true
    
    print_success "Files downloaded successfully"
fi

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

# Copy layouts with error handling
print_info "Installing layouts..."
if ! cp "$PROJECT_DIR/layouts/"* "$ZELLIJ_CONFIG_DIR/layouts/" 2>/dev/null; then
    print_error "Failed to install layouts"
    exit 1
fi
print_success "Layouts installed to $ZELLIJ_CONFIG_DIR/layouts/"

# Copy session naming configuration
print_info "Installing session naming configuration..."
if [[ -f "$PROJECT_DIR/config/session-naming.conf" ]]; then
    if ! cp "$PROJECT_DIR/config/session-naming.conf" "$ZELLIJ_CONFIG_DIR/"; then
        print_error "Failed to install session naming configuration"
        exit 1
    fi
    print_success "Session naming config installed to $ZELLIJ_CONFIG_DIR/session-naming.conf"
else
    print_info "Session naming config not found, skipping..."
fi

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