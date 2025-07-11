# Local Development and Testing

This document provides instructions for developers and contributors who want to test, modify, or understand the internals of Zellij Utils.

For user-facing documentation, please see the [README.md](README.md).

## 🚀 Quick Start for Development

### Using Docker (Recommended)

The fastest way to get a consistent development and testing environment is by using Docker.

```bash
# Build the Docker image and set up the environment
make dev-setup

# Start an interactive shell inside the container
make docker-shell

# Once inside the shell, you can run tests or validate scripts
bash tests/run_all_tests.sh
make validate
```

### Local Setup

If you prefer to work locally, ensure you have `zellij`, `bash`, `git`, and `shellcheck` installed.

```bash
# Install project dependencies and set up hooks (if any)
make dev-setup

# Run validations and tests
make validate
make lint
make test # Requires zellij to be installed locally
```

## 🐳 Docker Test Environment

This project includes a complete Docker-based testing environment that validates all functionality in a clean, isolated container. This is the primary method for ensuring production readiness and is used by our CI/CD pipeline.

### Test Commands

```bash
# Run all tests in the primary Ubuntu container
make test-docker

# Run tests in a lightweight Alpine Linux container
make test-alpine

# Run with verbose output for debugging
make test-verbose

# Clean the environment and re-run tests
make test-clean

# Build the Docker image without running tests
make docker-build
```

### CI/CD Integration

The project uses GitHub Actions for automated testing with containerized test suites:

- **Multi-Environment Testing**: Tests run in both Ubuntu and Alpine Linux containers
- **Automated Testing**: Triggered on pull requests and pushes to main branch
- **Complete Isolation**: Each test run uses fresh containers with no session interference
- **Comprehensive Reporting**: Detailed test results and artifacts are generated
- **Security Scanning**: Trivy integration for container security validation

The CI pipeline uses the same Docker environment as local development, ensuring consistency between local testing and automated validation.

### Test Categories

The automated test suite validates:

- ✅ **Configuration System** - Loading, validation, and migration.
- ✅ **Session Naming** - Smart naming with git integration and custom patterns.
- ✅ **Core Functionality** - Session management (`zj`, `zjd`, etc.) and layout application.
- ✅ **Security** - Input validation and shell injection prevention.
- ✅ **Performance** - Caching mechanisms and scalability.
- ✅ **Integration** - Installation script and shell compatibility.
- ✅ **Edge Cases** - Filesystem issues, permissions, and error handling.

### Test Results

After running tests, detailed results are generated in `test-results/test_plan_results.md`. This report includes:

- ✅ **Pass/Fail status** for each test category.
- 📊 **Detailed metrics** and performance data.
- 🔍 **Error details** for any failed tests.
- 📈 **Recommendations** for production readiness.

You can view the latest results with:
```bash
make results
```

## 🛠 Development Workflow

### Available Commands

```bash
make help           # Show all available development commands
make status         # Show project status (git, etc.)
make validate       # Validate configuration and scripts for errors
make lint           # Run shellcheck on all scripts
make clean          # Clean up temporary files and build artifacts
```

### Typical Workflow

1.  **Make changes** to scripts, layouts, or configuration.
2.  **Validate** your changes for syntax errors: `make validate`
3.  **Lint** your scripts for style and common issues: `make lint`
4.  **Test** your changes using the Docker environment: `make test-docker`
5.  **Review results** to ensure nothing broke: `make results`
6.  **Commit** your changes with a descriptive message.

## 📁 Project Structure

```
zellij-utils/
├── scripts/               # Core utility scripts
│   ├── zellij-utils.sh   # Main utilities (zj, zjd, etc.)
│   ├── config-loader.sh  # Configuration management
│   ├── config-validator.sh # Validation system
│   ├── config-migration.sh # Migration system
│   └── session-naming.sh # Advanced session naming logic
├── config/               # Default configuration files
│   ├── zellij-utils.conf # Main configuration
│   └── session-naming.conf # Session naming config
├── layouts/              # Zellij layout definitions
├── docker/               # Docker test environment
│   ├── Dockerfile       # Ubuntu test image
│   ├── Dockerfile.alpine # Alpine test image
│   ├── docker-compose.yml # Container orchestration
│   └── run_tests.sh     # Master test runner script
├── tests/                # Test suites (integration, security, etc.)
├── test_plan.md          # Comprehensive test plan document
└── Makefile              # Development and automation commands
```

## 🤝 Contributing

1.  **Fork** the repository.
2.  **Create** a feature branch: `git checkout -b feature/my-new-feature`.
3.  **Implement** your changes, following the development workflow above.
4.  **Ensure** all tests pass: `make test-docker`.
5.  **Submit** a pull request with a clear description of your changes.
