#!/bin/bash
# Advanced Session Naming System for Zellij Utils
# Supports user-defined patterns and comprehensive naming strategies

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/config-loader.sh"

# Session naming cache
declare -gA _ZJ_SESSION_NAME_CACHE
declare -g _ZJ_SESSION_NAME_CACHE_FILE="$HOME/.config/zellij/session-name-cache"

# Load session naming configuration
_zj_load_session_naming_config() {
    # Load session-specific config if it exists
    local session_config="$HOME/.config/zellij/session-naming.conf"
    if [[ -f "$session_config" ]]; then
        source "$session_config"
    fi
    
    # Ensure main config is loaded
    zj_load_config >/dev/null 2>&1
}

# Cache management for session names
_zj_load_session_name_cache() {
    if [[ "$ZJ_CACHE_SESSION_NAMES" != "true" ]]; then
        return 0
    fi
    
    if [[ -f "$_ZJ_SESSION_NAME_CACHE_FILE" ]]; then
        source "$_ZJ_SESSION_NAME_CACHE_FILE" 2>/dev/null || true
    fi
}

_zj_save_session_name_cache() {
    if [[ "$ZJ_CACHE_SESSION_NAMES" != "true" ]]; then
        return 0
    fi
    
    mkdir -p "$(dirname "$_ZJ_SESSION_NAME_CACHE_FILE")"
    
    {
        echo "# Session name cache - $(date)"
        for key in "${!_ZJ_SESSION_NAME_CACHE[@]}"; do
            printf '_ZJ_SESSION_NAME_CACHE[%q]=%q\n' "$key" "${_ZJ_SESSION_NAME_CACHE[$key]}"
        done
    } > "$_ZJ_SESSION_NAME_CACHE_FILE"
}

# Clean expired cache entries
_zj_clean_session_name_cache() {
    if [[ "$ZJ_CACHE_SESSION_NAMES" != "true" ]]; then
        return 0
    fi
    
    local current_time="$(date +%s)"
    local cache_ttl="${ZJ_SESSION_NAME_CACHE_TTL:-300}"
    local cleaned=false
    
    for key in "${!_ZJ_SESSION_NAME_CACHE[@]}"; do
        if [[ "$key" =~ ^(.+)_timestamp$ ]]; then
            local cache_time="${_ZJ_SESSION_NAME_CACHE[$key]}"
            if [[ $((current_time - cache_time)) -gt $cache_ttl ]]; then
                local base_key="${BASH_REMATCH[1]}"
                unset "_ZJ_SESSION_NAME_CACHE[$key]"
                unset "_ZJ_SESSION_NAME_CACHE[$base_key]"
                cleaned=true
            fi
        fi
    done
    
    if [[ "$cleaned" == "true" ]]; then
        _zj_save_session_name_cache
    fi
}

