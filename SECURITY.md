# Security Notice

## ⚠️ Keystore Compromise Risk

**Status:** The upload keystore was previously committed to the git repository history.

### The Problem

The following files were committed to git in the past:
- `android/app/upload-keystore.jks`
- `android/keystore.properties`

Even though they are now in `.gitignore`, they remain in the git history and can be accessed by anyone with repository access.

### Impact

If the keystore is compromised:
- An attacker could sign malicious APKs/AABs with your app's signature
- Google Play could flag your app for security issues
- Users could be tricked into installing malicious updates

### Immediate Actions Required

#### Option 1: Create New Keystore (Recommended)

1. **Generate a new upload keystore:**
   ```bash
   cd android/app
   keytool -genkey -v -keystore upload-keystore-new.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias key0 \
     -storepass NEW_PASSWORD \
     -keypass NEW_PASSWORD
   ```

2. **Update `keystore.properties`:**
   ```properties
   storeFile=upload-keystore-new.jks
   storePassword=NEW_PASSWORD
   keyAlias=key0
   keyPassword=NEW_PASSWORD
   ```

3. **Contact Google Play Support** to reset your upload key:
   - Go to Play Console → Help → Contact Support
   - Request upload key reset
   - Provide them with the new certificate fingerprint

4. **Delete old keystore:**
   ```bash
   rm android/app/upload-keystore.jks
   ```

5. **Add new keystore to .gitignore** (already done):
   ```
   android/app/upload-keystore-new.jks
   ```

#### Option 2: Use Google Play App Signing (Best Practice)

If you're using Google Play App Signing (recommended), the upload keystore compromise is less critical because:
- Google holds the actual signing key
- You only use the upload key to submit to Play Store
- You can request a reset from Google

To check if you're using Play App Signing:
1. Go to Play Console → Your App → Setup → App Signing
2. If you see "Google manages your app signing key", you're protected

### Cleaning Git History (Advanced)

To remove the keystore from git history (requires force push - coordinate with team):

```bash
# Using BFG Repo-Cleaner (recommended)
brew install bfg
bfg --delete-files upload-keystore.jks
bfg --delete-files keystore.properties
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Or using git filter-branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch android/app/upload-keystore.jks android/keystore.properties' \
  --prune-empty --tag-name-filter cat -- --all
```

⚠️ **Warning:** This rewrites git history. All collaborators must reclone the repository.

### Prevention

Always keep these in `.gitignore`:
```
**/*.jks
**/*.keystore
keystore.properties
android/app/*.jks
```

Never commit:
- Keystore files (.jks, .keystore)
- Key passwords
- Service account JSON files
- Any signing credentials

### Current Mitigation

The repository now has:
- ✅ Keystore files in `.gitignore`
- ✅ Service account JSON excluded
- ⚠️ Historical commits still contain the old keystore

**Recommendation:** Rotate the keystore ASAP by following Option 1 above.
