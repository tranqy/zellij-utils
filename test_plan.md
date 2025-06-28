# Zellij Utils Production Test Plan

## Overview

This test plan ensures the zellij-utils system is production-ready by validating all critical functionality, configuration management, security measures, and edge cases.

## Test Categories

### 1. Configuration System Tests

#### 1.1 Configuration Loading Tests
- [ ] **Test default configuration loading**
  ```bash
  # Remove all config files and test defaults
  mv ~/.config/zellij/zellij-utils.conf ~/.config/zellij/zellij-utils.conf.backup 2>/dev/null || true
  source scripts/config-loader.sh
  zj_load_config
  echo "ZJ_AUTO_START_ENABLED: $ZJ_AUTO_START_ENABLED"  # Should be 'true'
  echo "ZJ_SESSION_NAME_MAX_LENGTH: $ZJ_SESSION_NAME_MAX_LENGTH"  # Should be '50'
  ```

- [ ] **Test configuration file precedence**
  ```bash
  # Create test configs in different locations
  echo "ZJ_AUTO_START_ENABLED=false" > ~/.config/zellij/zellij-utils.conf
  echo "ZJ_AUTO_START_ENABLED=true" > ~/.zellij-utils.conf
  source scripts/config-loader.sh
  zj_load_config
  echo "Should be 'false': $ZJ_AUTO_START_ENABLED"
  ```

- [ ] **Test environment variable override**
  ```bash
  export ZJ_AUTO_START_ENABLED=true
  echo "ZJ_AUTO_START_ENABLED=false" > ~/.config/zellij/zellij-utils.conf
  source scripts/config-loader.sh
  zj_load_config
  echo "Should be 'true': $ZJ_AUTO_START_ENABLED"
  ```

#### 1.2 Configuration Validation Tests
- [ ] **Test session name validation**
  ```bash
  source scripts/config-validator.sh
  zj_validate_session_name "valid-name"      # Should pass
  zj_validate_session_name "invalid@name"   # Should fail
  zj_validate_session_name "$(printf 'a%.0s' {1..60})"  # Should fail (too long)
  zj_validate_session_name ""               # Should fail (empty)
  ```

- [ ] **Test path validation**
  ```bash
  source scripts/config-validator.sh
  zj_validate_path "/valid/absolute/path"    # Should pass
  zj_validate_path "../dangerous/path"      # Should fail
  zj_validate_path "path\$injection"        # Should fail
  ```

- [ ] **Test full configuration validation**
  ```bash
  source scripts/config-validator.sh
  zj_validate_full_config  # Should pass with clean config
  ```

#### 1.3 Configuration Migration Tests
- [ ] **Test migration system**
  ```bash
  # Create old config format
  echo 'ZJ_CONFIG_VERSION="0.9"' > ~/.config/zellij/zellij-utils.conf
  source scripts/config-migration.sh
  zj_migrate_config  # Should upgrade to 1.0
  grep 'ZJ_CONFIG_VERSION="1.0"' ~/.config/zellij/zellij-utils.conf
  ```

- [ ] **Test backup creation**
  ```bash
  source scripts/config-migration.sh
  backup_dir=$(zj_backup_config)
  [[ -d "$backup_dir" ]] && echo "Backup created: $backup_dir"
  [[ -f "$backup_dir/manifest.txt" ]] && echo "Manifest exists"
  ```

#### 1.4 Runtime Configuration Tests
- [ ] **Test configuration reload**
  ```bash
  source scripts/config-loader.sh
  zj_load_config
  echo "ZJ_AUTO_START_ENABLED=false" >> ~/.config/zellij/zellij-utils.conf
  zj_reload_config
  echo "Should be 'false': $ZJ_AUTO_START_ENABLED"
  ```

### 2. Session Naming System Tests

#### 2.1 Basic Session Naming Tests
- [ ] **Test git repository naming**
  ```bash
  cd /tmp && git init test-repo && cd test-repo
  source ../path/to/scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'test-repo'
  cd .. && rm -rf test-repo
  ```

- [ ] **Test project marker detection**
  ```bash
  mkdir -p /tmp/test-project && cd /tmp/test-project
  touch package.json
  source ../path/to/scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'test-project'
  cd .. && rm -rf test-project
  ```

