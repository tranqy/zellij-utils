# Zellij Environment Setup
# Add these lines to your ~/.bashrc or ~/.zshrc

# Zellij configuration environment variables
export ZJ_NO_AUTO=1                    # Disable auto-start in SSH sessions
export DOTFILES_DIR="$HOME/.dotfiles"  # For zjdot function
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

# Optional: Set default editor for zellij
export EDITOR="nvim"  # or "code --wait" for VS Code

# Source zellij utilities
# Update this path to where you placed the zellij-utils.sh file
source "$HOME/.config/shell/zellij-utils.sh"

# Optional: Additional aliases
alias mux='zjwork'  # Migration alias for tmuxinator users
alias dev='zjdev'   # Quick development session

# Optional: fzf integration for better session selection
# Requires fzf to be installed
if command -v fzf >/dev/null 2>&1; then
    # Enhanced session switcher with preview
    zj_fzf() {
        local session=$(zellij list-sessions 2>/dev/null | fzf \
            --prompt="Select zellij session: " \
            --height=40% \
            --border \
            --preview="echo 'Session: {}'" \
            --preview-window=up:3:hidden:wrap \
            --bind="?:toggle-preview")
        
        if [[ -n "$session" ]]; then
            zj "$session"
        fi
    }
    
    alias zf='zj_fzf'
fi

# Optional: Git integration
# Auto-create sessions for git repositories
git_session() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local repo_name=$(basename "$(git rev-parse --show-toplevel)")
        zj "$repo_name"
    else
        echo "Not in a git repository"
    fi
}

alias gs='git_session'  # Quick git session