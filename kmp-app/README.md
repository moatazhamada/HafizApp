# Hafiz KMP (Kotlin Multiplatform)

This is an alternative app implementation scaffolded with Kotlin Multiplatform inside `kmp-app/`.

It includes:
- `shared`: Kotlin Multiplatform library (Android + iOS) exposing a simple `Greeting` API.
- `androidApp`: Android app that consumes the `shared` module.

## Build / Run (Android)

1. Open the `kmp-app/` folder in Android Studio (Giraffe+ recommended).
2. Let Gradle sync complete.
3. Select the `androidApp` run configuration and run on an emulator/device.

## Using the shared module from iOS

The `shared` module is configured for iOS targets (`iosX64`, `iosArm64`, `iosSimulatorArm64`).
To integrate with a native iOS app:
- Create an Xcode project and add the `shared` module as a framework built via Gradle.
- Typical commands:
  - `./gradlew :shared:assemble` (builds all targets)
  - Artifacts are generated under `kmp-app/shared/build`.

You can then call `Greeting().greet()` from Swift/Objective‑C via the framework API.

## Notes
- Kotlin plugin: 2.0.20, Android Gradle Plugin: 8.5.2, compileSdk: 34, minSdk: 24.
- This is a minimal scaffold. We can expand the shared module to include actual domain/data logic from the Flutter app, and optionally add Compose Multiplatform UI shared across platforms if desired.

## Next Steps (proposed)
- Port core features (models, localization strings, business logic) into `shared`.
- Add networking (Ktor), serialization (kotlinx.serialization), and persistence (SQLDelight) if needed.
- Optionally add a Compose Multiplatform UI module to share UI across Android/iOS/desktop.
