# Hafiz Kotlin Multiplatform App (This branch)

This branch promotes the Kotlin Multiplatform (KMP) implementation as the main app. The previous Flutter app was removed on this branch to focus on a shared Kotlin codebase and Compose Multiplatform UI.

Modules:
- `shared`: Kotlin Multiplatform shared logic (Android + iOS)
- `composeApp`: Compose Multiplatform UI (Android + iOS), includes onboarding, home, surah list and reader
- `androidApp`: Android host app using the Compose UI and bundling Quran JSON assets

Run (Android):
- Open the repository root in Android Studio, sync Gradle, run `androidApp`.

iOS entry point:
- `composeApp/src/iosMain/.../MainViewController.kt` exposes `MainViewController()` to embed Compose UI in a UIKit/SwiftUI app. Build frameworks with `./gradlew :composeApp:assemble` and use in Xcode.

Assets:
- Quran JSON lives in `androidApp/src/main/assets/quran/uthmani/` and mirrors the original `assets/quran/uthmani` content.

Notes:
- Kotlin: 2.0.20, AGP: 8.5.2, Compose Multiplatform: 1.7.0, compileSdk: 34, minSdk: 24.

See also `KMP_README.md` for more details.
