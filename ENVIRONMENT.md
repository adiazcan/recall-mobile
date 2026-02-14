# Environment Configuration Guide

This document explains how to configure the Recall Mobile app using `.env` files.

## Quick Start

1. **Copy the template**:
   ```bash
   cp .env.example .env.dev
   ```

2. **Get your Entra ID credentials** from Azure Portal (see [Getting Entra ID Credentials](#getting-entra-id-credentials) below)

3. **Edit `.env.dev`** with your values:
   ```bash
   nano .env.dev
   ```

4. **Run the app**:
   ```bash
   ./run.sh dev
   ```

## Environment Files

The project supports three environment files:

- **`.env.dev`** - Development environment (local backend, dev Entra app)
- **`.env.staging`** - Staging environment (staging backend and Entra app)
- **`.env.prod`** - Production environment (production backend and Entra app)

Only the template file **`.env.example`** is committed to version control.
The concrete environment files (`.env.dev`, `.env.staging`, `.env.prod`, or any other `.env.*` files) are **local-only secrets** and must be listed in your `.gitignore` (using patterns like `*.env` and `.env*`) so they are never committed.

## Configuration Options

### Required Values

| Variable | Description | Example |
|----------|-------------|---------|
| `ENTRA_CLIENT_ID` | Azure app registration client ID | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` |
| `ENTRA_TENANT_ID` | Azure tenant/directory ID | `12345678-1234-1234-1234-123456789012` |
| `ENTRA_SCOPES` | Space-separated OAuth scopes | `api://recall/Items.ReadWrite User.Read offline_access` |
| `ENTRA_REDIRECT_URI` | Mobile redirect URI | `msauth.com.recall.mobile://auth` |
| `API_BASE_URL` | Backend API base URL | `https://api.recall.com` |
| `OPENAPI_SPEC_URL` | OpenAPI spec endpoint | `https://api.recall.com/openapi.json` |

### Optional Values

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ENV` | Environment name | `dev` |
| `LOG_HTTP` | Enable HTTP request/response logging | `true` (dev), `false` (prod) |

## Getting Entra ID Credentials

### 1. Create App Registration

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID** → **App registrations**
3. Click **New registration**
4. Enter name: `Recall Mobile` (or `Recall Mobile Dev/Staging/Prod`)
5. Select account types (usually Single tenant)
6. Click **Register**

### 2. Get Client ID and Tenant ID

After registration:
- **Application (client) ID** → use as `ENTRA_CLIENT_ID`
- **Directory (tenant) ID** → use as `ENTRA_TENANT_ID`

Copy these to your `.env.dev` file.

### 3. Configure Mobile Redirect URI

1. In your app registration, go to **Authentication**
2. Click **Add a platform** → **Mobile and desktop applications**
3. Add custom redirect URI: `msauth://com.recall.mobile/callback`
4. Enable **Public client flows** if prompted
5. Click **Configure**

### 4. Configure API Permissions

1. Go to **API permissions** → **Add a permission**
2. For Microsoft Graph:
   - Add `User.Read` (read user profile)
   - Add `offline_access` (refresh tokens)
3. For your custom API (if applicable):
   - Click **APIs my organization uses**
   - Search for your Recall API
   - Add scopes like `Items.ReadWrite`, `Items.Read`, etc.
4. Click **Grant admin consent** (if you have admin rights)

### 5. Update Scopes in .env

Based on the permissions you added, update `ENTRA_SCOPES`:
```bash
# For custom API
ENTRA_SCOPES=api://recall/Items.ReadWrite User.Read offline_access

# Or for multiple custom scopes
ENTRA_SCOPES=api://recall/Items.ReadWrite api://recall/Collections.ReadWrite User.Read offline_access
```

## Running with Different Environments

### Development
```bash
./run.sh dev
```
Uses `.env.dev` → runs `lib/main_dev.dart`

### Staging
```bash
./run.sh staging
```
Uses `.env.staging` → runs `lib/main_staging.dart`

### Production
```bash
./run.sh prod
```
Uses `.env.prod` → runs `lib/main_prod.dart`

### Passing Additional Flutter Arguments

You can pass additional Flutter arguments after the environment:

```bash
# Run on specific device
./run.sh dev -d <device-id>

# Run in release mode
./run.sh staging --release

# Run with additional dart defines (will override .env values)
./run.sh dev --dart-define=LOG_HTTP=false
```

## Troubleshooting

### "Environment file not found"

Make sure you've created the `.env.<environment>` file:
```bash
cp .env.example .env.dev
```

### "AADSTS50011: The redirect URI doesn't match"

The redirect URI in your `.env` file must exactly match what's configured in Azure Portal → Authentication.

Verify:
- `.env` has: `ENTRA_REDIRECT_URI=msauth://com.recall.mobile/callback`
- Azure Portal → Authentication → Platform configurations → Mobile includes the same URI

### "Application not found" or "Invalid client"

Double-check your `ENTRA_CLIENT_ID` matches the Application (client) ID in Azure Portal.

### Silent token refresh fails

Ensure:
1. `offline_access` is included in `ENTRA_SCOPES`
2. Admin consent has been granted (if required by your tenant)

## Security Best Practices

✅ **DO**:
- Keep `.env.*` files in `.gitignore` (already configured)
- Use separate app registrations for dev/staging/prod
- Store production credentials securely (password manager, Azure Key Vault)
- Rotate credentials periodically

❌ **DON'T**:
- Commit `.env.*` files to Git
- Share credentials in Slack, email, or other chat tools
- Use production credentials in dev/staging environments
- Hard-code credentials in source files

## Team Setup

For team members:
1. Share the `.env.example` file (committed to Git)
2. Each developer creates their own `.env.dev` with personal dev credentials
3. Store shared staging/prod credentials in a secure location (e.g., 1Password, Azure Key Vault)
4. Document the secure credential location in team wiki/docs

## CI/CD Integration

For automated builds, set environment variables as secrets in your CI/CD platform:

### GitHub Actions
```yaml
env:
  ENTRA_CLIENT_ID: ${{ secrets.ENTRA_CLIENT_ID }}
  ENTRA_TENANT_ID: ${{ secrets.ENTRA_TENANT_ID }}
  # ... other secrets
```

### GitLab CI
```yaml
variables:
  ENTRA_CLIENT_ID: $CI_ENTRA_CLIENT_ID
  ENTRA_TENANT_ID: $CI_ENTRA_TENANT_ID
```

The `run.sh` script can be adapted for CI by reading from environment variables instead of `.env` files when they're not present.
