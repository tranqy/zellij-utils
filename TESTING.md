# Testing Guide

## ⚠️ IMPORTANT SAFETY WARNING

**For local testing, ALWAYS use Docker-based testing to avoid interfering with your active zellij sessions:**
```bash
./scripts/test-local.sh    # SAFE - Uses Docker isolation
```

**AVOID direct native testing if you have active zellij sessions:**
```bash
./tests/run-tests.sh       # May interfere with your sessions - use with caution
```

This project uses a modern hybrid testing system that provides both complete local isolation and fast CI execution.

## Quick Start

### Local Development Testing (Recommended)

Use Docker for complete isolation from your running zellij sessions:

```bash
# Run main tests with isolation
./scripts/test-local.sh

# Test both Ubuntu and Alpine
./scripts/test-local.sh -t both

# Interactive debugging
./scripts/test-local.sh --shell
```

### Native Testing

For quick validation without Docker:

```bash
# Auto-detect environment and run tests
./tests/run-tests.sh

# Quick validation only
./tests/run-tests.sh --quick

# Verbose output
./tests/run-tests.sh --verbose
```

## Architecture

The testing system has two complementary approaches:

### 1. Local Docker Testing
- **Purpose**: Complete isolation for development
- **Benefits**: No interference with your zellij sessions
- **Usage**: `./scripts/test-local.sh`
- **Environments**: Ubuntu and Alpine Linux containers

### 2. Native CI Testing
- **Purpose**: Fast, reliable GitHub Actions
- **Benefits**: 5x faster, no hanging issues
- **Usage**: Automatic in CI, or `./tests/run-tests.sh`
- **Environments**: GitHub Actions runners

## Test Structure

```
tests/
├── shared/           # Environment-agnostic test logic
│   └── core-tests.sh # Main test suites
├── utils/            # Common test framework
│   └── test-framework.sh
├── local/            # Docker-specific setup
│   └── docker-setup.sh
├── ci/               # Native environment setup
│   ├── github-setup.sh
│   └── native-setup.sh
└── run-tests.sh      # Universal test runner
```

## Test Categories

1. **Validation Tests** - Script syntax and layout files
2. **Configuration Tests** - Script loading and function availability  
3. **Session Tests** - Zellij session management
4. **Integration Tests** - Shell compatibility and git integration
5. **Security Tests** - Input validation and dangerous command detection
6. **Performance Tests** - Basic timing and speed validation

## Environment Variables

- `ZJ_TEST_MODE=1` - Enable test mode
- `ZJ_DISABLE_AUTO=1` - Disable auto-start
- `TEST_VERBOSE=true` - Detailed output
- `TEST_OUTPUT_DIR` - Results directory
- `ZELLIJ_CONFIG_DIR` - Config directory
- `ZJ_CI_ENV` - Set by test runner (github-actions, docker, native)
- `FORCE_NATIVE=1` - Skip safety warnings for native testing
- `GITHUB_ACTIONS` - Automatically set in GitHub Actions environment

## CI Integration

GitHub Actions uses the native testing approach with intelligent environment handling:

- **Lint and Validation** - Shell syntax and style checking (shellcheck)
- **Quick Tests** - Fast core validation (5 tests)
- **Full Test Suite (bash)** - Comprehensive bash testing (15 tests)  
- **Full Test Suite (zsh)** - Comprehensive zsh testing (15 tests)
- **Security Scan** - Safety and security validation 
- **Compatibility Test** - Installation workflow testing
- **Test Results Summary** - Aggregated results and status reporting

**Automatic Adaptations:**
- TTY-dependent tests skip automatically in CI
- Session tests adapt to environment capabilities  
- Clear status reporting distinguishes skips from failures
- Comprehensive logging for debugging

## Migration from Old System

If you were using the old Docker-only CI:

- ✅ **Local testing**: Now use `./scripts/test-local.sh`
- ✅ **CI testing**: Automatically uses native approach
- ✅ **Same tests**: All test logic is shared between environments
- ✅ **Better debugging**: Interactive shells and clearer output

## Troubleshooting

### Local Docker Issues
```bash
# Rebuild containers
./scripts/test-local.sh --build

# Interactive debugging
./scripts/test-local.sh --shell

# Skip cleanup for inspection
./scripts/test-local.sh --no-cleanup
```

### Native Testing Issues
```bash
# Force specific environment
./tests/run-tests.sh --env native

# Skip safety warnings
FORCE_NATIVE=1 ./tests/run-tests.sh

# Check dependencies
zellij --version
git --version

# Clean test environment
rm -rf test-results/
```

### TTY-Related Issues
**Expected behavior in CI:**
- "Skipping session creation test in GitHub Actions (no TTY available)" - This is normal
- Session creation tests only run in Docker environments with TTY support
- All other functionality tests normally across environments

**Not actual failures:**
- TTY warnings in GitHub Actions
- Session creation test skips
- Environment adaptation messages

### Permission Issues
```bash
# Ensure scripts are executable
chmod +x ./scripts/test-local.sh
chmod +x ./tests/run-tests.sh
```

## Contributing

When adding new tests:

1. Add test logic to `tests/shared/core-tests.sh`
2. Test locally with `./scripts/test-local.sh`
3. Verify CI compatibility with `./tests/run-tests.sh --env github-actions`
4. Update this documentation if needed

The hybrid approach ensures your tests work consistently across all environments.

## CI Status

✅ **Native CI Active**: Fast, reliable GitHub Actions pipeline now fully operational.

**Current Status**: ✅ PASSING (15/15 tests with 1 appropriate skip)
- **Last Updated**: 2025-07-13
- **Key Fixes**: TTY limitation handling, arithmetic operation compatibility
- **Performance**: 5x faster than previous Docker-based CI

### Recent Improvements (2025-07-13)

**Major Fixes Applied:**
- ✅ **Resolved exit code 1 failures** - Fixed arithmetic operations with strict bash mode
- ✅ **Implemented TTY handling** - Smart environment detection prevents false CI failures  
- ✅ **Enhanced session safety** - No interference with user's active zellij sessions
- ✅ **Improved error reporting** - Clear distinction between real failures and environment limitations

**TTY Limitation Handling:**
- Session creation tests automatically skip in GitHub Actions (no TTY available)
- Session listing tests adapt to CI environment while maintaining coverage
- All other tests run normally across environments
- Documentation clearly explains expected behavior

### Environment-Specific Behavior

**GitHub Actions CI:**
- Automatically skips TTY-dependent tests
- Runs 15/16 total tests (1 appropriate skip)
- Provides clear warning messages for skipped tests
- Maintains full test coverage for non-TTY functionality

**Local Docker Testing:**
- Runs all 16 tests including TTY-dependent ones
- Complete session isolation from host system
- Full zellij session creation and management testing
- Recommended for comprehensive local validation

**Native Local Testing:**
- Runs all tests but may interfere with active sessions
- Includes safety warnings and confirmation prompts
- Use `FORCE_NATIVE=1` to skip warnings
- Best for quick validation when no sessions are active