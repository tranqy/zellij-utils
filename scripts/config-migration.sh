#!/bin/bash
# Configuration Migration System for Zellij Utils
# Handles version upgrades and configuration format changes

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/config-loader.sh"

# Migration version mapping
declare -A ZJ_MIGRATION_PATHS=(
    ["0.8"]="0.9"
    ["0.9"]="1.0"
)

# Migration state tracking
ZJ_MIGRATION_LOG="$HOME/.config/zellij/migration.log"
ZJ_MIGRATION_BACKUP_DIR="$HOME/.config/zellij/backups"

# Logging functions
_zj_log_migration() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] $message" | tee -a "$ZJ_MIGRATION_LOG" >&2
}

_zj_migration_error() {
    _zj_log_migration "ERROR: $1"
    return 1
}

_zj_migration_info() {
    _zj_log_migration "INFO: $1"
}

_zj_migration_warning() {
    _zj_log_migration "WARNING: $1"
}

# Create backup of current configuration
zj_backup_config() {
    local backup_timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup_dir="$ZJ_MIGRATION_BACKUP_DIR/$backup_timestamp"
    
    _zj_migration_info "Creating configuration backup at: $backup_dir"
    
    mkdir -p "$backup_dir" || {
        _zj_migration_error "Failed to create backup directory: $backup_dir"
        return 1
    }
    
    # Backup all possible config locations
    for config_file in "${ZJ_CONFIG_FILES[@]}"; do
        if [[ -f "$config_file" ]]; then
            local relative_path="${config_file#$HOME/}"
            local backup_path="$backup_dir/$relative_path"
            mkdir -p "$(dirname "$backup_path")"
            
            if cp "$config_file" "$backup_path" 2>/dev/null; then
                _zj_migration_info "Backed up: $config_file"
            else
                _zj_migration_warning "Failed to backup: $config_file"
            fi
        fi
    done
    
    # Backup layout files
    local layouts_dir="$HOME/${ZJ_LAYOUTS_DIR:-".config/zellij/layouts"}"
    if [[ -d "$layouts_dir" ]]; then
        if cp -r "$layouts_dir" "$backup_dir/layouts" 2>/dev/null; then
            _zj_migration_info "Backed up layouts directory"
        else
            _zj_migration_warning "Failed to backup layouts directory"
        fi
    fi
    
    # Create backup manifest
    cat > "$backup_dir/manifest.txt" << EOF
Zellij Utils Configuration Backup
Created: $(date)
Original Version: ${ZJ_CONFIG_VERSION:-"unknown"}
Target Version: ${ZJ_CURRENT_CONFIG_VERSION}
Backup Directory: $backup_dir

Files included:
$(find "$backup_dir" -type f -not -name "manifest.txt" | sort)
EOF
    
    echo "$backup_dir"
}

# Restore configuration from backup
zj_restore_config() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        _zj_migration_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    _zj_migration_info "Restoring configuration from: $backup_dir"
    
    # Restore files
    find "$backup_dir" -type f -not -name "manifest.txt" | while read -r backup_file; do
        local relative_path="${backup_file#$backup_dir/}"
        local target_file="$HOME/$relative_path"
        
        mkdir -p "$(dirname "$target_file")"
        
        if cp "$backup_file" "$target_file" 2>/dev/null; then
            _zj_migration_info "Restored: $target_file"
        else
            _zj_migration_warning "Failed to restore: $target_file"
        fi
    done
    
    _zj_migration_info "Configuration restored successfully"
}

# Migrate from version 0.8 to 0.9
_zj_migrate_0_8_to_0_9() {
    _zj_migration_info "Migrating from version 0.8 to 0.9"
    
    # Example migration: rename old config file
    local old_config="$HOME/.zellij-utils.conf"
    local new_config="$HOME/.config/zellij/zellij-utils.conf"
    
    if [[ -f "$old_config" && ! -f "$new_config" ]]; then
        mkdir -p "$(dirname "$new_config")"
        if mv "$old_config" "$new_config"; then
            _zj_migration_info "Moved config file from $old_config to $new_config"
        else
            _zj_migration_error "Failed to move config file"
            return 1
        fi
    fi
    
    # Update configuration format
    if [[ -f "$new_config" ]]; then
        # Add new configuration options with defaults
        if ! grep -q "ZJ_CONFIG_VERSION" "$new_config"; then
            echo "" >> "$new_config"
            echo "# Migration settings" >> "$new_config"
            echo "ZJ_CONFIG_VERSION=\"0.9\"" >> "$new_config"
            echo "ZJ_AUTO_MIGRATE=true" >> "$new_config"
            echo "ZJ_BACKUP_ON_MIGRATE=true" >> "$new_config"
            _zj_migration_info "Added migration settings to config file"
        fi
    fi
    
    return 0
}

