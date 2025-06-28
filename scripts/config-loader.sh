#!/bin/bash
# Configuration Loader for Zellij Utils
# Provides centralized configuration management with validation and migration

# Configuration file locations (in order of precedence)
declare -a ZJ_CONFIG_FILES=(
    "$HOME/.config/zellij/zellij-utils.conf"
    "$HOME/.zellij-utils.conf"
    "/etc/zellij-utils/config.conf"
    "./config/zellij-utils.conf"
)

# Configuration version for migration support
ZJ_CURRENT_CONFIG_VERSION="1.0"

# Default configuration values
_zj_set_defaults() {
    # Session Management
    ZJ_AUTO_START_ENABLED=${ZJ_AUTO_START_ENABLED:-true}
    ZJ_AUTO_START_IN_SSH=${ZJ_AUTO_START_IN_SSH:-false}
    ZJ_AUTO_START_DELAY=${ZJ_AUTO_START_DELAY:-1}
    
    # Session naming
    ZJ_USE_GIT_REPO_NAME=${ZJ_USE_GIT_REPO_NAME:-true}
    ZJ_LOWERCASE_NAMES=${ZJ_LOWERCASE_NAMES:-true}
    ZJ_SANITIZE_NAMES=${ZJ_SANITIZE_NAMES:-true}
    ZJ_DEFAULT_SESSION_NAME=${ZJ_DEFAULT_SESSION_NAME:-"default"}
    
    # Performance
    ZJ_CACHE_TTL=${ZJ_CACHE_TTL:-60}
    ZJ_ENABLE_CACHING=${ZJ_ENABLE_CACHING:-true}
    
    # Directories
    ZJ_CONFIG_DIR=${ZJ_CONFIG_DIR:-".config/zellij"}
    ZJ_LAYOUTS_DIR=${ZJ_LAYOUTS_DIR:-".config/zellij/layouts"}
    ZJ_SAVED_SESSIONS_DIR=${ZJ_SAVED_SESSIONS_DIR:-".config/zellij/saved-sessions"}
    ZJ_SHELL_DIR=${ZJ_SHELL_DIR:-".config/shell"}
    ZJ_DOTFILES_DIR=${ZJ_DOTFILES_DIR:-".dotfiles"}
    ZJ_PROJECTS_DIR=${ZJ_PROJECTS_DIR:-"projects"}
    
    # Editor and Tools
    ZJ_EDITOR=${ZJ_EDITOR:-"nvim"}
    ZJ_ALTERNATE_EDITOR=${ZJ_ALTERNATE_EDITOR:-"nano"}
    ZJ_FZF_ENABLED=${ZJ_FZF_ENABLED:-true}
    ZJ_FZF_OPTIONS=${ZJ_FZF_OPTIONS:-"--height 40% --border --layout=reverse"}
    
    # Project Detection
    ZJ_PROJECT_MARKERS=${ZJ_PROJECT_MARKERS:-"package.json,Cargo.toml,go.mod,.git,pyproject.toml,composer.json,Makefile,CMakeLists.txt,Dockerfile"}
    ZJ_SPECIAL_DIRS=${ZJ_SPECIAL_DIRS:-"/:root,$HOME:home,$HOME/.config/*:config,$HOME/Documents/*:docs"}
    
    # Validation
    ZJ_SESSION_NAME_MAX_LENGTH=${ZJ_SESSION_NAME_MAX_LENGTH:-50}
    ZJ_SESSION_NAME_PATTERN=${ZJ_SESSION_NAME_PATTERN:-"^[a-zA-Z0-9_-]+$"}
    ZJ_VALIDATE_PATHS=${ZJ_VALIDATE_PATHS:-true}
    ZJ_ALLOW_RELATIVE_PATHS=${ZJ_ALLOW_RELATIVE_PATHS:-false}
    
    # Layouts
    ZJ_DEFAULT_LAYOUT=${ZJ_DEFAULT_LAYOUT:-"simple"}
    ZJ_DEV_LAYOUT=${ZJ_DEV_LAYOUT:-"dev"}
    ZJ_WORK_LAYOUT=${ZJ_WORK_LAYOUT:-"dev"}
    ZJ_LAYOUT_EDITOR_PANE=${ZJ_LAYOUT_EDITOR_PANE:-true}
    ZJ_LAYOUT_GIT_PANE=${ZJ_LAYOUT_GIT_PANE:-true}
    ZJ_LAYOUT_LOG_PANE=${ZJ_LAYOUT_LOG_PANE:-true}
    
    # Logging
    ZJ_DEBUG_MODE=${ZJ_DEBUG_MODE:-false}
    ZJ_LOG_FILE=${ZJ_LOG_FILE:-"$HOME/.config/zellij/zellij-utils.log"}
    ZJ_LOG_LEVEL=${ZJ_LOG_LEVEL:-"INFO"}
    
    # Migration
    ZJ_CONFIG_VERSION=${ZJ_CONFIG_VERSION:-"1.0"}
    ZJ_AUTO_MIGRATE=${ZJ_AUTO_MIGRATE:-true}
    ZJ_BACKUP_ON_MIGRATE=${ZJ_BACKUP_ON_MIGRATE:-true}
    
    # VS Code Integration
    ZJ_VSCODE_INTEGRATION=${ZJ_VSCODE_INTEGRATION:-true}
    ZJ_VSCODE_AUTO_START=${ZJ_VSCODE_AUTO_START:-true}
    ZJ_VSCODE_TERMINAL_NAME=${ZJ_VSCODE_TERMINAL_NAME:-"zellij"}
}

