#!/bin/bash
# Configuration Validator for Zellij Utils
# Provides comprehensive validation for all configuration options

# Source the config loader for validation functions
source "$(dirname "${BASH_SOURCE[0]}")/config-loader.sh"

# Validation error tracking
declare -g ZJ_VALIDATION_ERRORS=0
declare -g ZJ_VALIDATION_WARNINGS=0

# Validation logging
_zj_log_error() {
    echo "ERROR: $1" >&2
    ((ZJ_VALIDATION_ERRORS++))
}

_zj_log_warning() {
    echo "WARNING: $1" >&2
    ((ZJ_VALIDATION_WARNINGS++))
}

_zj_log_info() {
    echo "INFO: $1" >&2
}

# Validate session name according to rules
zj_validate_session_name() {
    local name="$1"
    local errors=0
    
    if [[ -z "$name" ]]; then
        _zj_log_error "Session name cannot be empty"
        return 1
    fi
    
    if [[ ${#name} -gt ${ZJ_SESSION_NAME_MAX_LENGTH:-50} ]]; then
        _zj_log_error "Session name '$name' exceeds maximum length of ${ZJ_SESSION_NAME_MAX_LENGTH:-50}"
        ((errors++))
    fi
    
    if [[ ! "$name" =~ ${ZJ_SESSION_NAME_PATTERN:-^[a-zA-Z0-9_-]+$} ]]; then
        _zj_log_error "Session name '$name' contains invalid characters. Must match pattern: ${ZJ_SESSION_NAME_PATTERN:-^[a-zA-Z0-9_-]+$}"
        ((errors++))
    fi
    
    # Check for reserved names
    local reserved_names=("." ".." "~" "current" "default" "temp" "tmp")
    for reserved in "${reserved_names[@]}"; do
        if [[ "$name" == "$reserved" ]]; then
            _zj_log_error "Session name '$name' is reserved and cannot be used"
            ((errors++))
        fi
    done
    
    return $errors
}

# Validate path according to configuration rules
zj_validate_path() {
    local path="$1"
    local require_exists="${2:-false}"
    local errors=0
    
    if [[ -z "$path" ]]; then
        _zj_log_error "Path cannot be empty"
        return 1
    fi
    
    # Check for relative paths if not allowed
    if [[ "$ZJ_ALLOW_RELATIVE_PATHS" != "true" && "$path" != /* ]]; then
        _zj_log_error "Relative paths are not allowed: '$path'"
        ((errors++))
    fi
    
    # Check for dangerous path patterns
    if [[ "$path" =~ \.\./|/\.\./|\.\.$|//+ ]]; then
        _zj_log_error "Path contains dangerous patterns: '$path'"
        ((errors++))
    fi
    
    # Check if path should exist
    if [[ "$require_exists" == "true" && ! -e "$path" ]]; then
        _zj_log_error "Required path does not exist: '$path'"
        ((errors++))
    fi
    
    # Check for shell injection patterns
    if [[ "$path" =~ [\$\`\;] ]]; then
        _zj_log_error "Path contains shell injection patterns: '$path'"
        ((errors++))
    fi
    
    return $errors
}

# Validate layout name and file
zj_validate_layout() {
    local layout="$1"
    local errors=0
    
    if [[ -z "$layout" ]]; then
        _zj_log_error "Layout name cannot be empty"
        return 1
    fi
    
    # Validate layout name format
    if [[ ! "$layout" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        _zj_log_error "Layout name '$layout' contains invalid characters"
        ((errors++))
    fi
    
    # Check if layout file exists
    local layout_file="$HOME/${ZJ_LAYOUTS_DIR:-".config/zellij/layouts"}/$layout.kdl"
    if [[ ! -f "$layout_file" ]]; then
        _zj_log_warning "Layout file does not exist: $layout_file"
    else
        # Validate layout file syntax (basic check)
        if ! grep -q "^layout" "$layout_file" 2>/dev/null; then
            _zj_log_error "Layout file '$layout_file' appears to be invalid (missing 'layout' declaration)"
            ((errors++))
        fi
    fi
    
    return $errors
}

# Validate project markers configuration
zj_validate_project_markers() {
    local errors=0
    
    if [[ -z "${ZJ_PROJECT_MARKERS_ARRAY[*]}" ]]; then
        _zj_log_warning "No project markers defined"
        return 0
    fi
    
    for marker in "${ZJ_PROJECT_MARKERS_ARRAY[@]}"; do
        if [[ -z "$marker" ]]; then
            _zj_log_error "Empty project marker found"
            ((errors++))
            continue
        fi
        
        # Check for valid file patterns
        if [[ "$marker" =~ [\/\\] ]]; then
            _zj_log_error "Project marker '$marker' should not contain path separators"
            ((errors++))
        fi
    done
    
    return $errors
}

# Validate special directories configuration
zj_validate_special_dirs() {
    local errors=0
    
    for pattern in "${!ZJ_SPECIAL_DIRS_MAP[@]}"; do
        local name="${ZJ_SPECIAL_DIRS_MAP[$pattern]}"
        
        # Validate pattern
        if [[ -z "$pattern" ]]; then
            _zj_log_error "Empty pattern in special directories configuration"
            ((errors++))
            continue
        fi
        
        # Validate name
        if ! zj_validate_session_name "$name"; then
            _zj_log_error "Invalid session name '$name' for pattern '$pattern'"
            ((errors++))
        fi
        
        # Check if pattern directory exists (for non-wildcard patterns)
        if [[ "$pattern" != *"*"* && ! -d "$pattern" ]]; then
            _zj_log_warning "Special directory pattern '$pattern' does not exist"
        fi
    done
    
    return $errors
}

# Validate editor configuration
zj_validate_editor() {
    local errors=0
    
    # Check primary editor
    if [[ -n "$ZJ_EDITOR" ]]; then
        if ! command -v "$ZJ_EDITOR" >/dev/null 2>&1; then
            _zj_log_warning "Primary editor '$ZJ_EDITOR' not found in PATH"
        fi
    fi
    
    # Check alternate editor
    if [[ -n "$ZJ_ALTERNATE_EDITOR" ]]; then
        if ! command -v "$ZJ_ALTERNATE_EDITOR" >/dev/null 2>&1; then
            _zj_log_warning "Alternate editor '$ZJ_ALTERNATE_EDITOR' not found in PATH"
        fi
    fi
    
    return $errors
}

# Validate external tools configuration
zj_validate_external_tools() {
    local errors=0
    
    # Check fzf if enabled
    if [[ "$ZJ_FZF_ENABLED" == "true" ]]; then
        if ! command -v fzf >/dev/null 2>&1; then
            _zj_log_warning "FZF is enabled but 'fzf' command not found in PATH"
        fi
    fi
    
    # Check zellij availability
    if ! command -v zellij >/dev/null 2>&1; then
        _zj_log_error "Zellij command not found in PATH - this is required for functionality"
        ((errors++))
    fi
    
    # Check git availability
    if ! command -v git >/dev/null 2>&1; then
        _zj_log_warning "Git command not found in PATH - some features will be limited"
    fi
    
    return $errors
}

# Validate directory structure
zj_validate_directories() {
    local errors=0
    
    local required_dirs=(
        "$HOME/${ZJ_CONFIG_DIR:-".config/zellij"}"
        "$HOME/${ZJ_LAYOUTS_DIR:-".config/zellij/layouts"}"
    )
    
    local optional_dirs=(
        "$HOME/${ZJ_SAVED_SESSIONS_DIR:-".config/zellij/saved-sessions"}"
        "$HOME/${ZJ_SHELL_DIR:-".config/shell"}"
        "$HOME/${ZJ_DOTFILES_DIR:-".dotfiles"}"
    )
    
    # Check required directories
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            _zj_log_error "Required directory does not exist: $dir"
            ((errors++))
        elif [[ ! -w "$dir" ]]; then
            _zj_log_error "Required directory is not writable: $dir"
            ((errors++))
        fi
    done
    
    # Check optional directories
    for dir in "${optional_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            _zj_log_info "Optional directory does not exist: $dir (will be created if needed)"
        elif [[ ! -w "$dir" ]]; then
            _zj_log_warning "Optional directory is not writable: $dir"
        fi
    done
    
    return $errors
}

# Validate log configuration
zj_validate_logging() {
    local errors=0
    
    # Check log directory exists and is writable
    local log_dir="$(dirname "$ZJ_LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
        _zj_log_warning "Log directory does not exist: $log_dir"
    elif [[ ! -w "$log_dir" ]]; then
        _zj_log_error "Log directory is not writable: $log_dir"
        ((errors++))
    fi
    
    # Check log file permissions if it exists
    if [[ -f "$ZJ_LOG_FILE" && ! -w "$ZJ_LOG_FILE" ]]; then
        _zj_log_error "Log file is not writable: $ZJ_LOG_FILE"
        ((errors++))
    fi
    
    return $errors
}

# Comprehensive configuration validation
zj_validate_full_config() {
    echo "=== Zellij Utils Configuration Validation ===" >&2
    
    # Reset counters
    ZJ_VALIDATION_ERRORS=0
    ZJ_VALIDATION_WARNINGS=0
    
    # Load configuration first
    if ! zj_load_config; then
        _zj_log_error "Failed to load configuration"
        return 1
    fi
    
    # Run all validation checks
    _zj_validate_config || true  # Built-in validation from config-loader
    zj_validate_project_markers || true
    zj_validate_special_dirs || true
    zj_validate_editor || true
    zj_validate_external_tools || true
    zj_validate_directories || true
    zj_validate_logging || true
    
    # Test sample values
    echo "Testing sample session names..." >&2
    local test_names=("test-session" "my_project" "dev123" "invalid@name" "toolongname$(printf 'a%.0s' {1..50})")
    for name in "${test_names[@]}"; do
        if zj_validate_session_name "$name" >/dev/null 2>&1; then
            _zj_log_info "Valid session name: '$name'"
        fi
    done
    
    # Summary
    echo "=== Validation Summary ===" >&2
    echo "Errors: $ZJ_VALIDATION_ERRORS" >&2
    echo "Warnings: $ZJ_VALIDATION_WARNINGS" >&2
    
    if [[ $ZJ_VALIDATION_ERRORS -eq 0 ]]; then
        echo "Configuration validation PASSED" >&2
        return 0
    else
        echo "Configuration validation FAILED with $ZJ_VALIDATION_ERRORS errors" >&2
        return 1
    fi
}

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-full}" in
        "full"|"all")
            zj_validate_full_config
            ;;
        "session")
            shift
            zj_validate_session_name "$@"
            ;;
        "path")
            shift
            zj_validate_path "$@"
            ;;
        "layout")
            shift
            zj_validate_layout "$@"
            ;;
        *)
            echo "Usage: $0 [full|session <name>|path <path>|layout <layout>]" >&2
            echo "  full     - Validate entire configuration (default)" >&2
            echo "  session  - Validate a session name" >&2
            echo "  path     - Validate a path" >&2
            echo "  layout   - Validate a layout name" >&2
            exit 1
            ;;
    esac
fi