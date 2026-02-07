# Hafiz Flutter App

![image](https://github.com/abualgait/HafizApp/assets/38107393/aaa45a94-030c-40fc-afb6-108bd43f8742)


🚀 **Embark on a Flutter Journey with Holy Quran App 📖**

Dive into the world of Flutter with our Hafiz app – a meticulously crafted learning journey that encapsulates essential Flutter concepts. 🌟

**Google Play:** https://play.google.com/store/apps/details?id=com.hafiz.app.hafiz_app&hl=en_US

🛠 **Tech Stack Highlights:**
1. **Clean Architecture:** We've architectured the app for clarity, separation of concerns, and maintainability. Clean code is at the heart of our design, ensuring scalability and ease of collaboration.

2. **App Theme Styling:** Immerse yourself in a visually appealing app theme that not only enhances the user experience but also demonstrates the power of Flutter's theming capabilities.

3. **Localization Magic:** Explore the beauty of multilingual support with our app's localization feature. Providing a seamless experience for users worldwide, we've harnessed the power of Flutter to make the Quran accessible in multiple languages.

4. **Dio Integration:** Witness the power of network requests with Dio integration. Our app leverages Dio for efficient and robust API interactions, ensuring a smooth and responsive experience.

5. **Bloc State Management:** Delve into the world of BLoC (Business Logic Component) for clean and efficient state management. Experience the power of reactive programming to streamline your app's logic.

6. **Navigation Mastery:** Navigate effortlessly through the app using Flutter's navigation system. Enjoy a smooth and intuitive user experience as you traverse through different screens.

7. **SharedPreferences Magic:** Store and retrieve data persistently with SharedPreferences. Our app leverages this powerful tool for efficient local data storage, enhancing the user experience.

8. **GetIt Dependency Injection:** Experience the simplicity and power of dependency injection with GetIt. Our app utilizes GetIt for efficient management of dependencies, ensuring modularity and testability.

9. **Unit testing:** with mocktail, flutter_test and bloc_test.

Figma file: https://www.figma.com/community/file/1237733090712918938/quran-mobile-app


🌐 **Sharing the Flutter Love:**
This Quran app is not just an app – it's a learning journey! 🚀 I have crafted it to serve as a starter template for Flutter enthusiasts, enabling them to explore and understand the core concepts of Flutter development.

Let's Flutter together and create remarkable experiences! 🚀✨

## Acknowledgements

- Original idea and initial project by: https://github.com/abualgait
- Source repository: https://github.com/abualgait/HafizApp

This build includes small fixes and updates by the current maintainer. The app is non‑profit and intended as a good deed for us and our families.

## Quran Text Source & Integrity

- The Arabic Quran text is bundled locally in the app to avoid tampering and to work fully offline.
- Local files live under `assets/quran/uthmani/` as per‑surah JSON: `surah_<1..114>.json`.
- Each file uses this schema:

```json
{
  "chapter": [
    {"chapter": 1, "verse": 1, "text": "..."},
    {"chapter": 1, "verse": 2, "text": "..."}
  ]
}
```

- A remote fallback (Quran.com API v4) is only used if a local file is missing.

### Preparing Local Assets (Tanzil)

1. Download the verified Uthmani text from Tanzil: https://tanzil.net/download/
   - e.g., `quran-uthmani.txt` where each line is `SURA|AYA|TEXT` (e.g., `1|1|بِسْمِ اللَّهِ ...`).
2. Generate per‑surah JSON files:
   - `dart run tool/generate_quran_assets.dart /path/to/quran-uthmani.txt assets/quran/uthmani`
3. Ensure `pubspec.yaml` includes the `assets/` directory (already configured).

Note: Tanzil’s license is CC BY‑ND 3.0. Do not modify the Quran text. Include attribution when distributing.

## About Screen

An in‑app About page includes acknowledgements and intent. You can find it via the info icon on the Home screen.

---

## 🚀 Automated Deployment (Fastlane)

This project uses **Fastlane** for automated Play Store deployments.

### Quick Start

```bash
cd android
bundle install

# Deploy to Internal Testing
bundle exec fastlane deploy_internal

# Deploy to Production
bundle exec fastlane deploy_production
```

### Setup

1. **Install dependencies:**
   ```bash
   cd android
   bundle install
   ```

2. **Set up Google Play Service Account (one-time):**
   - Go to Google Play Console → Settings → API Access
   - Create a service account and download the JSON key
   - Save as `android/fastlane/service-account.json`:
     ```bash
     cp /path/to/downloaded-service-account.json android/fastlane/service-account.json
     ```

**Note:** This is a private repository. See [SECURITY.md](./SECURITY.md) for collaboration guidelines.

### GitHub Actions CI/CD

Automatic deployments on push:
- `feature/sheikh-recitation-coach` → Internal Testing
- Tags `v*` → Production (requires approval)

See `android/fastlane/README.md` for detailed documentation.

---

## 🚧 Upcoming Features (Roadmap)

### 🎯 In Progress (Current Branch)
- ✅ **Crash Fixes**: BuildContext stability improvements in voice verification
- ✅ **Juz (Para) Index**: Quick navigation to any of the 30 Juz
- ✅ **UI Polish**: Edge-to-edge support for Android 15+

### 🌟 Planned Features

#### 1. **Full Quran Mushaf View** (Next Major Feature)
A seamless, continuous Mushaf experience that mimics reading from a physical Quran:
- All 114 Surahs in one continuous scrollable view
- Exact Mushaf page numbers (Madani/Uthmani script pagination)
- Page flip animations with realistic curl effect
- Visual Surah dividers with ornate Islamic headers
- Bookmarking specific "pages" rather than just verses
- Jump to any Mushaf page number (1-604)

#### 2. **Audio Recitation Player**
- Full Surah audio playback with verse highlighting
- Background audio support with notification controls  
- Download audio for offline listening
- Variable playback speed (0.5x - 2x)
- Loop specific verse ranges for memorization
- Sleep timer for bedtime listening

#### 3. **Deep Linking & Sharing**
- Share any verse with a unique link (e.g., `hafiz.app/surah/2/verse/255`)
- Links open directly to the specific verse in the app
- Generate beautiful verse images for social sharing
- Copy verse text with proper attribution

#### 4. **Daily Reading Goals (Khatmah Tracker)**
- Set daily pages/verses targets
- Track progress toward completing the Quran
- Reading streak calendar with reminders
- Multiple simultaneous Khatmah tracking
- Group reading challenges

#### 5. **Tafsir Integration**
- Multiple Tafsir sources (Ibn Kathir, Jalalayn, etc.)
- Side-by-side or bottom sheet display
- Download Tafsir for offline reading
- Bookmark Tafsir explanations

#### 6. **Advanced Memorization Tools**
- Recording comparison: Record yourself vs. reciter
- Spaced repetition system for verse review
- Memorization planner with scheduling
- Difficulty tracking per verse
- Audio repeat with customizable delays

#### 7. **Widgets & Quick Actions**
- Home screen widget: Daily verse
- Progress widget: Reading streak and goals
- Quick action: Jump to last read position

#### 8. **Search Enhancements**
- Search by topic/keyword across all verses
- Advanced search filters (Surah range, Juz, etc.)
- Search history and suggestions
- Voice search

---

*Want to contribute? Pick a feature from the roadmap and open a PR!*

