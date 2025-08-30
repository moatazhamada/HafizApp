# Hafiz KMP (Kotlin Multiplatform)

This is an alternative app implementation scaffolded with Kotlin Multiplatform inside `kmp-app/`.

It includes:
- `shared`: Kotlin Multiplatform library (Android + iOS) exposing a simple `Greeting` API.
- `composeApp`: Compose Multiplatform UI module (Android + iOS) with brand theme/colors.
- `androidApp`: Android host app using the Compose UI from `composeApp`.

## Build / Run (Android)

1. Open the `kmp-app/` folder in Android Studio (Giraffe+ recommended).
2. Let Gradle sync complete.
3. Select the `androidApp` run configuration and run on an emulator/device.

## iOS Entry Point

- `composeApp` provides `MainViewController()` in `kmp-app/composeApp/src/iosMain/...` to embed the Compose UI in iOS.
- Build a framework and use it from Xcode:
  - `./gradlew :composeApp:assemble` (builds iOS frameworks)
  - Frameworks in `kmp-app/composeApp/build/` can be linked in a simple SwiftUI/UIKit app:
    ```swift
    import UIKit
    import ComposeApp
    @main
    class AppDelegate: UIResponder, UIApplicationDelegate {
      var window: UIWindow?
      func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        return true
      }
    }
    ```

## Notes
- Kotlin plugin: 2.0.20, Android Gradle Plugin: 8.5.2, Compose Multiplatform: 1.7.0, compileSdk: 34, minSdk: 24.
- The UI theme uses the Flutter brand colors (primary `#006754`, secondary `#87D1A4`) and gradient accents.

## Next Steps (proposed)
- Port core features (models, localization strings, business logic) into `shared`.
- Add networking (Ktor), serialization (kotlinx.serialization), and persistence (SQLDelight) if needed.
- Optionally add a Compose Multiplatform UI module to share UI across Android/iOS/desktop.
