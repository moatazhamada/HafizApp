# Tech Stack

## Framework & Language

- **Flutter** 3.9.0+ (Dart SDK >=3.9.0 <4.0.0)
- **Material 3** design system with custom theming

## Architecture

**Clean Architecture** with strict layer separation:
- **Domain Layer**: Business logic, entities, use cases, repository interfaces
- **Data Layer**: Repository implementations, data sources (remote/local), models
- **Presentation Layer**: UI, BLoC state management, screens, widgets

## Key Dependencies

### State Management
- `flutter_bloc` (^9.1.1) - BLoC pattern for state management
- `hydrated_bloc` (^10.1.1) - Persistent BLoC state
- `equatable` (^2.0.0) - Value equality for state objects

### Dependency Injection
- `get_it` (^9.2.0) - Service locator pattern (see `lib/injection_container.dart`)

### Networking
- `dio` (^5.0.3) - HTTP client with interceptors
- `connectivity_plus` (^7.0.0) - Network status monitoring

### Local Storage
- `hive` (^2.2.3) + `hive_flutter` (^1.1.0) - Fast key-value storage
- `shared_preferences` (^2.0.15) - Simple persistent storage
- Boxes: `surah_cache`, `bookmarks`, `recitation_errors`, `qiraat_cache`, `audio_cache`

### Firebase Services
- `firebase_core`, `firebase_crashlytics`, `firebase_analytics`, `firebase_performance`
- `cloud_firestore` - Cloud data sync

### Audio
- `just_audio` (^0.10.5) - Audio playback
- `audio_service` (^0.18.15) - Background audio
- `speech_to_text` (^7.0.0) - Voice recognition
- `whisper_ggml_plus` (^1.3.1) - Local speech-to-text

### UI & Assets
- `flutter_svg` (^2.0.9) - SVG rendering
- `cached_network_image` (^3.2.1) - Image caching
- Custom fonts: Poppins (UI), Amiri (Arabic text)

### Testing
- `flutter_test`, `integration_test` - Testing frameworks
- `mocktail` (^1.0.2) - Mocking
- `bloc_test` (^10.0.0) - BLoC testing
- `mockito` (^5.4.4) - Additional mocking

## Common Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run app (debug)
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload: press 'r' in terminal
# Hot restart: press 'R' in terminal
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/quran_index/mushaf_types_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test test/integration/

# Run golden tests
flutter test test/golden/
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Generate code (for build_runner)
dart run build_runner build --delete-conflicting-outputs
```

### Building
```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build for web
flutter build web
```

### Deployment (Fastlane - Android only)
```bash
cd android
bundle install

# Deploy to internal testing
bundle exec fastlane deploy_internal

# Deploy to production
bundle exec fastlane deploy_production
```

## Build Configuration

- **Version**: Managed in `pubspec.yaml` (format: `major.minor.patch+build`)
- **App Icons**: Generated via `flutter_launcher_icons` from `assets/app_icon.png`
- **Signing**: Android keystore at `android/keystore.properties`
- **Firebase**: Platform-specific config files (`google-services.json`, `GoogleService-Info.plist`)

## Asset Management

- Quran text: `assets/quran/uthmani/surah_<1-114>.json`
- Images: `assets/images/`
- Fonts: `assets/fonts/`
- All assets declared in `pubspec.yaml` under `flutter.assets`

## Code Generation

Use `build_runner` for generating code (mocks, JSON serialization if added):
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Logging & Debugging

- Custom `Logger` class wraps Firebase Crashlytics
- Use `Logger.error()`, `Logger.info()` instead of `print()`
- Debug mode: `LogMode.debug`, Production: `LogMode.live`

### Logger Methods
```dart
Logger.debug('Debug info', feature: 'FeatureName');
Logger.info('General info', feature: 'FeatureName');
Logger.warning('Warning', feature: 'FeatureName');
Logger.error('Error', feature: 'FeatureName', error: e, stackTrace: st);
```

## Network Architecture

### Dual API Strategy
- **Primary**: Quran.com API v4 (public, no auth required)
- **Optional**: Quran.Foundation API (OAuth2, requires credentials)
- Configured via `ApiConfig` with environment variables

### Network Manager
- `NetworkManagerImpl` wraps Dio
- Automatic logging in debug mode (PrettyDioLogger)
- Validates all HTTP status codes
- Handles DioException gracefully

### OAuth2 Integration (Optional)
- `QfAuthService` handles token management
- `QfAuthInterceptor` adds Bearer tokens to requests
- Configured via `--dart-define` flags
