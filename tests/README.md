# Zellij Utils Test Suite

This directory contains a comprehensive test suite for the Zellij Utils project, ensuring production readiness and quality assurance.

## Test Coverage

### 🛡️ Security Tests (`security_tests.sh`)
- **Input Validation**: Tests session name sanitization and injection prevention
- **Command Safety**: Validates that no unsafe command execution patterns exist
- **Error Handling**: Ensures proper error responses for invalid inputs
- **Dependency Checks**: Verifies safe handling of external command dependencies

### 🔧 Integration Tests (`integration_tests.sh`)
- **Installation Process**: Tests the complete installation workflow
- **File Deployment**: Verifies correct placement of scripts and configurations
- **Core Functionality**: Tests that installed functions work correctly
- **Configuration Validation**: Ensures config files are properly formatted
- **Cleanup/Uninstallation**: Tests removal of installed components

### 🌐 Compatibility Tests (`compatibility_tests.sh`)
- **Shell Compatibility**: Tests Bash (4+) and Zsh compatibility
- **System Compatibility**: Tests across different operating systems
- **Path Handling**: Validates handling of various path formats and special characters
- **Environment Variables**: Tests proper environment variable usage
- **Performance**: Basic performance and memory usage validation
- **Edge Cases**: Tests handling of extreme inputs and error conditions

## Running Tests

### Quick Start
```bash
# Run all tests
./tests/run_all_tests.sh

# Run quietly (less output)
./tests/run_all_tests.sh --quiet

# Run individual test suites
./tests/security_tests.sh
./tests/integration_tests.sh
./tests/compatibility_tests.sh
```

### Test Runner Features
- **Comprehensive Reporting**: Detailed results with timing information
- **Production Readiness Assessment**: Clear pass/fail status for deployment
- **Automatic Cleanup**: Removes temporary test artifacts
- **Report Generation**: Creates timestamped test reports

## Test Environment Requirements

### Minimum Requirements
- Bash 4.0+ (for associative arrays in caching system)
- Standard POSIX utilities: `cp`, `mkdir`, `chmod`, `grep`, `sed`, `awk`
- Write access to test directories in `/tmp`

### Optional Dependencies
- `zsh` - For zsh compatibility testing
- `git` - For git integration testing
- `fzf` - For fuzzy finder testing
- `zellij` - For actual functionality testing (not required for syntax/structure tests)

## Test Structure

### Security Test Categories
1. **Input Sanitization**: Session names, paths, commands
2. **Command Injection Prevention**: Eval safety, parameter expansion
3. **Error Handling**: Graceful failure modes
4. **Dependency Validation**: Safe external command usage

### Integration Test Flow
1. **Environment Setup**: Create isolated test environment
2. **Dependency Check**: Verify installation requirements
3. **Installation Test**: Run installation process
4. **Functionality Test**: Verify installed components work
5. **Cleanup Test**: Ensure proper removal

### Compatibility Test Matrix
- **Shells**: Bash 4+, Zsh 5+
- **Systems**: Linux (Ubuntu, CentOS, Alpine), macOS, WSL2
- **Scenarios**: Various path formats, environment configurations
- **Edge Cases**: Empty inputs, very long inputs, special characters

## Production Readiness Criteria

### ✅ Ready for Production
- All security tests pass
- Installation process works reliably
- Core functionality operates correctly
- Compatible with target environments
- No critical performance issues

### ⚠️ Ready with Warnings
- Core functionality works
- Minor compatibility issues detected
- Non-critical test failures
- Performance within acceptable ranges

### ❌ Not Ready for Production
- Security vulnerabilities detected
- Installation failures
- Core functionality broken
- Major compatibility issues

## Test Results Interpretation

### Exit Codes
- `0`: All tests passed
- `1`: Test failures detected
- Other: System or script errors

### Test Status Indicators
- `✅ PASSED`: Test completed successfully
- `❌ FAILED`: Test detected issues
- `⚠️ WARNING`: Test passed with concerns
- `MISSING`: Test script not found
- `NOT_EXECUTABLE`: Test script permissions issue

## Maintenance

### Adding New Tests
1. Create test script in appropriate category
2. Make script executable: `chmod +x test_script.sh`
3. Add test to `run_all_tests.sh` if needed
4. Update this README with test description

### Test Debugging
- Individual test scripts can be run standalone
- Use `bash -x test_script.sh` for detailed execution tracing
- Check `/tmp/zellij-test-*` for temporary test artifacts
- Review generated test reports for detailed information

## Best Practices

### Test Design
- Tests should be idempotent (can run multiple times safely)
- Use temporary directories for isolation
- Clean up all test artifacts
- Provide clear pass/fail criteria

### Security Testing
- Never use real credentials or sensitive data
- Test with various malicious input patterns
- Verify all user inputs are properly validated
- Check for command injection vulnerabilities

### Compatibility Testing
- Test on minimum supported versions
- Include edge cases and error conditions
- Verify graceful degradation when optional tools are missing
- Test with various system configurations

## Continuous Integration

These tests are designed to be CI-friendly:
- Non-interactive execution
- Clear exit codes
- Structured output
- Minimal external dependencies
- Cleanup on completion

Example CI usage:
```bash
# In CI pipeline
cd zellij-utils
./tests/run_all_tests.sh --quiet
echo "Exit code: $?"
```

## Troubleshooting

### Common Issues
- **Permission Errors**: Ensure test scripts are executable
- **Missing Dependencies**: Install required tools or skip optional tests
- **Cleanup Failures**: Manually remove `/tmp/zellij-test-*` directories
- **False Positives**: Check system-specific compatibility issues

### Getting Help
- Review test output for specific failure details
- Check generated test reports
- Run individual test categories to isolate issues
- Verify system meets minimum requirements

This test suite ensures the Zellij Utils project maintains high quality and security standards suitable for production deployment.