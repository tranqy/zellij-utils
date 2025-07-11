#!/bin/bash
# Zellij Utilities
# Source this file in your bashrc: source ~/path/to/zellij-utils.sh

# =============================================================================
# CACHING SYSTEM
# =============================================================================

# Cache variables for performance optimization
declare -A _ZJ_GIT_CACHE=()
declare -A _ZJ_SESSION_CACHE=()
_ZJ_CACHE_TTL=60  # Cache TTL in seconds

# Clear expired cache entries
_zj_clear_expired_cache() {
    local current_time=$(date +%s)
    local cache_key
    
    # Clear git cache
    for cache_key in "${!_ZJ_GIT_CACHE[@]}"; do
        local cache_data="${_ZJ_GIT_CACHE[$cache_key]}"
        local cache_time="${cache_data##*:}"
        if [[ $((current_time - cache_time)) -gt $_ZJ_CACHE_TTL ]]; then
            unset _ZJ_GIT_CACHE["$cache_key"]
        fi
    done
    
    # Clear session cache
    for cache_key in "${!_ZJ_SESSION_CACHE[@]}"; do
        local cache_time="${_ZJ_SESSION_CACHE[$cache_key]##*:}"
        if [[ $((current_time - cache_time)) -gt $_ZJ_CACHE_TTL ]]; then
            unset _ZJ_SESSION_CACHE["$cache_key"]
        fi
    done
}

# Get cached git repo info or compute and cache it
_zj_get_git_info() {
    local pwd_key="$PWD"
    local current_time=$(date +%s)
    
    # Check cache first
    if [[ -n "${_ZJ_GIT_CACHE[$pwd_key]}" ]]; then
        local cache_data="${_ZJ_GIT_CACHE[$pwd_key]}"
        local cache_time="${cache_data##*:}"
        
        if [[ $((current_time - cache_time)) -le $_ZJ_CACHE_TTL ]]; then
            # Cache hit - return cached result
            echo "${cache_data%:*}"
            return 0
        fi
    fi
    
    # Cache miss - compute git info
    local git_result=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local repo_root
        if repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
            git_result="$(basename "$repo_root")"
        fi
    fi
    
    # Cache the result
    _ZJ_GIT_CACHE["$pwd_key"]="$git_result:$current_time"
    echo "$git_result"
}