# Sanitize session name according to configuration
_zj_sanitize_session_name() {
    local name="$1"
    
    if [[ "$ZJ_SANITIZE_NAMES" != "true" ]]; then
        echo "$name"
        return 0
    fi
    
    # Remove/replace invalid characters
    local sanitized="$name"
    local remove_chars="${ZJ_SANITIZE_REMOVE_CHARS:- .()[]{}!@#$%^&*+=|\\:;\"'<>?/,}"
    local replace_char="${ZJ_SANITIZE_REPLACE_CHAR:-_}"
    
    # Replace each character in remove_chars with replace_char
    local i
    for ((i=0; i<${#remove_chars}; i++)); do
        local char="${remove_chars:$i:1}"
        sanitized="${sanitized//"$char"/"$replace_char"}"
    done
    
    # Remove consecutive replace characters
    while [[ "$sanitized" == *"${replace_char}${replace_char}"* ]]; do
        sanitized="${sanitized//"${replace_char}${replace_char}"/"$replace_char"}"
    done
    
    # Remove leading/trailing replace characters
    sanitized="${sanitized#"$replace_char"}"
    sanitized="${sanitized%"$replace_char"}"
    
    # Convert to lowercase if requested
    if [[ "$ZJ_LOWERCASE_NAMES" == "true" ]]; then
        sanitized="${sanitized,,}"
    fi
    
    echo "$sanitized"
}

# Apply custom naming patterns
_zj_apply_custom_patterns() {
    local name="$1"
    
    if [[ "$ZJ_ENABLE_CUSTOM_PATTERNS" != "true" || -z "$ZJ_CUSTOM_PATTERNS" ]]; then
        echo "$name"
        return 0
    fi
    
    local result="$name"
    IFS=',' read -ra patterns <<< "$ZJ_CUSTOM_PATTERNS"
    
    for pattern in "${patterns[@]}"; do
        if [[ "$pattern" =~ ^([^:]+):(.*)$ ]]; then
            local regex="${BASH_REMATCH[1]}"
            local replacement="${BASH_REMATCH[2]}"
            
            # Apply regex replacement if pattern matches
            if [[ "$result" =~ $regex ]]; then
                # Use sed for more complex replacements
                result="$(echo "$result" | sed -E "s/$regex/$replacement/")"
                break  # Only apply first matching pattern
            fi
        fi
    done
    
    echo "$result"
}

# Get git repository name with advanced options
_zj_get_git_repo_name() {
    local dir="${1:-$PWD}"
    
    if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 1
    fi
    
    local repo_name=""
    
    # Try remote name first if configured
    if [[ "$ZJ_USE_GIT_REMOTE_NAME" == "true" ]]; then
        local remote_name="${ZJ_GIT_REMOTE_NAME:-origin}"
        local remote_url="$(git -C "$dir" remote get-url "$remote_name" 2>/dev/null)"
        
        if [[ -n "$remote_url" ]]; then
            # Extract repo name from remote URL
            repo_name="$(basename "$remote_url" .git)"
        fi
    fi
    
    # Fallback to local repo name
    if [[ -z "$repo_name" ]]; then
        repo_name="$(basename "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)")"
    fi
    
    # Strip git suffixes if configured
    if [[ "$ZJ_STRIP_GIT_SUFFIXES" == "true" && -n "$ZJ_GIT_SUFFIXES" ]]; then
        IFS=',' read -ra suffixes <<< "$ZJ_GIT_SUFFIXES"
        for suffix in "${suffixes[@]}"; do
            repo_name="${repo_name%$suffix}"
        done
    fi
    
    echo "$repo_name"
}

# Check if directory matches special patterns
_zj_check_special_dirs() {
    local dir="$1"
    
    for pattern in "${!ZJ_SPECIAL_DIRS_MAP[@]}"; do
        local name="${ZJ_SPECIAL_DIRS_MAP[$pattern]}"
        
        # Handle wildcard patterns
        if [[ "$pattern" == *"*"* ]]; then
            if [[ "$dir" == $pattern ]]; then
                echo "$name"
                return 0
            fi
        else
            # Exact match
            if [[ "$dir" == "$pattern" ]]; then
                echo "$name"
                return 0
            fi
        fi
    done
    
    return 1
}

# Check for project markers in directory
_zj_check_project_markers() {
    local dir="$1"
    
    for marker in "${ZJ_PROJECT_MARKERS_ARRAY[@]}"; do
        if [[ -e "$dir/$marker" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Get project name using parent directory if nested
_zj_get_project_name() {
    local dir="$1"
    local current_dir="$dir"
    local depth=0
    local max_depth="${ZJ_PARENT_DEPTH_LIMIT:-3}"
    
    while [[ "$depth" -le "$max_depth" && "$current_dir" != "/" ]]; do
        if _zj_check_project_markers "$current_dir"; then
            if [[ "$ZJ_USE_PARENT_FOR_NESTED" == "true" && "$depth" -gt 0 ]]; then
                # Use parent directory name for nested projects
                echo "$(basename "$(dirname "$current_dir")")"
            else
                echo "$(basename "$current_dir")"
            fi
            return 0
        fi
        
        current_dir="$(dirname "$current_dir")"
        ((depth++))
    done
    
    # No project markers found, use directory name
    echo "$(basename "$dir")"
}

# Handle duplicate session names
_zj_handle_duplicate_name() {
    local name="$1"
    local strategy="${ZJ_DUPLICATE_NAME_STRATEGY:-suffix}"
    local format="${ZJ_DUPLICATE_NAME_FORMAT:-%d}"
    
    # Check if session already exists
    if ! zellij list-sessions 2>/dev/null | grep -q "^$name$"; then
        echo "$name"
        return 0
    fi
    
    case "$strategy" in
        "suffix")
            local counter=2
            while zellij list-sessions 2>/dev/null | grep -q "^${name}_${counter}$"; do
                ((counter++))
            done
            printf "${name}_${format}" "$counter"
            ;;
        "prefix")
            local counter=2
            while zellij list-sessions 2>/dev/null | grep -q "^${counter}_${name}$"; do
                ((counter++))
            done
            printf "${format}_${name}" "$counter"
            ;;
        "prompt")
            echo "Session '$name' already exists. Please choose a different name:" >&2
            read -r new_name
            echo "$new_name"
            ;;
        "error")
            echo "Session '$name' already exists" >&2
            return 1
            ;;
        *)
            echo "$name"
            ;;
    esac
}