# Validate configuration values
_zj_validate_config() {
    local errors=0
    
    # Validate session name settings
    if [[ ! "$ZJ_SESSION_NAME_MAX_LENGTH" =~ ^[0-9]+$ ]] || [[ "$ZJ_SESSION_NAME_MAX_LENGTH" -lt 1 ]]; then
        echo "Error: ZJ_SESSION_NAME_MAX_LENGTH must be a positive integer" >&2
        ((errors++))
    fi
    
    # Validate cache TTL
    if [[ ! "$ZJ_CACHE_TTL" =~ ^[0-9]+$ ]] || [[ "$ZJ_CACHE_TTL" -lt 1 ]]; then
        echo "Error: ZJ_CACHE_TTL must be a positive integer" >&2
        ((errors++))
    fi
    
    # Validate boolean values
    local booleans=(
        "ZJ_AUTO_START_ENABLED" "ZJ_AUTO_START_IN_SSH" "ZJ_USE_GIT_REPO_NAME"
        "ZJ_LOWERCASE_NAMES" "ZJ_SANITIZE_NAMES" "ZJ_ENABLE_CACHING"
        "ZJ_FZF_ENABLED" "ZJ_VALIDATE_PATHS" "ZJ_ALLOW_RELATIVE_PATHS"
        "ZJ_LAYOUT_EDITOR_PANE" "ZJ_LAYOUT_GIT_PANE" "ZJ_LAYOUT_LOG_PANE"
        "ZJ_DEBUG_MODE" "ZJ_AUTO_MIGRATE" "ZJ_BACKUP_ON_MIGRATE"
        "ZJ_VSCODE_INTEGRATION" "ZJ_VSCODE_AUTO_START"
    )
    
    for var in "${booleans[@]}"; do
        local value="${!var}"
        if [[ ! "$value" =~ ^(true|false)$ ]]; then
            echo "Error: $var must be 'true' or 'false', got '$value'" >&2
            ((errors++))
        fi
    done
    
    # Validate directories exist (for absolute paths)
    if [[ "$ZJ_VALIDATE_PATHS" == "true" ]]; then
        local dirs=("$HOME/$ZJ_CONFIG_DIR" "$HOME/$ZJ_LAYOUTS_DIR")
        for dir in "${dirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                echo "Warning: Directory $dir does not exist" >&2
            fi
        done
    fi
    
    # Validate log level
    if [[ ! "$ZJ_LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
        echo "Error: ZJ_LOG_LEVEL must be one of: DEBUG, INFO, WARN, ERROR" >&2
        ((errors++))
    fi
    
    return $errors
}

# Load configuration from files
_zj_load_config_files() {
    local loaded=false
    
    for config_file in "${ZJ_CONFIG_FILES[@]}"; do
        if [[ -f "$config_file" && -r "$config_file" ]]; then
            if [[ "$ZJ_DEBUG_MODE" == "true" ]]; then
                echo "Loading config from: $config_file" >&2
            fi
            
            # Safely source config file
            if source "$config_file" 2>/dev/null; then
                loaded=true
                break
            else
                echo "Warning: Failed to load config file: $config_file" >&2
            fi
        fi
    done
    
    if [[ "$loaded" != "true" && "$ZJ_DEBUG_MODE" == "true" ]]; then
        echo "No configuration file found, using defaults" >&2
    fi
}

# Convert comma-separated values to arrays
_zj_process_arrays() {
    # Convert project markers to array
    IFS=',' read -ra ZJ_PROJECT_MARKERS_ARRAY <<< "$ZJ_PROJECT_MARKERS"
    
    # Convert special dirs to associative array
    declare -gA ZJ_SPECIAL_DIRS_MAP
    IFS=',' read -ra special_dirs_array <<< "$ZJ_SPECIAL_DIRS"
    for item in "${special_dirs_array[@]}"; do
        if [[ "$item" =~ ^([^:]+):(.+)$ ]]; then
            local pattern="${BASH_REMATCH[1]}"
            local name="${BASH_REMATCH[2]}"
            # Safely expand $HOME in pattern
            pattern="${pattern//\$HOME/$HOME}"
            ZJ_SPECIAL_DIRS_MAP["$pattern"]="$name"
        fi
    done
}

# Check for configuration migration needs
_zj_check_migration() {
    if [[ "$ZJ_CONFIG_VERSION" != "$ZJ_CURRENT_CONFIG_VERSION" ]]; then
        if [[ "$ZJ_AUTO_MIGRATE" == "true" ]]; then
            _zj_migrate_config
        else
            echo "Warning: Configuration version mismatch. Current: $ZJ_CONFIG_VERSION, Expected: $ZJ_CURRENT_CONFIG_VERSION" >&2
            echo "Run 'zj-migrate-config' to update your configuration" >&2
        fi
    fi
}

# Migrate configuration to current version
_zj_migrate_config() {
    local backup_file="$HOME/.config/zellij/zellij-utils.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ "$ZJ_BACKUP_ON_MIGRATE" == "true" ]]; then
        for config_file in "${ZJ_CONFIG_FILES[@]}"; do
            if [[ -f "$config_file" ]]; then
                cp "$config_file" "$backup_file" 2>/dev/null
                echo "Configuration backed up to: $backup_file" >&2
                break
            fi
        done
    fi
    
    echo "Migrating configuration from version $ZJ_CONFIG_VERSION to $ZJ_CURRENT_CONFIG_VERSION" >&2
    
    # Add migration logic here for future versions
    case "$ZJ_CONFIG_VERSION" in
        "0.9")
            # Example migration from 0.9 to 1.0
            echo "Migrating from 0.9 to 1.0..." >&2
            ;;
        *)
            echo "No migration needed or unknown version: $ZJ_CONFIG_VERSION" >&2
            ;;
    esac
}

