# Project Structure

## Root Directory Layout

```
hafiz_app/
├── lib/                    # Application source code
├── test/                   # Test files (mirrors lib/ structure)
├── assets/                 # Static assets (images, fonts, Quran data)
├── android/                # Android platform code
├── ios/                    # iOS platform code
├── web/                    # Web platform code
├── linux/                  # Linux platform code
├── macos/                  # macOS platform code
├── windows/                # Windows platform code
├── .kiro/                  # Kiro AI assistant configuration
└── pubspec.yaml            # Dependencies and project metadata
```

## lib/ Structure (Clean Architecture)

### Core Layer (`lib/core/`)
Shared utilities, constants, and cross-cutting concerns:
- `analytics/` - Firebase Analytics integration
- `audio/` - Audio playback handler
- `config/` - API configuration
- `deep_link/` - Deep linking service
- `errors/` - Error handling and exceptions
- `i18n/` - Internationalization utilities
- `network/` - Network manager, connectivity checks
- `qiraat/` - Qiraat (recitation styles) logic
- `quran_index/` - Quran structure (surahs, pages, verses)
- `scroll/` - Scroll position management
- `usecase/` - Base use case classes
- `utils/` - General utilities (date, size, theme, preferences)
- `app_export.dart` - Barrel file for common exports

### Domain Layer (`lib/domain/`)
Business logic and contracts (framework-agnostic):
- `entities/` - Business objects (Surah, Verse, Bookmark, etc.)
- `repository/` - Repository interfaces (contracts)
- `usecase/` - Use case implementations (business rules)

### Data Layer (`lib/data/`)
Data access and repository implementations:
- `datasource/` - Data sources (remote API, local Hive/SharedPreferences)
  - `surah/` - Surah data sources
  - `bookmark/` - Bookmark data sources
  - `recitation_error/` - Recitation error data sources
- `model/` - Data transfer objects (DTOs) with JSON serialization
- `repository/` - Repository implementations (implements domain interfaces)

### Presentation Layer (`lib/presentation/`)
UI components organized by feature:
- Each screen has its own folder with:
  - `bloc/` - BLoC state management (events, states, bloc)
  - `widgets/` - Screen-specific widgets
  - `<screen_name>_screen.dart` - Main screen widget
- Feature folders:
  - `home_screen/` - Home/Surah list
  - `surah_screen/` - Surah reading view
  - `mushaf_screen/` - Mushaf (page-based) view
  - `audio_player/` - Audio playback UI
  - `bookmarks/` - Bookmarks management
  - `search/` - Quran search
  - `recitation_error/` - Voice verification errors
  - `settings_screen/` - App settings
  - `onboarding_screen/` - First-run onboarding
  - `about_screen/` - About/acknowledgements
  - `help_screen/` - Help documentation

### Supporting Directories
- `lib/localization/` - Localization files (en_us, ar_eg)
- `lib/routes/` - Navigation routes and arguments
- `lib/theme/` - Theme BLoC and styling
- `lib/widgets/` - Shared/reusable widgets
- `lib/injection_container.dart` - Dependency injection setup (GetIt)
- `lib/main.dart` - App entry point

## test/ Structure

Mirrors `lib/` structure with additional categories:
- `test/core/` - Unit tests for core utilities
- `test/domain/` - Unit tests for use cases
- `test/data/` - Unit tests for repositories and data sources
- `test/presentation/` - Widget tests for UI components
- `test/integration/` - Integration tests for user flows
- `test/golden/` - Golden file tests for visual regression
- `test/fixture/` - Test fixtures and mock data

## assets/ Structure

```
assets/
├── quran/
│   ├── uthmani/              # Quran text (surah_1.json to surah_114.json)
│   └── mushaf_page_index.json # Page-to-verse mapping
├── images/                   # SVG and PNG images
├── fonts/                    # Custom fonts (Poppins, Amiri)
└── app_icon.png              # App launcher icon
```

## Naming Conventions

### Files
- Dart files: `snake_case.dart`
- Screens: `<feature>_screen.dart`
- Widgets: `<widget_name>.dart`
- BLoCs: `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`
- Repositories: `<entity>_repository.dart` (interface), `<entity>_repository_impl.dart` (implementation)
- Data sources: `<entity>_remote_data_source.dart`, `<entity>_local_data_source.dart`

### Classes
- Classes: `PascalCase`
- BLoCs: `<Feature>Bloc`
- Events: `<Action><Feature>Event`
- States: `<Status><Feature>State`
- Widgets: `<Purpose>Widget` or descriptive name

### Variables & Functions
- Variables: `camelCase`
- Constants: `camelCase` (not SCREAMING_SNAKE_CASE)
- Private members: `_leadingUnderscore`
- Functions: `camelCase`

## Dependency Flow

```
Presentation → Domain → Data
     ↓           ↓        ↓
   BLoC    →  UseCase → Repository → DataSource
```

**Rules:**
- Presentation depends on Domain (not Data)
- Domain is independent (no Flutter imports)
- Data implements Domain interfaces
- Use dependency injection (GetIt) to wire layers

## Feature Organization Pattern

When adding a new feature:
1. Create entity in `domain/entities/`
2. Create repository interface in `domain/repository/`
3. Create use case in `domain/usecase/`
4. Implement data source in `data/datasource/`
5. Implement repository in `data/repository/`
6. Create BLoC in `presentation/<feature>/bloc/`
7. Create screen in `presentation/<feature>/`
8. Register dependencies in `injection_container.dart`
9. Add route in `routes/app_routes.dart`
10. Write tests in `test/` mirroring the structure

## Import Conventions

- Use relative imports within the same layer
- Use `package:hafiz_app/` imports across layers
- Use `core/app_export.dart` for common core imports
- Avoid circular dependencies
