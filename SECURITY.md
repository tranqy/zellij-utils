# Security Policy

## Supported Versions

We actively support the following versions of Zellij Utils:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 1. Do Not Create Public Issues

Please **do not** create public GitHub issues for security vulnerabilities. This could put users at risk.

### 2. Contact Us Privately

Send an email to: **[INSERT SECURITY EMAIL]**

Include the following information:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if you have one)
- Your contact information

### 3. Response Timeline

We aim to respond to security reports within:
- **24 hours**: Initial acknowledgment
- **72 hours**: Preliminary assessment
- **7 days**: Detailed response with timeline

### 4. Disclosure Process

1. **Investigation**: We'll investigate and confirm the vulnerability
2. **Fix Development**: We'll develop and test a fix
3. **Security Advisory**: We'll prepare a security advisory
4. **Coordinated Disclosure**: We'll work with you on disclosure timing
5. **Public Release**: We'll release the fix and advisory

## Security Considerations

### Shell Script Security

Zellij Utils consists of shell scripts that:
- Handle user input and file paths
- Execute system commands
- Manage session data
- Process configuration files

### Common Security Areas

1. **Input Validation**
   - Session names are sanitized
   - File paths are validated
   - Command arguments are properly escaped

2. **Command Injection Prevention**
   - All user input is properly quoted
   - No direct evaluation of user-provided strings
   - Safe parameter expansion techniques

3. **File System Security**
   - Configuration files have appropriate permissions
   - No sensitive data in temporary files
   - Safe handling of symbolic links

4. **Process Security**
   - No unnecessary privilege escalation
   - Secure handling of environment variables
   - Safe subprocess execution

### Security Testing

We maintain comprehensive security tests:
- Input validation tests
- Command injection prevention
- File system security validation
- Process isolation verification

Run security tests with:
```bash
bash tests/security_tests.sh
```

## Security Best Practices for Users

### Installation Security

1. **Verify Source**: Only install from official sources
2. **Review Scripts**: Examine installation scripts before execution
3. **Check Permissions**: Ensure appropriate file permissions
4. **Regular Updates**: Keep Zellij Utils updated

### Configuration Security

1. **Protect Config Files**: Set appropriate permissions on config files
2. **Review Settings**: Understand all configuration options
3. **Limit Scope**: Use least-privilege principles
4. **Monitor Changes**: Track configuration modifications

### Usage Security

1. **Validate Input**: Be cautious with session names and paths
2. **Secure Networks**: Use secure connections for remote sessions
3. **Regular Audits**: Periodically review active sessions
4. **Clean Up**: Remove unused sessions and configurations

## Vulnerability Assessment

### Attack Vectors

Potential security risks include:
- Malicious session names
- Path traversal attempts
- Command injection via parameters
- Configuration file tampering
- Environment variable manipulation

### Mitigation Strategies

We implement multiple layers of protection:
- Input sanitization and validation
- Secure coding practices
- Comprehensive testing
- Regular security audits
- Community review process

## Security Updates

### Notification Methods

Security updates are communicated through:
- GitHub Security Advisories
- Repository releases
- Email notifications (if subscribed)
- Community channels

### Update Process

1. **Automatic Detection**: Monitor for new releases
2. **Review Changes**: Check release notes for security fixes
3. **Test Updates**: Verify compatibility in test environment
4. **Apply Updates**: Install security fixes promptly
5. **Verify Installation**: Confirm successful update

## Responsible Disclosure

We appreciate security researchers who:
- Follow responsible disclosure practices
- Provide clear, detailed reports
- Work with us on fix development
- Respect user privacy and safety

### Recognition

Security contributors may be recognized in:
- Security advisory acknowledgments
- Project documentation
- Community recognition programs

## Contact Information

For security-related questions or concerns:
- **Email**: [INSERT SECURITY EMAIL]
- **Response Time**: Within 24 hours
- **Encryption**: PGP key available on request

---

**Note**: This security policy is a living document and may be updated as the project evolves. Please check for updates regularly.