- [ ] **Test special directory patterns**
  ```bash
  cd "$HOME/.config"
  source scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'config'
  ```

#### 2.2 Advanced Session Naming Tests
- [ ] **Test custom naming patterns**
  ```bash
  # Set custom pattern in config
  echo 'ZJ_CUSTOM_PATTERNS="([^/]+)-app$:\1"' >> ~/.config/zellij/session-naming.conf
  mkdir -p /tmp/myapp-app && cd /tmp/myapp-app
  source scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'myapp'
  cd .. && rm -rf myapp-app
  ```

- [ ] **Test session name sanitization**
  ```bash
  mkdir -p "/tmp/invalid@name" && cd "/tmp/invalid@name"
  source scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'invalid_name'
  cd .. && rm -rf "invalid@name"
  ```

- [ ] **Test duplicate handling**
  ```bash
  # Create existing session
  zellij -d -s test-session
  mkdir -p /tmp/test-session && cd /tmp/test-session
  source scripts/session-naming.sh
  name=$(zj_generate_session_name)
  echo "Generated name: $name"  # Should be 'test-session_2'
  zellij kill-session test-session
  cd .. && rm -rf test-session
  ```

### 3. Core Functionality Tests

#### 3.1 Session Management Tests
- [ ] **Test session creation with smart naming**
  ```bash
  source scripts/zellij-utils.sh
  cd /tmp && git init test-session && cd test-session
  zj  # Should create session named 'test-session'
  zellij list-sessions | grep test-session
  zellij kill-session test-session
  cd .. && rm -rf test-session
  ```

- [ ] **Test session attachment to existing**
  ```bash
  source scripts/zellij-utils.sh
  zellij -d -s existing-session
  zj existing-session  # Should attach to existing session
  zellij kill-session existing-session
  ```

- [ ] **Test session listing and killing**
  ```bash
  source scripts/zellij-utils.sh
  zellij -d -s test1 && zellij -d -s test2
  zjl  # Should list both sessions
  zjk test1  # Should kill test1
  zjl | grep -v test1  # Should not show test1
  zellij kill-session test2
  ```

#### 3.2 Layout Tests
- [ ] **Test development layout creation**
  ```bash
  source scripts/zellij-utils.sh
  zjdev test-dev dev  # Should create session with dev layout
  # Verify layout panes exist
  zellij list-sessions | grep test-dev
  zellij kill-session test-dev
  ```

- [ ] **Test layout file validation**
  ```bash
  source scripts/config-validator.sh
  zj_validate_layout "dev"     # Should pass
  zj_validate_layout "nonexistent"  # Should fail
  ```

#### 3.3 Navigation Tests
- [ ] **Test directory navigation functions**
  ```bash
  source scripts/zellij-utils.sh
  zjh  # Should create/attach to home session
  zjc  # Should create/attach to config session
  # Clean up
  zellij kill-session home 2>/dev/null || true
  zellij kill-session config 2>/dev/null || true
  ```

### 4. Security Tests

#### 4.1 Input Validation Tests
- [ ] **Test shell injection prevention**
  ```bash
  source scripts/zellij-utils.sh
  # These should be safely handled
  zj "session; rm -rf /"  # Should be sanitized
  zj "session\$(cat /etc/passwd)"  # Should be sanitized
  zj "session\`whoami\`"  # Should be sanitized
  ```

- [ ] **Test path traversal prevention**
  ```bash
  source scripts/config-validator.sh
  zj_validate_path "../../../etc/passwd"  # Should fail
  zj_validate_path "/legitimate/path"     # Should pass
  ```

- [ ] **Test configuration injection prevention**
  ```bash
  # Test that malicious config values are rejected
  echo 'ZJ_SESSION_NAME_PATTERN=".*; rm -rf /"' > /tmp/bad-config.conf
  source /tmp/bad-config.conf
  source scripts/config-validator.sh
  zj_validate_full_config  # Should catch the malicious pattern
  rm /tmp/bad-config.conf
  ```

