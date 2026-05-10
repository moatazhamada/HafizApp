# Privacy Policy

**Last updated:** April 25, 2026

**Application:** Hafiz App  
**Contact:** motazhamada@gmail.com  
**Repository:** https://github.com/moatazhamada/HafizApp

## 1. Overview

This Privacy Policy describes how Hafiz App ("the App") collects, uses, and protects your information. By using the App, you agree to the practices described herein.

## 2. Quran Foundation API Integration

Hafiz App integrates with the **Quran Foundation** API ecosystem (api-docs.quran.foundation). When you sign in with your Quran Foundation (Quran.com) account, the App accesses the following APIs on your behalf:

### Content APIs
- **Quran Verses** — fetches verse text, glyph data (`code_v1`/`code_v2`), and page mappings for mushaf rendering
- **Translations** — retrieves Quran translations in multiple languages
- **Tafsir** — loads tafsir (commentary) content for verse study
- **Audio Recitations** — accesses recitation audio files and metadata

### User APIs (requires authentication)
- **Bookmarks** — syncs your bookmarks between the App and your Quran Foundation account
- **Collections** — reads your Quran Foundation bookmark collections

Authentication is performed via OAuth2/OpenID Connect with PKCE. The App requests the minimum necessary scopes (`openid`, `offline_access`, `user`, `collection`). Your access and refresh tokens are stored securely in device keychain/keystore using `flutter_secure_storage`.

### Data Cached from Quran Foundation APIs
- Glyph data (`code_v1`, `code_v2`) is cached in memory only (not persisted)
- Cached content is not retained longer than 1 week
- Quran Foundation data is not used for advertising, profiling, or AI/ML training

## 3. Sensitive Religious Data

We recognize that Quranic text, reading history, memorization progress, and related data are **sensitive religious data**. We treat this information with the utmost care:

- Quran text is **never modified** and is sourced exclusively from verified Tanzil datasets and the Quran Foundation Content API
- Your reading history, bookmarks, and memorization progress are stored locally on your device by default
- Cloud sync via Quran Foundation is **opt-in** — no data is sent to external servers unless you explicitly sign in and enable sync
- We do not combine Quranic engagement data with advertising profiles or behavioral tracking

## 4. Information We Collect

### Locally Stored Data
All of the following are stored **only on your device** using local storage (Hive database and SharedPreferences):

- Bookmarks and favorite verses
- Memorization progress and scores
- Recitation session history and error logs
- Khatmah (reading completion) goals and daily logs
- App settings (font size, theme, orientation, mushaf type, language)
- Last read position per surah

### Cloud Data (Quran Foundation — Opt-in)
When you sign in with your Quran Foundation account:
- Your bookmarks are synced to/from your Quran Foundation account
- Your Quran Foundation user ID is stored locally to maintain the session
- OAuth2 tokens (access, refresh, ID) are stored in the device secure keystore

### Automatically Collected Data
- **Firebase Crashlytics**: Anonymous crash reports to improve app stability
- **Firebase Analytics**: Anonymous usage analytics (screen views, feature usage)
- Neither service collects personally identifiable information

## 5. How We Use Your Data

- To provide Quran reading, memorization, and recitation features
- To sync your bookmarks across devices (when signed in)
- To improve app stability and performance via anonymous analytics
- We **never** sell, share, or rent your personal data to third parties for commercial purposes

## 6. Data Sharing

We do **not** share your personal data except:

- **Quran Foundation**: bookmarks and collections when you are signed in (via encrypted OAuth2 connection)
- **Firebase**: anonymous crash reports and analytics (no personal identifiers)
- **EveryAyah CDN**: ayah-level image requests (no personal data sent — only image URL paths)

## 7. Your Rights

### Delete Your Data

You can delete your data at any time:

1. **Local data**: Clear app data from your device settings, or use the "Clear Cache" option in App Settings
2. **Quran Foundation data**: Use the **"Delete My Data"** button in Settings → Cloud Sync. This will:
   - Revoke your OAuth2 tokens with Quran Foundation
   - Remove your synced bookmarks from Quran Foundation servers
   - Sign you out and clear all local tokens and synced data

### Revoke Access

You can revoke the App's access to your Quran Foundation account at any time by:
- Using the **"Sign Out"** button in Cloud Sync (this also revokes your token)
- Or visiting your Quran.com account settings and removing the App's authorization

### Data Retention

- Local data is retained until you delete it or uninstall the App
- Quran Foundation data is subject to the [Quran Foundation Privacy Policy](https://quran.com/privacy)
- OAuth2 tokens are stored until you sign out or they expire

## 8. Security

- All API communication uses **TLS 1.2+** (HTTPS)
- OAuth2 tokens are stored in the device's **secure keystore** (Keychain on iOS, EncryptedSharedPreferences on Android)
- No passwords are ever stored by the App
- Access tokens have a limited lifetime and are refreshed automatically

## 9. Children's Privacy

The App does not target children under the age of 13. We do not knowingly collect personal information from children under 13. If you are under 13, please do not create an account or sign in.

## 10. International Data Transfers

Quran Foundation servers and Firebase services may be located outside your country. By using the App, you consent to the transfer of data to these services subject to appropriate safeguards.

## 11. Changes to This Policy

We may update this Privacy Policy from time to time. Material changes will be communicated via an in-app notice. The "Last updated" date at the top always reflects the current version.

## 12. Contact

For privacy questions or data deletion requests:
- Email: motazhamada@gmail.com
- GitHub: https://github.com/moatazhamada/HafizApp/issues

## 13. Sub-processors

| Service | Purpose | Policy |
|---------|---------|--------|
| Quran Foundation APIs | Content, authentication, bookmark sync | https://quran.com/privacy |
| Firebase Crashlytics | Anonymous crash reporting | https://firebase.google.com/policies |
| Firebase Analytics | Anonymous usage analytics | https://firebase.google.com/policies |
| EveryAyah CDN | Ayah image delivery | No personal data collected |

## 14. Third-Party Links

The App may contain links to external websites (e.g., Quran.com, QuranReflect). We are not responsible for the privacy practices of third-party sites.
