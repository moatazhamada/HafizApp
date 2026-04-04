# HafizApp API Services Guide

## Overview

This document explains all external services used by the HafizApp, their purposes, costs, and alternatives. The app is designed to work **100% offline** for core Quran reading functionality.

---

## 1. fawazahmed0 CDN (Quran Translations)

**What is it?**
A free CDN service hosted on GitHub and distributed via jsDelivr that provides Quran translations in JSON format.

**URL:** `https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@{apiVersion}/{endpoint}`

**Features:**
- 440+ Quran translations
- 90+ languages
- Multiple formats (JSON, CSV, XML, SQL)
- **Completely FREE**
- No rate limits
- No authentication required

**Used for:**
- Alternative source for Quran translations (fallback)
- Fetching translations not bundled in the app

**Status in HafizApp:**
✅ **Currently used as fallback** - Free forever

---

## 2. Quran.Foundation (Quran.com API)

**What is it?**
The official API from the organization behind Quran.com, providing comprehensive Quran data including text, audio, translations, and tafsirs.

**URL:** `https://api-docs.quran.foundation`

**Features:**
- Complete Quran text (Uthmani script)
- 100+ translations
- 30+ audio reciters
- Word-by-word data
- Tafsir collections
- **FREE but requires OAuth2 registration**

**Authentication:**
- Requires `client_id` and `client_secret`
- OAuth2 flow for access tokens
- Tokens expire after 1 hour

**Used for:**
- Primary content API (optional)
- User bookmarks/notes sync (if enabled)
- Advanced features

**Status in HafizApp:**
⚠️ **Optional** - Disabled by default, uses Quran.com v4 (also free) instead

---

## 3. Quran.com API v4

**What is it?**
The public API from Quran.com, providing basic Quran content without authentication.

**URL:** `https://api.quran.com/api/v4`

**Features:**
- Quran chapters and verses
- Translations
- Audio recitations
- **Completely FREE**
- No authentication required for basic endpoints

**Status in HafizApp:**
✅ **Currently used as primary API** - Free forever

---

## 4. Qurani.ai QRC (Quran Recitation Checker)

**What is it?**
An AI-powered service that provides real-time feedback on Quran recitation, detecting tajweed mistakes and pronunciation errors via WebSocket.

**URL:** `https://qurani.ai`

**Features:**
- Real-time recitation checking
- Tajweed mistake detection
- Word-level feedback
- Pronunciation scoring
- **PAID SUBSCRIPTION REQUIRED**

**Pricing:**
- Requires monthly/yearly subscription
- API key provided after subscription
- Not free for any usage tier

**Used for:**
- Advanced recitation coaching
- Real-time tajweed correction

**Status in HafizApp:**
💰 **Optional Premium Feature** - App works 100% without it

### Free Alternatives to QRC:

1. **Local Whisper (Already Implemented)** ✅
   - On-device speech recognition
   - Text matching (not tajweed-aware)
   - Completely private and free
   - Works offline

2. **Tarteel.ai (Open Source Whisper)**
   - Open-source project using Whisper
   - Can be self-hosted
   - GitHub: `tarteel-ai/whisper-base-ar-quran`

3. **Custom Rule Engine (Future Enhancement)**
   - Build tajweed rules locally
   - Pattern matching for common mistakes
   - Phonetic analysis

---

## 5. Other Services

### Firebase (Google)
**Purpose:** Analytics and Crash Reporting
**Cost:** Free tier available (generous limits)
**Offline:** Works without Firebase (app continues normally)

### Deep Links (hafiz.app)
**Purpose:** Share verses via URLs
**Cost:** Domain registration only (~$10/year)
**Status:** Optional feature

---

## Why Does the App Connect to the Internet?

Even though you have full Quran as offline JSONs, the app may connect for:

### **Required (for full functionality):**
1. **Audio Recitations** - Streaming or downloading audio files (can't bundle 30+ reciters)
2. **Voice Recognition** - If using cloud-based ASR (optional, Local Whisper is offline)
3. **QRC Service** - If you enable the premium recitation checker (optional)

### **Optional:**
4. **Analytics** - Firebase (helps improve app, can be disabled)
5. **Deep Links** - Handling shared URLs
6. **Search Enhancements** - Additional search capabilities (app search works offline too)
7. **Qiraat/Editions** - Additional Quran readings (main text is offline)
8. **App Updates** - Checking for new versions

### **100% Offline Features:**
- ✅ Reading Quran text (all 114 surahs)
- ✅ Basic search (via local cache)
- ✅ Bookmarks (stored locally)
- ✅ Mushaf view (all 604 pages)
- ✅ Local Whisper recitation checking
- ✅ Settings and preferences

---

## Cost Summary

| Service | Cost | Required | Alternative |
|---------|------|----------|-------------|
| Quran.com API v4 | **FREE** | No | Local JSON (included) |
| fawazahmed0 CDN | **FREE** | No | Local JSON (included) |
| Quran.Foundation | **FREE** (reg. required) | No | Quran.com v4 |
| **Qurani.ai QRC** | **$$$ PAID** | **No** | Local Whisper (free) |
| Firebase | Free tier | No | Can be disabled |
| Deep Links | $10/year domain | No | Not needed for usage |

**Total cost to run the app: $0** ✅

**Cost for premium features: ~$10-50/month** (QRC subscription)

---

## Recommendation

For a **non-profit, free Quran app**:

1. ✅ **Keep current setup** - Quran.com v4 API + Local JSON
2. ✅ **Use Local Whisper** for recitation checking (free, offline)
3. ⚠️ **Make QRC optional** - Users can subscribe if they want premium features
4. ✅ **Document clearly** - Let users know what's free vs. paid
5. ✅ **Consider self-hosting** - If you need QRC features, consider building a self-hosted alternative using open-source tools

---

## Adding QRC API Key

If users want to use the premium QRC feature, they can:

1. Visit: https://qurani.ai
2. Subscribe to a plan
3. Get their API key
4. Enter it in Settings → Recitation Coach → QRC API Key

**Note:** QRC is an external service. The API key is stored locally on the device and never synced to any server. The recitation checking happens directly between the device and Qurani.ai servers.

---

## Technical Details

### API Configuration

All API keys are configured via environment variables at build time:

```bash
# Optional - for Quran.Foundation (not needed for basic usage)
QF_CLIENT_ID=your_client_id
QF_CLIENT_SECRET=your_client_secret

# Optional - for QRC premium feature
QRC_API_KEY=your_qrc_api_key

# Optional - for Firebase (analytics)
# Configured via google-services.json
```

### Runtime API Key (QRC only)

The QRC API key can be entered at runtime by users in the Settings screen, making it optional and user-controlled.

---

## Privacy Note

- **Local features:** All Quran text, bookmarks, and Local Whisper processing happen on-device
- **QRC feature:** Only sends audio to Qurani.ai when user explicitly enables it
- **Analytics:** Anonymous usage data (can be disabled)
- **No user accounts:** The app doesn't require login or store personal data