#### 4.2 Error Handling Tests
- [ ] **Test missing dependencies**
  ```bash
  # Temporarily rename zellij
  sudo mv /usr/bin/zellij /usr/bin/zellij.backup 2>/dev/null || true
  source scripts/zellij-utils.sh
  zj test-session 2>&1 | grep -i "not found"  # Should show error
  sudo mv /usr/bin/zellij.backup /usr/bin/zellij 2>/dev/null || true
  ```

- [ ] **Test corrupted configuration**
  ```bash
  echo "INVALID CONFIG SYNTAX" > ~/.config/zellij/zellij-utils.conf
  source scripts/config-loader.sh
  zj_load_config 2>&1 | grep -i "error"  # Should handle gracefully
  ```

### 5. Performance Tests

#### 5.1 Caching Tests
- [ ] **Test git repository caching**
  ```bash
  cd /tmp && git init large-repo && cd large-repo
  source scripts/zellij-utils.sh
  time zj  # First call - should cache git info
  time zj  # Second call - should use cache (faster)
  cd .. && rm -rf large-repo
  ```

- [ ] **Test session list caching**
  ```bash
  source scripts/zellij-utils.sh
  # Create multiple sessions
  for i in {1..5}; do zellij -d -s "test$i"; done
  time zjl  # Should cache session list
  time zjl  # Should use cached list
  # Clean up
  for i in {1..5}; do zellij kill-session "test$i"; done
  ```

#### 5.2 Scalability Tests
- [ ] **Test with many sessions**
  ```bash
  source scripts/zellij-utils.sh
  # Create 20 sessions
  for i in {1..20}; do zellij -d -s "scale-test-$i"; done
  time zjl  # Should handle many sessions efficiently
  time zjka "scale-test"  # Should kill all efficiently
  ```

### 6. Integration Tests

#### 6.1 Installation Tests
- [ ] **Test clean installation**
  ```bash
  # Backup existing config
  mv ~/.config/zellij ~/.config/zellij.backup 2>/dev/null || true
  mv ~/.config/shell ~/.config/shell.backup 2>/dev/null || true
  
  # Run installation
  ./scripts/install.sh
  
  # Verify installation
  [[ -f ~/.config/shell/zellij-utils.sh ]] || echo "FAIL: Main script not installed"
  [[ -f ~/.config/zellij/layouts/dev.kdl ]] || echo "FAIL: Layout not installed"
  [[ -f ~/.config/zellij/config.kdl ]] || echo "FAIL: Config not installed"
  
  # Test functionality
  source ~/.config/shell/zellij-utils.sh
  zj --help  # Should work
  
  # Restore backup
  rm -rf ~/.config/zellij ~/.config/shell
  mv ~/.config/zellij.backup ~/.config/zellij 2>/dev/null || true
  mv ~/.config/shell.backup ~/.config/shell 2>/dev/null || true
  ```

#### 6.2 Compatibility Tests
- [ ] **Test different shell environments**
  ```bash
  # Test in bash
  bash -c "source scripts/zellij-utils.sh && zj test-bash"
  zellij kill-session test-bash 2>/dev/null || true
  
  # Test in zsh (if available)
  if command -v zsh >/dev/null; then
    zsh -c "source scripts/zellij-utils.sh && zj test-zsh"
    zellij kill-session test-zsh 2>/dev/null || true
  fi
  ```

- [ ] **Test with different zellij versions**
  ```bash
  zellij --version
  source scripts/zellij-utils.sh
  zj version-test  # Should work with current zellij version
  zellij kill-session version-test 2>/dev/null || true
  ```

### 7. Edge Case Tests

#### 7.1 Filesystem Edge Cases
- [ ] **Test with spaces in paths**
  ```bash
  mkdir -p "/tmp/path with spaces" && cd "/tmp/path with spaces"
  source scripts/zellij-utils.sh
  zj  # Should handle spaces correctly
  cd /tmp && rm -rf "path with spaces"
  ```

- [ ] **Test with very long paths**
  ```bash
  long_path="/tmp/$(printf 'very-long-directory-name%.0s' {1..10})"
  mkdir -p "$long_path" && cd "$long_path"
  source scripts/zellij-utils.sh
  zj  # Should handle long paths
  cd /tmp && rm -rf "$long_path"
  ```

