# Fastlane Setup for Hafiz App

This directory contains Fastlane configuration for automated Play Store deployments.

## Repository Status

This is a **PRIVATE** repository. The keystore is stored locally and excluded from git.

## Keystore Location

The signing keystore is stored at:
- **Keystore:** `android/app/upload-keystore.jks`
- **Config:** `android/keystore.properties`

These files are in `.gitignore` and won't be committed.

## Prerequisites

1. **Install Ruby dependencies:**
   ```bash
   cd android
   bundle install
   ```

2. **Set up Google Play Service Account:**
   - Go to Google Play Console → Settings → API Access
   - Create a service account and download the JSON key
   - Save it as `android/fastlane/service-account.json`:
     ```bash
     cp /path/to/downloaded-service-account.json android/fastlane/service-account.json
     ```

## Available Lanes

### Local Development

```bash
# Run tests
bundle exec fastlane test

# Build APK for testing
bundle exec fastlane build_apk

# Build AAB for Play Store
bundle exec fastlane build_aab

# Bump version code
bundle exec fastlane bump_version
```

### Deployment

```bash
# Deploy to Internal Testing
bundle exec fastlane deploy_internal

# Deploy to Beta (Closed Testing)
bundle exec fastlane deploy_beta

# Deploy to Production (requires confirmation)
bundle exec fastlane deploy_production

# Promote Internal to Production
bundle exec fastlane promote_to_production
```

### Full CI/CD Pipeline

```bash
# Test, bump version, and deploy to Internal
bundle exec fastlane ci_internal

# Test, bump version, and deploy to Production
bundle exec fastlane ci_production
```

## Environment Variables

For CI/CD, set these GitHub Secrets:

| Variable | Description |
|----------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Base64-encoded service account JSON |

To encode files:
```bash
base64 -i android/app/upload-keystore.jks
base64 -i /path/to/service-account.json
```

## Play Store Metadata

Edit these files to update Play Store listing:

- `metadata/android/en-US/title.txt` - App title
- `metadata/android/en-US/short_description.txt` - Short description (80 chars)
- `metadata/android/en-US/full_description.txt` - Full description
- `metadata/android/en-US/changelogs/default.txt` - Default changelog

## Security Notes

- Never commit `service-account.json` or `upload-keystore.jks` to git
- Keep your keystore file backed up securely
- The service account JSON has access to your Play Store - protect it carefully
- This is a private repository - do not make it public without rotating keys