# Get cached session list or fetch and cache it
_zj_get_session_list() {
    local current_time=$(date +%s)
    local cache_key="sessions"
    
    # Check cache first
    if [[ -n "${_ZJ_SESSION_CACHE[$cache_key]}" ]]; then
        local cache_data="${_ZJ_SESSION_CACHE[$cache_key]}"
        local cache_time="${cache_data##*:}"
        
        if [[ $((current_time - cache_time)) -le $_ZJ_CACHE_TTL ]]; then
            # Cache hit - return cached result
            echo "${cache_data%:*}"
            return 0
        fi
    fi
    
    # Cache miss - fetch session list
    local session_list=""
    if session_list=$(zellij list-sessions 2>/dev/null); then
        # Cache the result
        _ZJ_SESSION_CACHE["$cache_key"]="$session_list:$current_time"  
        echo "$session_list"
    else
        return 1
    fi
}

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
    local session_name="${1:-}"
    local layout="${2:-}"
    local provided_empty=false
    
    # Check if session name was explicitly provided as empty
    if [[ $# -gt 0 && -z "$session_name" ]]; then
        provided_empty=true
        echo "Error: Session name cannot be empty" >&2
        return 1
    fi
    
    # Validate user-provided session name immediately
    if [[ -n "$session_name" ]]; then
        # Check for dangerous characters
        if [[ "$session_name" =~ [\$\`\;\|\&\(\)\<\>\'\"] ]]; then
            echo "Error: Session name contains invalid characters" >&2
            return 1
        fi
        
        # Check length
        if [[ ${#session_name} -gt 50 ]]; then
            echo "Error: Session name too long" >&2
            return 1
        fi
    fi
    
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
            if [[ "$USE_GIT_REPO_NAME" == true ]]; then
                local git_repo_name
                git_repo_name=$(_zj_get_git_info)
                if [[ -n "$git_repo_name" ]]; then
                    session_name="$git_repo_name"
                else
                    session_name=$(basename "$PWD")
                fi
            else
                session_name=$(basename "$PWD")
            fi
        else
            # Check special directories
            local matched=false
            for dir_mapping in "${SPECIAL_DIRS[@]}"; do
                local pattern="${dir_mapping%:*}"
                local name="${dir_mapping#*:}"
                
                # Safely expand variables in pattern
                # Only expand $HOME and $USER variables to prevent injection
                pattern="${pattern//\$HOME/$HOME}"
                pattern="${pattern//\$USER/$USER}"
                
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
    
    # Validate and sanitize session name
    if [[ "$provided_empty" == true ]]; then
        echo "Error: Session name cannot be empty" >&2
        return 1
    fi
    
    if [[ -z "$session_name" ]]; then
        echo "Error: Failed to generate session name" >&2
        return 1
    fi
    
    # Check for dangerous characters (improved pattern)
    if [[ "$session_name" =~ [\$\`\;\|\&\(\)\<\>\'\"] ]]; then
        echo "Error: Session name contains invalid characters" >&2
        return 1
    fi
    
    # Apply transformations
    if [[ "${SANITIZE_NAMES:-false}" == true ]]; then
        # Replace dots with hyphens to preserve meaningful names and prevent collisions
        session_name=$(echo "$session_name" | tr '.' '-' | tr -cd '[:alnum:]_-')
    fi
    
    if [[ "${LOWERCASE_NAMES:-false}" == true ]]; then
        session_name=$(echo "$session_name" | tr '[:upper:]' '[:lower:]')
    fi
    
    # Final length check
    if [[ ${#session_name} -gt 50 ]]; then
        echo "Error: Session name too long" >&2
        return 1
    fi
    
    [[ -z "$session_name" ]] && session_name="$DEFAULT_SESSION_NAME"
    
    # Check if zellij is available
    if ! command -v zellij >/dev/null 2>&1; then
        echo "Error: zellij is not installed or not in PATH" >&2
        return 1
    fi
    
    # Clear expired cache entries
    _zj_clear_expired_cache
    
    # Check if session exists
    local session_list
    if ! session_list=$(_zj_get_session_list); then
        echo "Error: Failed to list zellij sessions" >&2
        return 1
    fi
    
    if echo "$session_list" | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$session_name\b"; then
        echo "📎 Attaching to existing session: $session_name"
        if ! zellij attach "$session_name"; then
            echo "Error: Failed to attach to session '$session_name'" >&2
            return 1
        fi
    else
        echo "✨ Creating new session: $session_name"
        if ! zellij --session "$session_name" ${layout:+--layout "$layout"}; then
            echo "Error: Failed to create session '$session_name'" >&2
            return 1
        fi
    fi
}

# List all sessions with status
zjl() {
    echo "📋 Active zellij sessions:"
    _zj_clear_expired_cache
    local session_list
    if session_list=$(_zj_get_session_list); then
        echo "$session_list"
    else
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

# Delete session with interactive selection and safety checks
zjd() {
    local session_name=""
    local force_flag=false
    local pattern_mode=false
    local all_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                force_flag=true
                shift
                ;;
            --pattern|-p)
                pattern_mode=true
                shift
                ;;
            --all|-a)
                all_mode=true
                shift
                ;;
            -*)
                echo "❌ Unknown option: $1" >&2
                echo "Usage: zjd [session_name] [--force] [--pattern] [--all]" >&2
                return 1
                ;;
            *)
                if [[ -z "$session_name" ]]; then
                    session_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Handle empty session name case first
    if [[ -n "$session_name" && -z "${session_name// /}" ]]; then
        echo "No sessions to delete"
        return 0
    fi
    
    # Validate session name if provided
    if [[ -n "$session_name" ]]; then
        # Check for dangerous characters
        if [[ "$session_name" =~ [\$\`\;\|\&\(\)\<\>\'\"] ]]; then
            echo "Error: Session name contains invalid characters" >&2
            return 1
        fi
        
        # Check length
        if [[ ${#session_name} -gt 50 ]]; then
            echo "Error: Session name too long" >&2
            return 1
        fi
    fi
    
    # Clear expired cache entries
    _zj_clear_expired_cache
    
    # Get current session list
    local session_list
    if ! session_list=$(_zj_get_session_list); then
        echo "❌ Error: Failed to get session list" >&2
        return 1
    fi
    
    if [[ -z "$session_list" ]]; then
        echo "No sessions to delete"
        return 0
    fi
    
    local sessions_to_delete=()
    local current_session="${ZELLIJ_SESSION_NAME:-}"
    
    if [[ "$all_mode" == true ]]; then
        # Delete all sessions except current
        while IFS= read -r line; do
            [[ -n "$line" ]] || continue
            local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
            local session=$(echo "$clean_line" | awk '{print $1}')
            if [[ "$session" != "$current_session" ]]; then
                sessions_to_delete+=("$session")
            fi
        done <<< "$session_list"
        
    elif [[ -z "$session_name" ]]; then
        # Interactive selection
        if command -v fzf >/dev/null 2>&1; then
            local selected_sessions
            selected_sessions=$(echo "$session_list" | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | grep -v "^$current_session$" | fzf --multi --prompt="Select sessions to delete (TAB for multiple): " --height=10)
            
            if [[ -z "$selected_sessions" ]]; then
                echo "No sessions selected"
                return 0
            fi
            
            while IFS= read -r session; do
                [[ -n "$session" ]] && sessions_to_delete+=("$session")
            done <<< "$selected_sessions"
        else
            echo "Available sessions (excluding current):"
            local available_sessions=()
            local index=1
            
            while IFS= read -r line; do
                [[ -n "$line" ]] || continue
                local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
                local session=$(echo "$clean_line" | awk '{print $1}')
                if [[ "$session" != "$current_session" ]]; then
                    echo "  $index) $session"
                    available_sessions+=("$session")
                    ((index++))
                fi
            done <<< "$session_list"
            
            if [[ ${#available_sessions[@]} -eq 0 ]]; then
                echo "No other sessions available to delete"
                return 0
            fi
            
            echo ""
            read -p "Enter session number(s) to delete (space-separated, or 'all'): " -r selection
            
            if [[ "$selection" == "all" ]]; then
                sessions_to_delete=("${available_sessions[@]}")
            else
                for num in $selection; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#available_sessions[@]} ]]; then
                        sessions_to_delete+=("${available_sessions[$((num-1))]}")
                    else
                        echo "⚠️  Invalid selection: $num" >&2
                    fi
                done
            fi
        fi
        
    elif [[ "$pattern_mode" == true ]]; then
        # Pattern matching
        while IFS= read -r line; do
            [[ -n "$line" ]] || continue
            local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
            local session=$(echo "$clean_line" | awk '{print $1}')
            if [[ "$session" == $session_name* ]] && [[ "$session" != "$current_session" ]]; then
                sessions_to_delete+=("$session")
            fi
        done <<< "$session_list"
        
    else
        # Single session deletion
        # Check if session name is empty for single deletion
        if [[ -z "$session_name" ]]; then
            echo "No sessions to delete"
            return 0
        fi
        
        # Current session protection
        if [[ "$session_name" == "$current_session" ]]; then
            echo "❌ Cannot delete current session '$session_name'" >&2
            return 1
        fi
        
        # Check if session exists
        if echo "$session_list" | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$session_name\b"; then
            sessions_to_delete+=("$session_name")
        else
            echo "❌ Session '$session_name' not found" >&2
            zjl
            return 1
        fi
    fi
    
    # Confirm deletion if not forced
    if [[ ${#sessions_to_delete[@]} -eq 0 ]]; then
        echo "No sessions to delete"
        return 0
    fi
    
    echo ""
    echo "Sessions to delete:"
    for session in "${sessions_to_delete[@]}"; do
        if [[ "$session" == "$current_session" ]]; then
            echo "  🔸 $session (current session)"
        else
            echo "  🔸 $session"
        fi
    done
    
    if [[ "$force_flag" == false ]]; then
        echo ""
        read -p "Are you sure you want to delete ${#sessions_to_delete[@]} session(s)? (y/N): " -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            return 0
        fi
    fi
    
    # Delete sessions
    local failed=0
    local success=0
    
    echo ""
    echo "🗑️  Deleting ${#sessions_to_delete[@]} session(s)..."
    
    for session in "${sessions_to_delete[@]}"; do
        echo "  Deleting session: $session"
        if zellij kill-session "$session" 2>/dev/null; then
            ((success++))
        else
            echo "  ⚠️  Failed to delete session: $session" >&2
            ((failed++))
        fi
    done
    
    # Invalidate session cache after deletion
    unset _ZJ_SESSION_CACHE["sessions"]
    
    # Summary
    echo ""
    if [[ $success -gt 0 ]]; then
        echo "✅ Successfully deleted $success session(s)"
    fi
    if [[ $failed -gt 0 ]]; then
        echo "⚠️  Failed to delete $failed session(s)" >&2
        return 1
    fi
}

# Kill all sessions except current
zjka() {
    local current_session="${ZELLIJ_SESSION_NAME:-}"
    _zj_clear_expired_cache
    local all_sessions sessions
    if ! all_sessions=$(_zj_get_session_list); then
        echo "❌ Error: Failed to get session list" >&2
        return 1
    fi
    # Parse and filter sessions more reliably
    local session_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        # Remove ANSI color codes and extract session name (first word)
        local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local session_name=$(echo "$clean_line" | awk '{print $1}')
        
        # Skip current session (exact match)
        if [[ "$session_name" != "$current_session" ]]; then
            session_array+=("$session_name")
        fi
    done <<< "$all_sessions"
    
    if [[ ${#session_array[@]} -eq 0 ]]; then
        echo "No other sessions to kill"
        return 0
    fi
    
    echo "🗑️  Killing ${#session_array[@]} session(s) except: $current_session"
    local failed=0
    for session in "${session_array[@]}"; do
        if [[ -n "$session" ]]; then
            echo "  Killing session: $session"
            if ! zellij kill-session "$session" 2>/dev/null; then
                echo "  ⚠️  Failed to kill session: $session" >&2
                ((failed++))
            fi
        fi
    done
    
    if [[ $failed -gt 0 ]]; then
        echo "⚠️  Warning: $failed session(s) could not be killed" >&2
    else
        echo "✅ All other sessions killed successfully"
    fi
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
    
    _zj_clear_expired_cache
    local session_list
    if session_list=$(_zj_get_session_list) && echo "$session_list" | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$session_name\b"; then
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
    
    # Validate layout parameter if provided
    if [[ -n "$layout" ]] && [[ ! "$layout" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "❌ Error: Invalid layout name '$layout'" >&2
        echo "   Layout names must contain only letters, numbers, hyphens, and underscores" >&2
        return 1
    fi
    
    zj "$project_name" "$layout"
}

# =============================================================================
# QUICK NAVIGATION & CREATION
# =============================================================================

# Quick session for current git project
zjgit() {
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Error: git command not found" >&2
        return 1
    fi
    
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: Not in a git repository" >&2
        return 1
    fi
    
    local repo_root
    if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        echo "❌ Error: Failed to get git repository root" >&2
        return 1
    fi
    
    if [[ ! -d "$repo_root" ]]; then
        echo "❌ Error: Repository root '$repo_root' not accessible" >&2
        return 1
    fi
    
    local repo_name=$(basename "$repo_root")
    cd "$repo_root" && zj "$repo_name"
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
    
    # Validate session name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ ${#project_name} -gt 50 ]]; then
        echo "❌ Error: Invalid session name '$project_name'" >&2
        echo "   Session names must contain only letters, numbers, hyphens, and underscores (max 50 chars)" >&2
        return 1
    fi
    
    # Check if zellij is available
    if ! command -v zellij >/dev/null 2>&1; then
        echo "❌ Error: zellij command not found. Please install zellij first." >&2
        return 1
    fi
    
    # Create session if it doesn't exist
    _zj_clear_expired_cache
    local session_list
    if ! session_list=$(_zj_get_session_list) || ! echo "$session_list" | sed 's/\x1b\[[0-9;]*m//g' | grep -q "^$project_name\b"; then
        echo "🚀 Setting up development workspace: $project_name"
        
        # Create initial session
        if ! zj "$project_name"; then
            echo "❌ Error: Failed to create session '$project_name'" >&2
            return 1
        fi
        
        # Add new panes and tabs with error handling
        sleep 1
        if ! zellij action new-pane --direction down 2>/dev/null; then
            echo "⚠️  Warning: Failed to create bottom pane" >&2
        fi
        
        if ! zellij action new-tab --name "editor" 2>/dev/null; then
            echo "⚠️  Warning: Failed to create editor tab" >&2
        fi
        
        if ! zellij action new-tab --name "server" 2>/dev/null; then
            echo "⚠️  Warning: Failed to create server tab" >&2
        fi
        
        if ! zellij action go-to-tab 1 2>/dev/null; then
            echo "⚠️  Warning: Failed to switch to first tab" >&2
        fi
        
        echo "✅ Development workspace '$project_name' setup complete"
    else
        echo "📎 Attaching to existing workspace: $project_name"
        if ! zj "$project_name"; then
            echo "❌ Error: Failed to attach to session '$project_name'" >&2
            return 1
        fi
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
    
    _zj_clear_expired_cache
    local session_list
    if ! session_list=$(_zj_get_session_list); then
        echo "❌ Error: Failed to get session list" >&2
        return 1
    fi
    
    local session=$(echo "$session_list" | fzf --prompt="Select session: " --height=10)
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
    if [[ -z "${ZELLIJ:-}" && $- == *i* ]]; then
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
alias zdelete='zjd'


# =============================================================================
# COMPLETION (optional)
# =============================================================================

# Basic completion for session names
_zellij_sessions() {
    _zj_clear_expired_cache
    local sessions
    if sessions=$(_zj_get_session_list 2>/dev/null); then
        COMPREPLY=($(compgen -W "$sessions" -- "${COMP_WORDS[COMP_CWORD]}"))
    else
        COMPREPLY=()
    fi
}

# Register completions
complete -F _zellij_sessions zjs zjk zjd

# =============================================================================
# INITIALIZATION
# =============================================================================

# Call auto-start (comment out if you don't want auto-start)
zj_auto

echo "🚀 Zellij utilities loaded! Use 'zj' to start/attach sessions."