# Migrate from version 0.9 to 1.0
_zj_migrate_0_9_to_1_0() {
    _zj_migration_info "Migrating from version 0.9 to 1.0"
    
    local config_file="$HOME/.config/zellij/zellij-utils.conf"
    
    if [[ -f "$config_file" ]]; then
        # Update version in config file
        if grep -q "ZJ_CONFIG_VERSION=" "$config_file"; then
            sed -i 's/ZJ_CONFIG_VERSION="0.9"/ZJ_CONFIG_VERSION="1.0"/' "$config_file"
            _zj_migration_info "Updated config version to 1.0"
        fi
        
        # Add new 1.0 configuration options
        local new_options=(
            "ZJ_VSCODE_INTEGRATION=true"
            "ZJ_VSCODE_AUTO_START=true"
            "ZJ_VSCODE_TERMINAL_NAME=\"zellij\""
            "ZJ_LAYOUT_EDITOR_PANE=true"
            "ZJ_LAYOUT_GIT_PANE=true"
            "ZJ_LAYOUT_LOG_PANE=true"
        )
        
        for option in "${new_options[@]}"; do
            local key="${option%=*}"
            if ! grep -q "^$key=" "$config_file"; then
                echo "$option" >> "$config_file"
                _zj_migration_info "Added new option: $option"
            fi
        done
    fi
    
    # Migrate old session naming config if it exists
    local old_session_config="$HOME/.config/zellij/session-naming.conf"
    if [[ -f "$old_session_config" ]]; then
        _zj_migration_info "Converting old session naming configuration"
        
        # Read old config and convert to new format
        local temp_file="$(mktemp)"
        {
            echo "# Migrated session naming configuration"
            echo "# Original file: $old_session_config"
            echo ""
            
            # Extract old values and convert to new format
            if grep -q "USE_GIT_REPO_NAME=" "$old_session_config"; then
                grep "USE_GIT_REPO_NAME=" "$old_session_config" | sed 's/USE_GIT_REPO_NAME=/ZJ_USE_GIT_REPO_NAME=/'
            fi
            
            if grep -q "LOWERCASE_NAMES=" "$old_session_config"; then
                grep "LOWERCASE_NAMES=" "$old_session_config" | sed 's/LOWERCASE_NAMES=/ZJ_LOWERCASE_NAMES=/'
            fi
            
            if grep -q "SANITIZE_NAMES=" "$old_session_config"; then
                grep "SANITIZE_NAMES=" "$old_session_config" | sed 's/SANITIZE_NAMES=/ZJ_SANITIZE_NAMES=/'
            fi
            
        } > "$temp_file"
        
        # Append to main config file
        cat "$temp_file" >> "$config_file"
        rm "$temp_file"
        
        # Backup old config
        mv "$old_session_config" "$old_session_config.migrated"
        _zj_migration_info "Old session naming config backed up to: $old_session_config.migrated"
    fi
    
    return 0
}

# Get migration path from current version to target
zj_get_migration_path() {
    local current_version="$1"
    local target_version="$2"
    local path=()
    local version="$current_version"
    
    while [[ "$version" != "$target_version" ]]; do
        local next_version="${ZJ_MIGRATION_PATHS[$version]}"
        if [[ -z "$next_version" ]]; then
            echo "No migration path from $version to $target_version" >&2
            return 1
        fi
        
        path+=("$version->$next_version")
        version="$next_version"
    done
    
    printf '%s\n' "${path[@]}"
}

