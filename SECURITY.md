# Security

Please use GitHub's **Security → Report a vulnerability** for sensitive reports once private vulnerability reporting is enabled. Do not post credentials, activity databases, exports or personal data in public issues. If private reporting is unavailable, open a minimal issue requesting a private contact channel without vulnerability details.

This is an early developer preview. A Developer ID signed and notarized release is not yet available. No authentication tokens or provider account integrations are used by this application.

The optional feedback endpoint accepts a strict field allowlist, caps request size, uses parameter-bound writes, rate limits submissions and has no public read API. Its random submission IDs are not authentication credentials. Rate limiting reduces casual abuse; it is not identity verification. Operators should monitor service quotas and may need additional abuse controls at larger scale.
