# Fastlane Setup for Hafiz App

This directory contains Fastlane configuration for automated Play Store deployments.

## ✅ Keystore Already Configured

The signing keystore is already included in the repository:
- Keystore: `android/app/upload-keystore.jks`
- Config: `android/keystore.properties`

No manual keystore setup needed! 🔒

## Prerequisites

1. **Install Ruby dependencies:**
   ```bash
   cd android
   bundle install
   ```

2. **Set up Google Play Service Account (Required for deployment):**
   - Go to Google Play Console → Settings → API Access
   - Create a service account and download the JSON key
   - Save it as `android/fastlane/service-account.json`

   ```bash
   # Place the service account JSON
   cp /path/to/downloaded-service-account.json android/fastlane/service-account.json
   ```

   ⚠️ **Note:** The service account JSON is NOT committed to git (see `.gitignore`).

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

For CI/CD, set these secrets:

| Variable | Description |
|----------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |
| `GOOGLE_PLAY_SERVICE_ACCOUNT` | Base64-encoded service account JSON |

## GitHub Actions

The `.github/workflows/deploy.yml` file configures automatic deployment:

- **Pushes to `feature/sheikh-recitation-coach`**: Deploys to Internal Testing
- **Tags starting with `v`**: Deploys to Production (requires manual approval)
- **Pull requests**: Runs tests only

## Play Store Metadata

Edit these files to update Play Store listing:

- `metadata/android/en-US/title.txt` - App title
- `metadata/android/en-US/short_description.txt` - Short description (80 chars)
- `metadata/android/en-US/full_description.txt` - Full description
- `metadata/android/en-US/changelogs/default.txt` - Default changelog

## Security Notes

- Never commit `service-account.json` or `keystore.jks` to git
- Keep your keystore file backed up securely
- The service account JSON has access to your Play Store - protect it carefully
