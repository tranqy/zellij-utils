# Contributing to Zellij Utils

Thank you for your interest in contributing to Zellij Utils! This document provides guidelines and information for contributors.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/tranqy/zellij-utils.git
   cd zellij-utils
   ```
3. **Install dependencies** (see [DEVELOPMENT.md](DEVELOPMENT.md) for detailed setup)

## Development Process

### Before You Start

- Check existing [issues](https://github.com/tranqy/zellij-utils/issues) to see if your idea is already being discussed
- For major changes, please open an issue first to discuss the approach
- Look at the [project roadmap](DEVELOPMENT.md) to understand current priorities

### Making Changes

1. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the project conventions:
   - Follow existing code style and patterns
   - Add appropriate comments for complex logic
   - Update documentation if needed

3. **Test your changes**:
   ```bash
   # Run the full test suite
   bash tests/run_all_tests.sh
   
   # Test installation process
   ./scripts/install.sh
   
   # Manual testing
   source ~/.config/shell/zellij-utils.sh
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

### Commit Message Format

We use conventional commits for clear history:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions/improvements
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

Examples:
```
feat: add interactive session deletion with zjd command
fix: resolve shell escaping issue in session names
docs: update installation instructions for zsh users
test: add comprehensive security validation tests
```

## Code Standards

### Shell Scripting Guidelines

- Use `#!/bin/bash` for bash scripts
- Quote variables: `"$variable"` not `$variable`
- Use `[[ ]]` instead of `[ ]` for conditions
- Add error handling with `set -e` where appropriate
- Use descriptive function names
- Add comments for complex logic

### Documentation

- Update README.md for user-facing changes
- Update DEVELOPMENT.md for developer-facing changes
- Add examples to EXAMPLES.md for new features
- Include inline comments for complex functions

## Testing

All contributions must include appropriate tests:

### Required Tests

- **Integration tests** for new functions
- **Security tests** for input validation
- **Compatibility tests** for shell differences
- **Installation tests** for setup changes

### Running Tests

```bash
# Run all tests
bash tests/run_all_tests.sh

# Run specific test suites
bash tests/integration_tests.sh
bash tests/security_tests.sh
bash tests/compatibility_tests.sh
```

## Pull Request Process

1. **Ensure tests pass** locally
2. **Update documentation** as needed
3. **Create a pull request** with:
   - Clear description of changes
   - Reference to related issues
   - Testing notes
   - Breaking change warnings (if any)

4. **Address review feedback** promptly
5. **Squash commits** if requested before merge

## Types of Contributions

### Bug Reports

- Use the bug report template
- Include reproduction steps
- Provide environment details
- Add relevant logs/screenshots

### Feature Requests

- Use the feature request template
- Explain the use case clearly
- Consider implementation complexity
- Discuss alternatives

### Code Contributions

- Start with smaller changes to understand the codebase
- Focus on one feature/fix per PR
- Follow existing patterns and conventions
- Add comprehensive tests

### Documentation

- Fix typos and improve clarity
- Add examples and use cases
- Update outdated information
- Translate to other languages (future)

## Community Guidelines

- Be respectful and inclusive
- Help newcomers get started
- Share knowledge and experiences
- Follow our [Code of Conduct](CODE_OF_CONDUCT.md)

## Getting Help

- **Issues**: For bugs and feature requests
- **Discussions**: For questions and general discussion
- **Documentation**: Check DEVELOPMENT.md for technical details

## Recognition

Contributors are recognized in:
- Git commit history
- Release notes for significant contributions
- Project documentation

Thank you for contributing to Zellij Utils!