- [ ] **Test with non-existent directories**
  ```bash
  source scripts/zellij-utils.sh
  zjd /nonexistent/path 2>&1 | grep -i "error"  # Should show error
  ```

#### 7.2 Concurrent Access Tests
- [ ] **Test multiple simultaneous sessions**
  ```bash
  # Start multiple zj processes in background
  for i in {1..3}; do
    (cd /tmp && source scripts/zellij-utils.sh && zj "concurrent-$i") &
  done
  wait
  
  # Verify all sessions created
  for i in {1..3}; do
    zellij list-sessions | grep "concurrent-$i" || echo "FAIL: Session $i not created"
    zellij kill-session "concurrent-$i" 2>/dev/null || true
  done
  ```

### 8. Production Readiness Checklist

#### 8.1 Security Checklist
- [ ] All user inputs are validated and sanitized
- [ ] No shell injection vulnerabilities
- [ ] No path traversal vulnerabilities
- [ ] Configuration files have proper permissions
- [ ] No secrets or sensitive data in logs
- [ ] Error messages don't expose system information

#### 8.2 Reliability Checklist
- [ ] Graceful degradation when dependencies missing
- [ ] Proper error handling in all functions
- [ ] Configuration validation prevents invalid states
- [ ] Cache invalidation works correctly
- [ ] Migration system preserves user data
- [ ] Backup and restore functionality works

#### 8.3 Performance Checklist
- [ ] Caching reduces redundant operations
- [ ] Session operations scale with number of sessions
- [ ] Configuration loading is efficient
- [ ] No memory leaks in long-running processes
- [ ] Startup time is acceptable

#### 8.4 Usability Checklist
- [ ] Installation process is straightforward
- [ ] Error messages are helpful and actionable
- [ ] Configuration options are well-documented
- [ ] Default settings work out of the box
- [ ] Migration preserves user customizations

## Test Execution

### Automated Test Runner
```bash
#!/bin/bash
# run_production_tests.sh

echo "=== Zellij Utils Production Test Suite ==="
echo "Starting: $(date)"

failed_tests=0
total_tests=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Running: $test_name"
    ((total_tests++))
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✓ PASS: $test_name"
    else
        echo "✗ FAIL: $test_name"
        ((failed_tests++))
    fi
}

# Add all test calls here
# run_test "Config Loading" "source scripts/config-loader.sh && zj_load_config"
# ... more tests

echo ""
echo "=== Test Summary ==="
echo "Total tests: $total_tests"
echo "Failed tests: $failed_tests"
echo "Success rate: $(( (total_tests - failed_tests) * 100 / total_tests ))%"

if [[ $failed_tests -eq 0 ]]; then
    echo "🎉 All tests passed! System is production ready."
    exit 0
else
    echo "❌ Some tests failed. Review and fix before production deployment."
    exit 1
fi
```

### Manual Testing Procedures

1. **Fresh Environment Test**: Test on a clean system without existing zellij configuration
2. **Upgrade Test**: Test migration from previous version
3. **Load Test**: Create 50+ sessions and verify performance
4. **Stress Test**: Rapid session creation/deletion cycles
5. **Integration Test**: Test with real development workflows

## Success Criteria

The system is considered production-ready when:

- [ ] All automated tests pass
- [ ] No security vulnerabilities found
- [ ] Performance meets requirements (session operations < 500ms)
- [ ] Installation succeeds on target platforms
- [ ] Migration preserves all user settings
- [ ] Error handling is robust and informative
- [ ] Documentation is complete and accurate

## Risk Assessment

**High Risk Areas:**
- Shell injection in session names
- Path traversal in navigation functions
- Configuration migration data loss
- Cache corruption issues

**Medium Risk Areas:**
- Performance degradation with many sessions
- Compatibility with different zellij versions
- Error handling edge cases

**Low Risk Areas:**
- Minor UI/UX issues
- Non-critical configuration options
- Optional feature failures

## Post-Deployment Monitoring

1. Monitor session creation success rates
2. Track configuration migration statistics
3. Watch for error patterns in logs
4. Collect user feedback on reliability
5. Performance metrics for large installations

This comprehensive test plan ensures the zellij-utils system meets production quality standards for security, reliability, performance, and usability.