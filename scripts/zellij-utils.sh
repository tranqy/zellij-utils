#!/bin/bash
# Zellij Utilities
# Source this file in your bashrc: source ~/path/to/zellij-utils.sh

# =============================================================================
# SESSION MANAGEMENT
# =============================================================================

# Load session naming configuration
_load_session_config() {
    local config_file="$HOME/.config/zellij/session-naming.conf"
    
    # Default values
    PROJECT_MARKERS=("package.json" "Cargo.toml" "go.mod" ".git" "pyproject.toml" "composer.json" "Makefile" "CMakeLists.txt")
    SPECIAL_DIRS=("/:root" "$HOME:home" "$HOME/.config/*:config" "$HOME/Documents/*:docs")
    USE_GIT_REPO_NAME=true
    DEFAULT_SESSION_NAME="default"
    LOWERCASE_NAMES=true
    SANITIZE_NAMES=true
    
    # Load config if it exists
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
}

# Enhanced session creation/attachment with smart naming
zj() {
    local session_name="$1"
    local layout="$2"
    
    if [[ -z "$session_name" ]]; then
        _load_session_config
        
        # Check for project markers first
        local has_project_marker=false
        for marker in "${PROJECT_MARKERS[@]}"; do
            if [[ -f "$marker" ]] || [[ -d "$marker" ]]; then
                has_project_marker=true
                break
            fi
        done
        
        if [[ "$has_project_marker" == true ]]; then
            # Use git repo name if available and enabled
            if [[ "$USE_GIT_REPO_NAME" == true ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                session_name=$(basename "$(git rev-parse --show-toplevel)")
            else
                session_name=$(basename "$PWD")
            fi
        else
            # Check special directories
            local matched=false
            for dir_mapping in "${SPECIAL_DIRS[@]}"; do
                local pattern="${dir_mapping%:*}"
                local name="${dir_mapping#*:}"
                
                # Expand variables in pattern
                pattern=$(eval echo "$pattern")
                
                if [[ "$PWD" == $pattern ]]; then
                    session_name="$name"
                    matched=true
                    break
                fi
            done
            
            # Default to directory basename
            if [[ "$matched" == false ]]; then
                session_name=$(basename "$PWD")
            fi
        fi
    fi
    
    # Apply transformations
    if [[ "$SANITIZE_NAMES" == true ]]; then
        session_name=$(echo "$session_name" | tr -cd '[:alnum:]_-')
    fi
    
    if [[ "$LOWERCASE_NAMES" == true ]]; then
        session_name=$(echo "$session_name" | tr '[:upper:]' '[:lower:]')
    fi
    
    [[ -z "$session_name" ]] && session_name="$DEFAULT_SESSION_NAME"
    
    if zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$session_name\b"; then
        echo "📎 Attaching to existing session: $session_name"
        zellij attach "$session_name"
    else
        echo "✨ Creating new session: $session_name"
        zellij --session "$session_name" ${layout:+--layout "$layout"}
    fi
}

# List all sessions with status
zjl() {
    echo "📋 Active zellij sessions:"
    if ! zellij list-sessions 2>/dev/null; then
        echo "   No active sessions"
    fi
}

# Kill a specific session
zjk() {
    local session_name="$1"
    if [[ -z "$session_name" ]]; then
        echo "Usage: zjk <session_name>"
        echo "Available sessions:"
        zjl
        return 1
    fi
    
    echo "🗑️  Killing session: $session_name"
    zellij kill-session "$session_name"
}

# Kill all sessions except current
zjka() {
    local current_session="${ZELLIJ_SESSION_NAME:-}"
    local sessions=$(zellij list-sessions 2>/dev/null | grep -v "^$current_session$")
    
    if [[ -z "$sessions" ]]; then
        echo "No other sessions to kill"
        return 0
    fi
    
    echo "🗑️  Killing all sessions except: $current_session"
    echo "$sessions" | while read -r session; do
        [[ -n "$session" ]] && zellij kill-session "$session"
    done
}

# Switch to another session (detach from current, attach to new)
zjs() {
    local session_name="$1"
    if [[ -z "$session_name" ]]; then
        echo "Available sessions:"
        zjl
        echo ""
        echo "Usage: zjs <session_name>"
        return 1
    fi
    
    if zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$session_name\b"; then
        echo "🔄 Switching to session: $session_name"
        zellij attach "$session_name"
    else
        echo "❌ Session '$session_name' not found"
        zjl
    fi
}

# =============================================================================
# SESSION CREATION
# =============================================================================

# Create session with specific layout for development
zjdev() {
    local project_name="${1:-dev}"
    local layout="${2:-dev}"
    zj "$project_name" "$layout"
}

# =============================================================================
# WORKSPACE MANAGEMENT
# =============================================================================

# Save current session layout (requires custom script)
zjsave() {
    local session_name="${ZELLIJ_SESSION_NAME:-$(basename "$PWD")}"
    local save_file="$HOME/.config/zellij/saved-sessions/$session_name.json"
    
    mkdir -p "$(dirname "$save_file")"
    echo "💾 Saving session layout: $session_name"
    # This would need a custom script to export current layout
    echo "Session: $session_name" > "$save_file"
    echo "Directory: $PWD" >> "$save_file"
    echo "Date: $(date)" >> "$save_file"
}

# List saved sessions
zjsaved() {
    local saved_dir="$HOME/.config/zellij/saved-sessions"
    if [[ -d "$saved_dir" ]] && [[ -n "$(ls -A "$saved_dir" 2>/dev/null)" ]]; then
        echo "💾 Saved sessions:"
        ls -1 "$saved_dir" | sed 's/\.json$//' | sed 's/^/   /'
    else
        echo "No saved sessions found"
    fi
}

# =============================================================================
# DEVELOPMENT WORKFLOWS
# =============================================================================

# Start a development session with common layout
zjwork() {
    local project_name="${1:-$(basename "$PWD")}"
    
    # Create session if it doesn't exist
    if ! zellij list-sessions 2>/dev/null | grep -q "^$project_name"; then
        echo "🚀 Setting up development workspace: $project_name"
        zj "$project_name"
        
        # Add new panes and tabs (you can customize this)
        sleep 1
        zellij action new-pane --direction down
        zellij action new-tab --name "editor"
        zellij action new-tab --name "server"
        zellij action go-to-tab 1
    else
        echo "📎 Attaching to existing workspace: $project_name"
        zj "$project_name"
    fi
}


# =============================================================================
# MONITORING & UTILITIES
# =============================================================================

# Show current session info
zjinfo() {
    if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
        echo "🎯 Current session: $ZELLIJ_SESSION_NAME"
        echo "📁 Working directory: $PWD"
        echo "🪟 Zellij version: $(zellij --version 2>/dev/null || echo 'Unknown')"
    else
        echo "❌ Not in a zellij session"
    fi
}

# Quick session status overview
zjstatus() {
    echo "📊 Zellij Status Overview"
    echo "========================"
    
    if [[ -n "$ZELLIJ_SESSION_NAME" ]]; then
        echo "Current session: $ZELLIJ_SESSION_NAME"
    else
        echo "Current session: None (not in zellij)"
    fi
    
    echo ""
    echo "All sessions:"
    zjl
    
    echo ""
    echo "System info:"
    echo "  Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2}' || echo 'N/A')"
    echo "  Uptime: $(uptime | awk '{print $3}' | sed 's/,//' || echo 'N/A')"
}

# Clean up dead sessions (if any)
zjclean() {
    echo "🧹 Cleaning up dead zellij sessions..."
    # This is more complex and might need custom implementation
    # For now, just show what sessions exist
    zjl
}

# =============================================================================
# INTEGRATION HELPERS
# =============================================================================

# Create session and run command
zjrun() {
    local session_name="$1"
    shift
    local command="$*"
    
    if [[ -z "$session_name" ]] || [[ -z "$command" ]]; then
        echo "Usage: zjrun <session_name> <command>"
        return 1
    fi
    
    echo "🚀 Running '$command' in session: $session_name"
    zj "$session_name"
    # Note: You'd need to use zellij action to send the command
}

# Fuzzy find and attach to session (requires fzf)
zjf() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "❌ fzf not found. Install fzf for fuzzy session selection."
        zjl
        return 1
    fi
    
    local session=$(zellij list-sessions 2>/dev/null | fzf --prompt="Select session: " --height=10)
    if [[ -n "$session" ]]; then
        zj "$session"
    fi
}

# =============================================================================
# AUTO-START CONFIGURATION
# =============================================================================

# Auto-start function (call this from your bashrc)
zj_auto() {
    # Only auto-start in interactive shells and not already in zellij
    if [[ -z "$ZELLIJ" && $- == *i* ]]; then
        # Don't auto-start if we're in a SSH session and ZJ_NO_AUTO is set
        if [[ -n "$SSH_CONNECTION" ]] && [[ -n "$ZJ_NO_AUTO" ]]; then
            return 0
        fi
        
        # Don't auto-start if explicitly disabled
        if [[ -n "$ZJ_DISABLE_AUTO" ]]; then
            return 0
        fi
        
        zj
    fi
}

# =============================================================================
# ALIASES AND SHORTCUTS
# =============================================================================

# Short aliases
alias zls='zjl'
alias zkill='zjk'
alias zswitch='zjs'
alias zinfo='zjinfo'


# =============================================================================
# COMPLETION (optional)
# =============================================================================

# Basic completion for session names
_zellij_sessions() {
    local sessions=$(zellij list-sessions 2>/dev/null)
    COMPREPLY=($(compgen -W "$sessions" -- "${COMP_WORDS[COMP_CWORD]}"))
}

# Register completions
complete -F _zellij_sessions zjs zjk

# =============================================================================
# INITIALIZATION
# =============================================================================

# Call auto-start (comment out if you don't want auto-start)
zj_auto

echo "🚀 Zellij utilities loaded! Use 'zj' to start/attach sessions."