# Fuzzy match against existing session names
_zj_fuzzy_match_session() {
    local name="$1"
    local threshold="${ZJ_FUZZY_THRESHOLD:-0.8}"
    
    if [[ "$ZJ_ENABLE_FUZZY_MATCHING" != "true" ]]; then
        echo "$name"
        return 0
    fi
    
    # Get list of existing sessions
    local sessions
    sessions="$(zellij list-sessions 2>/dev/null)" || {
        echo "$name"
        return 0
    }
    
    # Simple fuzzy matching using levenshtein distance approximation
    local best_match="$name"
    local best_score=0
    
    while IFS= read -r session; do
        if [[ -n "$session" ]]; then
            # Calculate similarity (simplified)
            local common_chars=0
            local max_len="${#name}"
            if [[ ${#session} -gt $max_len ]]; then
                max_len="${#session}"
            fi
            
            local i
            for ((i=0; i<${#name} && i<${#session}; i++)); do
                if [[ "${name:$i:1}" == "${session:$i:1}" ]]; then
                    ((common_chars++))
                fi
            done
            
            local score="$(echo "scale=2; $common_chars / $max_len" | bc 2>/dev/null || echo "0")"
            
            if (( $(echo "$score > $threshold && $score > $best_score" | bc 2>/dev/null || echo "0") )); then
                best_match="$session"
                best_score="$score"
            fi
        fi
    done <<< "$sessions"
    
    echo "$best_match"
}

# Main session name generation function
zj_generate_session_name() {
    local dir="${1:-$PWD}"
    local force_regenerate="${2:-false}"
    
    # Load configuration
    _zj_load_session_naming_config
    _zj_load_session_name_cache
    _zj_clean_session_name_cache
    
    # Check cache first
    local cache_key="$dir"
    if [[ "$force_regenerate" != "true" && "$ZJ_CACHE_SESSION_NAMES" == "true" ]]; then
        if [[ -n "${_ZJ_SESSION_NAME_CACHE[$cache_key]}" ]]; then
            echo "${_ZJ_SESSION_NAME_CACHE[$cache_key]}"
            return 0
        fi
    fi
    
    local session_name=""
    
    # Strategy 1: Check special directories
    if [[ -z "$session_name" ]]; then
        session_name="$(_zj_check_special_dirs "$dir")"
    fi
    
    # Strategy 2: Use git repository name
    if [[ -z "$session_name" && "$ZJ_USE_GIT_REPO_NAME" == "true" ]]; then
        session_name="$(_zj_get_git_repo_name "$dir")"
    fi
    
    # Strategy 3: Use project name based on markers
    if [[ -z "$session_name" ]]; then
        session_name="$(_zj_get_project_name "$dir")"
    fi
    
    # Strategy 4: Fallback to default
    if [[ -z "$session_name" ]]; then
        session_name="${ZJ_DEFAULT_SESSION_NAME:-default}"
    fi
    
    # Apply custom patterns
    session_name="$(_zj_apply_custom_patterns "$session_name")"
    
    # Sanitize the name
    session_name="$(_zj_sanitize_session_name "$session_name")"
    
    # Validate the name
    if ! zj_validate_session_name "$session_name" >/dev/null 2>&1; then
        session_name="${ZJ_DEFAULT_SESSION_NAME:-default}"
    fi
    
    # Handle duplicates
    session_name="$(_zj_handle_duplicate_name "$session_name")"
    
    # Apply fuzzy matching
    session_name="$(_zj_fuzzy_match_session "$session_name")"
    
    # Cache the result
    if [[ "$ZJ_CACHE_SESSION_NAMES" == "true" ]]; then
        _ZJ_SESSION_NAME_CACHE["$cache_key"]="$session_name"
        _ZJ_SESSION_NAME_CACHE["${cache_key}_timestamp"]="$(date +%s)"
        _zj_save_session_name_cache
    fi
    
    echo "$session_name"
}

# Clear session name cache
zj_clear_session_name_cache() {
    unset _ZJ_SESSION_NAME_CACHE
    declare -gA _ZJ_SESSION_NAME_CACHE
    rm -f "$_ZJ_SESSION_NAME_CACHE_FILE"
    echo "Session name cache cleared"
}

# Test session naming for a directory
zj_test_session_naming() {
    local dir="${1:-$PWD}"
    
    echo "Testing session naming for: $dir"
    echo "Configuration loaded: $(zj_load_config >/dev/null 2>&1 && echo "✓" || echo "✗")"
    echo ""
    
    # Show naming strategies
    echo "=== Naming Strategies ==="
    
    echo -n "Special directories: "
    local special_name="$(_zj_check_special_dirs "$dir")"
    if [[ -n "$special_name" ]]; then
        echo "✓ $special_name"
    else
        echo "✗ No match"
    fi
    
    echo -n "Git repository: "
    local git_name="$(_zj_get_git_repo_name "$dir")"
    if [[ -n "$git_name" ]]; then
        echo "✓ $git_name"
    else
        echo "✗ Not a git repo"
    fi
    
    echo -n "Project markers: "
    local project_name="$(_zj_get_project_name "$dir")"
    echo "✓ $project_name"
    
    echo ""
    echo "=== Final Result ==="
    local final_name="$(zj_generate_session_name "$dir")"
    echo "Generated name: $final_name"
    
    echo ""
    echo "=== Validation ==="
    if zj_validate_session_name "$final_name"; then
        echo "✓ Name is valid"
    else
        echo "✗ Name validation failed"
    fi
}

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-generate}" in
        "generate")
            shift
            zj_generate_session_name "$@"
            ;;
        "test")
            shift
            zj_test_session_naming "$@"
            ;;
        "clear-cache")
            zj_clear_session_name_cache
            ;;
        *)
            echo "Usage: $0 [generate [dir]|test [dir]|clear-cache]" >&2
            echo "  generate [dir] - Generate session name for directory (default: current)" >&2
            echo "  test [dir]     - Test session naming strategies for directory" >&2
            echo "  clear-cache    - Clear session name cache" >&2
            exit 1
            ;;
    esac
fi