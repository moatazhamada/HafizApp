# HafizApp — API Integration Map

> **For Quran Foundation Hackathon Judges** — Complete map of all QF APIs used in HafizApp

---

## Content APIs (Quran.com v4 + Quran Foundation)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CONTENT API CALLS                            │
├──────────────────────┬──────────────────────────────────────────────┤
│ Endpoint             │ Feature                                    │
├──────────────────────┼──────────────────────────────────────────────┤
│ /verses/by_chapter   │ Surah text loading (Uthmani + words)        │
│ /verses/by_key       │ Single verse lookup (voice verify, tafsir)  │
│ /verses/by_page      │ Mushaf 604-page glyph rendering (code_v2)  │
│ /verses/random       │ Home screen daily verse widget              │
│ /tafsirs/169/...     │ Ibn Kathir tafsir per-ayah & per-surah     │
│ /translations/85/... │ Abdel Haleem translation per-surah          │
│ /resources/...       │ Reciter listings for audio player           │
│ /chapter_recitations │ Audio with word-level timing segments       │
└──────────────────────┴──────────────────────────────────────────────┘
```

## User APIs (Quran Foundation Auth v1)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER API CALLS                             │
├────────────────────────┬────────────────────────────────────────────┤
│ Endpoint               │ Feature                                  │
├────────────────────────┼────────────────────────────────────────────┤
│ POST /activity-days    │ Record daily reading activity             │
│ GET  /activity-days    │ Retrieve activity history                 │
│ GET  /streaks/current  │ Cloud streak reconciliation               │
│ GET  /streaks          │ Streak history for visualization          │
│ POST /goals            │ Create reading/memorization goals         │
│ PUT  /goals/{id}       │ Update goal progress                     │
│ DELETE /goals/{id}     │ Remove goals                             │
│ GET  /goals/plan       │ Today's personalized reading plan         │
│ GET  /goals/estimate   │ Goal completion timeline estimation       │
│ POST /reading-sessions │ Record each reading session               │
│ GET  /reading-sessions │ Session history                          │
│ GET  /bookmarks        │ Pull cloud bookmarks                      │
│ POST /bookmarks        │ Push local bookmarks to cloud             │
│ DELETE /bookmarks/{id} │ Remove bookmark                          │
│ GET  /collections      │ List bookmark collections                 │
│ POST /collections      │ Create "Hafiz Bookmarks" collection       │
│ POST /posts            │ Create verse reflection                   │
│ GET  /posts            │ Get reflections for a verse               │
│ DELETE /posts/{id}     │ Delete a reflection                       │
│ GET  /search?q=...     │ Semantic verse search                     │
└────────────────────────┴────────────────────────────────────────────┘
```

## Authentication (OAuth2 PKCE)

```
┌─────────────────────────────────────────────────────────────────────┐
│                       AUTH FLOW                                     │
│                                                                     │
│  App ──PKCE authorize──▶ oauth2.quran.foundation/oauth2/auth       │
│   ▲                           │                                     │
│   │                      redirect URI                               │
│   │                           ▼                                     │
│   └─────code exchange─────────┘                                     │
│                                                                     │
│  Dio Interceptors:                                                  │
│  • QfAuthInterceptor — machine-to-machine (client_credentials)      │
│  • QfApiInterceptor  — user auth + automatic 401 retry + refresh   │
│  • Token revoke for "Delete My Data" compliance                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Additional Content Sources

| Source | API | Purpose |
|--------|-----|---------|
| QuranHub | `api.quranhub.com/v1` | Qiraat editions (Hafs, Warsh, Qaloon) |
| Qurani.ai | `wss://api.qurani.ai` | Real-time recitation verification via QRC |
| EveryAyah CDN | `everyayah.com/data/images_png/` | Ayah images for mushaf rendering mode |
| Tanzil (local) | `assets/quran/uthmani/surah_*.json` | Offline Uthmani text (always available) |

---

## API Count Summary

| Category | Endpoints |
|----------|-----------|
| Content API (Quran.com v4) | 8 |
| User API (QF Auth v1) | 20 |
| OAuth2 | 3 |
| External Content | 3 |
| **Total** | **34** |
