# Secret Detection Patterns

## Overview

Scan code and config files for accidentally committed secrets. These regex
patterns catch the most common credential types. Run them as part of
pre-commit hooks or CI checks.

## AWS Credentials

```regex
# AWS Access Key ID (starts with AKIA)
AKIA[0-9A-Z]{16}

# AWS Secret Access Key (40 chars, base64-like)
(?i)aws_secret_access_key\s*[=:]\s*[A-Za-z0-9/+=]{40}

# AWS Session Token
(?i)aws_session_token\s*[=:]\s*[A-Za-z0-9/+=]{100,}
```

### Example Match
```
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## GitHub Tokens

```regex
# GitHub Personal Access Token (classic)
ghp_[A-Za-z0-9_]{36}

# GitHub Fine-Grained Personal Access Token
github_pat_[A-Za-z0-9_]{82}

# GitHub OAuth Access Token
gho_[A-Za-z0-9_]{36}

# GitHub App Installation Token
ghs_[A-Za-z0-9_]{36}

# GitHub App Refresh Token
ghr_[A-Za-z0-9_]{36}
```

## Stripe Keys

```regex
# Stripe Secret Key (live)
sk_live_[A-Za-z0-9]{24,}

# Stripe Secret Key (test)
sk_test_[A-Za-z0-9]{24,}

# Stripe Restricted Key
rk_live_[A-Za-z0-9]{24,}

# Stripe Webhook Secret
whsec_[A-Za-z0-9]{32,}
```

## JWT and Auth Secrets

```regex
# JWT token (three base64 segments separated by dots)
eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}

# Generic secret/key assignment
(?i)(secret|token|password|api_key|apikey|auth)\s*[=:]\s*['"][A-Za-z0-9+/=_-]{16,}['"]

# Bearer token in code
(?i)Bearer\s+[A-Za-z0-9_\-.]{20,}
```

## Generic Password Patterns

```regex
# Password in assignment (various languages)
(?i)(password|passwd|pwd)\s*[=:]\s*['"][^'"]{8,}['"]

# Database connection string with password
(?i)(mysql|postgres|mongodb|redis):\/\/[^:]+:[^@]+@

# Basic auth in URL
https?://[^:]+:[^@]+@[^/]+
```

## .env File Patterns

### Common .env Secrets
```regex
# Any line in .env with secret-looking values
^[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD|CREDENTIAL|AUTH)[A-Z_]*=.+$

# Database URL with credentials
^DATABASE_URL=.*(password|:[^@]+@).*$

# API keys
^[A-Z_]*API[_]?KEY=.+$
```

### Files to Scan
```
.env
.env.local
.env.production
.env.*.local
config/secrets.yml
credentials.json
service-account.json
*.pem
*.key
```

## Cloud Provider Patterns

```regex
# Google Cloud Service Account Key
"type"\s*:\s*"service_account"

# Google API Key
AIza[0-9A-Za-z_-]{35}

# Azure Storage Key
(?i)DefaultEndpointsProtocol=https;AccountName=[^;]+;AccountKey=[A-Za-z0-9+/=]{88}

# Slack Token
xox[bpors]-[A-Za-z0-9-]{10,}

# SendGrid API Key
SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}

# Twilio Account SID + Auth Token
(?i)twilio.*AC[a-z0-9]{32}
```

## Pre-Commit Hook Setup

### Using git-secrets
```bash
# Install
brew install git-secrets  # macOS
# or: git clone https://github.com/awslabs/git-secrets && cd git-secrets && make install

# Configure for AWS patterns
git secrets --register-aws

# Add custom patterns
git secrets --add 'sk_live_[A-Za-z0-9]{24,}'
git secrets --add 'ghp_[A-Za-z0-9_]{36}'

# Install hook
git secrets --install
```

### Using .gitignore
Always ignore secret files:
```gitignore
.env
.env.local
.env.*.local
*.pem
*.key
credentials.json
service-account*.json
```

## False Positive Handling

Some patterns match non-secrets. Common false positives:

| Pattern | False Positive | How to Distinguish |
|---------|---------------|-------------------|
| JWT regex | Example tokens in docs | Check if in .md or test file |
| Password regex | Schema definitions | Check if it's a type definition |
| Generic key regex | Config key names | Check if value is a placeholder |

### Allowlist Format
```
# .secret-scan-allowlist
# Lines starting with # are comments
test/fixtures/example-token.txt
docs/auth-example.md:15
```

## Response When Secret Found

```
1. IMMEDIATELY revoke the exposed credential
2. Rotate to a new credential
3. Remove from git history (git filter-branch or BFG Repo Cleaner)
4. Update .gitignore to prevent recurrence
5. Add pre-commit hook if not already in place
6. Check access logs for unauthorized usage during exposure window
```

Do NOT just delete the file and push a new commit — the secret remains in
git history and is still exposed.
