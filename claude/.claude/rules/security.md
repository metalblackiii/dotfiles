# Security

These rules apply to all code generation.

## Data Protection
- Never output real PII (names, emails, SSNs, phone numbers) in examples
- Use placeholder data like `john.doe@example.com` or `555-0100`
- Never hardcode credentials, API keys, or secrets in code
- Always use environment variables or secret management for sensitive data

## Input Validation
- Sanitize all user inputs before processing
- Use parameterized queries for database operations - never string concatenation
- Validate and escape data before rendering in HTML to prevent XSS
- Implement proper CSRF protection for state-changing operations

## Authentication & Authorization
- Never store passwords in plain text - use proper hashing (bcrypt, Argon2)
- Implement proper session management with secure, httpOnly cookies
- Always verify authorization on the server side, never trust client-side checks
- Use principle of least privilege for all access controls

## Secure Defaults
- Enable HTTPS/TLS for all communications
- Set secure headers (HSTS, CSP, X-Frame-Options)
- Disable verbose error messages in production
- Log security events but never log sensitive data

## Code Review Considerations
- Flag any code that handles authentication, authorization, or sensitive data
- Highlight potential injection vulnerabilities
- Ensure error handling doesn't leak implementation details
