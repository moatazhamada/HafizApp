# Security Information

## Repository Status

**This repository is PRIVATE.**

## Keystore Storage

The upload keystore is stored locally in the repository:
- `android/app/upload-keystore.jks`
- `android/keystore.properties`

These files are excluded from git tracking (see `.gitignore`).

### Why This is Acceptable

1. **Google Play App Signing is enabled** - Google holds the actual app signing key
2. **Repository is PRIVATE** - Only authorized collaborators have access
3. **Upload key only** - Even if compromised, Google can reset it

### For Collaborators

When working on this project:

1. **Don't commit keystore files** - They're already in `.gitignore`
2. **Don't share keystore passwords** - Keep them secure
3. **Don't share service account JSON** - Required for deployment

### If You Need to Share the Project

If you need to share this project publicly:

1. **Generate a new upload keystore** (don't use the existing one)
2. **Use environment variables** for CI/CD instead of committed files
3. **Contact Google Play Support** to reset the upload key

## Deployment Security

For CI/CD deployment, use GitHub Secrets:
- `KEYSTORE_BASE64` - Base64 encoded keystore
- `KEYSTORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password
- `KEY_ALIAS` - Key alias
- `GOOGLE_PLAY_SERVICE_ACCOUNT` - Service account JSON

See `.github/workflows/deploy.yml` for details.