# Runtime configuration reload
zj_reload_config() {
    echo "Reloading zellij-utils configuration..." >&2
    
    # Clear any existing cached config
    unset ZJ_CONFIG_LOADED
    
    # Clear cached arrays and maps
    unset ZJ_PROJECT_MARKERS_ARRAY
    unset ZJ_SPECIAL_DIRS_MAP
    
    # Clear session naming cache if enabled
    if [[ "$ZJ_CACHE_SESSION_NAMES" == "true" ]]; then
        source "$(dirname "${BASH_SOURCE[0]}")/session-naming.sh"
        zj_clear_session_name_cache >/dev/null 2>&1
    fi
    
    # Reload configuration
    if zj_load_config; then
        echo "Configuration reloaded successfully" >&2
        
        # Validate the new configuration
        if command -v zj_validate_full_config >/dev/null 2>&1; then
            if zj_validate_full_config >/dev/null 2>&1; then
                echo "New configuration is valid" >&2
            else
                echo "Warning: New configuration has validation errors" >&2
            fi
        fi
        
        return 0
    else
        echo "Failed to reload configuration" >&2
        return 1
    fi
}

# Watch configuration files for changes (requires inotify-tools)
zj_watch_config() {
    if ! command -v inotifywait >/dev/null 2>&1; then
        echo "Error: inotifywait not found. Install inotify-tools to use config watching." >&2
        return 1
    fi
    
    echo "Watching configuration files for changes..." >&2
    echo "Press Ctrl+C to stop watching" >&2
    
    # Watch all possible config files
    local watch_files=()
    for config_file in "${ZJ_CONFIG_FILES[@]}"; do
        if [[ -f "$config_file" ]]; then
            watch_files+=("$config_file")
        fi
    done
    
    # Add session naming config
    local session_config="$HOME/.config/zellij/session-naming.conf"
    if [[ -f "$session_config" ]]; then
        watch_files+=("$session_config")
    fi
    
    if [[ ${#watch_files[@]} -eq 0 ]]; then
        echo "No configuration files found to watch" >&2
        return 1
    fi
    
    echo "Watching files:" >&2
    printf '  %s\n' "${watch_files[@]}" >&2
    echo "" >&2
    
    while inotifywait -e modify -e move -e create -e delete "${watch_files[@]}" 2>/dev/null; do
        echo "Configuration file changed, reloading..." >&2
        zj_reload_config
        echo "" >&2
    done
}

# Main configuration loader function
zj_load_config() {
    # Only load once per session unless explicitly reloaded
    if [[ "$ZJ_CONFIG_LOADED" == "true" ]]; then
        return 0
    fi
    
    # Set defaults first
    _zj_set_defaults
    
    # Load from configuration files
    _zj_load_config_files
    
    # Process array configurations
    _zj_process_arrays
    
    # Validate configuration
    if ! _zj_validate_config; then
        echo "Configuration validation failed. Using defaults where possible." >&2
        return 1
    fi
    
    # Check for migration needs
    _zj_check_migration
    
    # Mark as loaded
    ZJ_CONFIG_LOADED=true
    
    if [[ "$ZJ_DEBUG_MODE" == "true" ]]; then
        echo "Zellij-utils configuration loaded successfully" >&2
    fi
    
    return 0
}

# Export all configuration functions
export -f zj_load_config zj_reload_config