# Execute specific migration step
zj_execute_migration_step() {
    local from_version="$1"
    local to_version="$2"
    
    case "$from_version->$to_version" in
        "0.8->0.9")
            _zj_migrate_0_8_to_0_9
            ;;
        "0.9->1.0")
            _zj_migrate_0_9_to_1_0
            ;;
        *)
            _zj_migration_error "Unknown migration path: $from_version -> $to_version"
            return 1
            ;;
    esac
}

# Main migration function
zj_migrate_config() {
    local current_version="${1:-$ZJ_CONFIG_VERSION}"
    local target_version="${2:-$ZJ_CURRENT_CONFIG_VERSION}"
    local force_backup="${3:-$ZJ_BACKUP_ON_MIGRATE}"
    
    _zj_migration_info "Starting configuration migration"
    _zj_migration_info "Current version: $current_version"
    _zj_migration_info "Target version: $target_version"
    
    # Check if migration is needed
    if [[ "$current_version" == "$target_version" ]]; then
        _zj_migration_info "No migration needed - already at target version"
        return 0
    fi
    
    # Create backup if requested
    local backup_dir=""
    if [[ "$force_backup" == "true" ]]; then
        backup_dir="$(zj_backup_config)"
        if [[ $? -ne 0 ]]; then
            _zj_migration_error "Failed to create backup - aborting migration"
            return 1
        fi
    fi
    
    # Get migration path
    local migration_path
    if ! migration_path="$(zj_get_migration_path "$current_version" "$target_version")"; then
        _zj_migration_error "No migration path available"
        return 1
    fi
    
    _zj_migration_info "Migration path:"
    echo "$migration_path" | while read -r step; do
        _zj_migration_info "  $step"
    done
    
    # Execute migration steps
    local failed=false
    echo "$migration_path" | while read -r step; do
        local from_version="${step%->*}"
        local to_version="${step#*->}"
        
        _zj_migration_info "Executing migration step: $step"
        
        if ! zj_execute_migration_step "$from_version" "$to_version"; then
            _zj_migration_error "Migration step failed: $step"
            failed=true
            break
        fi
        
        _zj_migration_info "Migration step completed: $step"
    done
    
    if [[ "$failed" == "true" ]]; then
        _zj_migration_error "Migration failed - consider restoring from backup"
        if [[ -n "$backup_dir" ]]; then
            _zj_migration_info "Backup available at: $backup_dir"
            echo "To restore: zj_restore_config '$backup_dir'"
        fi
        return 1
    fi
    
    _zj_migration_info "Migration completed successfully"
    
    # Validate migrated configuration
    if command -v zj_validate_full_config >/dev/null 2>&1; then
        _zj_migration_info "Validating migrated configuration"
        if zj_validate_full_config >/dev/null 2>&1; then
            _zj_migration_info "Configuration validation passed"
        else
            _zj_migration_warning "Configuration validation failed - please review settings"
        fi
    fi
    
    return 0
}

# List available backups
zj_list_backups() {
    if [[ ! -d "$ZJ_MIGRATION_BACKUP_DIR" ]]; then
        echo "No backups found"
        return 0
    fi
    
    echo "Available backups:"
    find "$ZJ_MIGRATION_BACKUP_DIR" -name "manifest.txt" | while read -r manifest; do
        local backup_dir="$(dirname "$manifest")"
        local backup_name="$(basename "$backup_dir")"
        echo "  $backup_name"
        grep "Created:" "$manifest" | sed 's/^/    /'
        grep "Original Version:" "$manifest" | sed 's/^/    /'
        echo ""
    done
}

# Command line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-migrate}" in
        "migrate")
            shift
            zj_migrate_config "$@"
            ;;
        "backup")
            zj_backup_config
            ;;
        "restore")
            shift
            zj_restore_config "$@"
            ;;
        "list-backups")
            zj_list_backups
            ;;
        "path")
            shift
            zj_get_migration_path "$@"
            ;;
        *)
            echo "Usage: $0 [migrate|backup|restore <dir>|list-backups|path <from> <to>]" >&2
            echo "  migrate       - Migrate configuration to current version (default)" >&2
            echo "  backup        - Create backup of current configuration" >&2
            echo "  restore <dir> - Restore configuration from backup directory" >&2
            echo "  list-backups  - List available configuration backups" >&2
            echo "  path <from> <to> - Show migration path between versions" >&2
            exit 1
            ;;
    esac
fi