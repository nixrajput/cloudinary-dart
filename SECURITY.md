# Security Policy

## Supported versions

| Version | Supported           |
| ------- | ------------------- |
| 2.1.x   | Yes, actively       |
| 2.0.x   | Security fixes only |
| 1.x     | Security fixes only |

## Reporting a vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

### Option 1 - GitHub private advisory (preferred)

Use GitHub's private vulnerability reporting:

[https://github.com/nixrajput/cloudinary-dart/security/advisories/new](https://github.com/nixrajput/cloudinary-dart/security/advisories/new)

### Option 2 - Email

Send a description of the vulnerability to **<nkr.nikhil.nkr@gmail.com>**. Include:

- A clear description of the issue and its potential impact.
- Steps to reproduce or a proof-of-concept.
- Any suggested remediation if you have one.

## Response expectations

| Milestone          | Target                           |
| ------------------ | -------------------------------- |
| Acknowledgement    | Within 72 hours                  |
| Initial assessment | Within 7 days                    |
| Fix or mitigation  | Within 30 days for high-severity |

You will be credited in the release notes unless you prefer to remain anonymous. Thank you for helping keep this project secure.

## Handling your API secret

This package talks to an API that authenticates with a long-lived secret, so how you hold that secret matters more than anything else here.

**Never ship an API secret in a Flutter or web app.** Anyone who downloads the app or opens devtools can read it, and a leaked secret allows deleting every asset in your product environment. `Cloudinary.signed` refuses to construct on a JavaScript runtime unless you pass `allowSecretOnWeb: true`, which exists only for code you are certain never reaches a browser.

For client-side uploads there are two safe options:

1. **An unsigned upload preset**, with `Cloudinary.unsigned`. No credentials are involved at all. Restrict the preset in your Cloudinary settings to the folder, formats and size you actually accept.
2. **A `SignatureProvider`**, which asks your own backend to sign each request. The secret stays on your server, and the client receives only a signature that is useless for anything else.

## What this package does on your behalf

- Signatures use version 2 by default, which escapes `&` inside parameter values so that a value cannot inject additional parameters into the signed string.
- Timestamps are UNIX seconds, sorted by key, matching Cloudinary's algorithm. Golden vectors in `test/golden/` pin this.
- Validation guards throw rather than using `assert`, because Dart removes asserts from release builds and a guard that disappears in production is not a guard.
- The API secret is never placed in a URL, and `CloudinaryConfig.toString()` redacts it.
- Webhook verification compares digests in constant time and rejects payloads older than a configurable window, which limits replay.
- Nothing in `lib/` writes to stdout, so a secret cannot reach your logs through this package.

## Verifying webhooks

Always verify notifications before acting on them, and pass the **raw** request body. Re-encoding a decoded JSON object changes the bytes and the signature will not match.
