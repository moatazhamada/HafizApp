# HafizApp Architecture

## Layer Diagram

```
┌─────────────────────────────────────────────┐
│  Presentation Layer (UI + State Management) │
│  lib/presentation/                          │
│  - Screens, BLoCs, Widgets                  │
│  - Uses BLoC pattern                        │
├─────────────────────────────────────────────┤
│  Domain Layer (Business Logic)              │
│  lib/domain/                                │
│  - Entities, Repository Interfaces,         │
│    Use Cases                                │
│  - Pure Dart, no Flutter dependency         │
├─────────────────────────────────────────────┤
│  Data Layer (External Access)               │
│  lib/data/                                  │
│  - Data Sources, Models,                    │
│    Repository Implementations               │
│  - Dio, Hive, Local JSON                    │
├─────────────────────────────────────────────┤
│  Core Layer (Shared Utilities)              │
│  lib/core/                                  │
│  - Config, Theme, Network, Utils            │
└─────────────────────────────────────────────┘
```

## Data Flow

```
UI (Widget) → Event → BLoC → UseCase → Repository (interface)
                                              ↓
                              RepositoryImpl → DataSource → API/Local
                                              ↓
                              Either<Failure, Data> ← DataSource
                                              ↓
                              State ← BLoC ← UseCase ← Repository
                                              ↓
                              UI rebuilds via BlocBuilder
```

### Pattern: Either<Failure, Success>

- **Left(Failure)**: Error path (ServerFailure, ConnectionFailure, CacheFailure)
- **Right(Data)**: Success path with typed data
- Repositories return `Future<Either<Failure, T>>`
- BLoCs map failures to appropriate error states

## Dependency Injection (GetIt)

```
lib/injection_container.dart    → sl (GetIt instance)
  ├── di/di_core.dart           → Dio, NetworkInfo, ThemeBloc, QfAuthBloc
  ├── di/di_qf.dart             → QF data sources (Activity, Goals, Search,
  │                                Tafsir, Translation, VerseStudy, Post, Mushaf)
  └── di/di_features.dart       → Repositories, Use Cases, BLoCs, Local Data Sources
```

### Registration Types
- `registerLazySingleton`: Created on first use, shared instance
- `registerFactory`: New instance each time
- `registerSingleton`: Created immediately, shared

## Quran Foundation API Integration

### Auth Flow
1. User taps "Sign in" → `QfAuthLoginRequested` event
2. `QfAuthBloc` calls `QfAuthRemoteDataSource.login()` (OAuth via AppAuth)
3. On success: `QfAuthInterceptor` attaches Bearer token to all API requests
4. On session expiry: `QfApiInterceptor` refreshes token automatically

### Content API (v4)
| Data Source | Endpoints | Purpose |
|------------|-----------|---------|
| `QfTranslationRemoteDataSource` | `/translations/{id}/by_chapter/{id}` | Verse translations (pagination) |
| `QfTafsirRemoteDataSourceImpl` | `/tafsirs/{id}/by_ayah/{key}` | Per-verse tafsir |
| `QfVerseStudyRemoteDataSourceImpl` | Combined Arabic + Translation + Tafsir | Verse study screen |

### Auth API (v1)
| Data Source | Endpoints | Purpose |
|------------|-----------|---------|
| `QfActivityRemoteDataSource` | `/streaks`, `/activity-days` | Reading streaks & daily activity |
| `QfGoalsRemoteDataSource` | `/goals`, `/reading-sessions` | Reading goals & session tracking |
| `QfUserApiRemoteDataSource` | `/bookmarks`, `/collections` | Bookmark sync with collections |
| `QfPostRemoteDataSource` | `/posts` | Verse reflections |

### Cloud Sync
- Bookmarks: Bidirectional sync via `SyncWithQf` use case (push local → QF, pull QF → local)
- Activity: Fire-and-forget activity day posting after reading; daily sync for pending days
- Goals: Pushed to QF on goal creation/update
- Collections: "Hafiz Bookmarks" collection used for synced bookmarks

## State Management (BLoC)

```
Event (User action) → Bloc.on<Event> → Repository call → emit(State) → UI rebuild
```

### Key BLoCs
| BLoC | Purpose | Registration |
|------|---------|-------------|
| `SurahBloc` | Load surah verses, scroll tracking | Factory (per-screen) |
| `BookmarkBloc` | Manage bookmarks (CRUD) | LazySingleton (shared) |
| `KhatmahBloc` | Reading tracker dashboard | LazySingleton |
| `QfAuthBloc` | QF authentication state | LazySingleton |
| `ThemeBloc` | Light/dark/system theme | LazySingleton (Hydrated) |
| `MemorizationBloc` | Memorization progress | LazySingleton |
| `RecitationErrorBloc` | Practice verses | LazySingleton |
| `SearchBloc` | Verse search | Factory |

## Data Persistence

- **Hive**: Bookmarks, memorization progress, khatmah (reading logs, goals), recitation errors, recitation sessions
- **SharedPreferences** (via `PrefUtils`): User settings (theme, font size, language, etc.)
- **HydratedBloc**: ThemeBloc state (persists theme choice across app restarts)

## Navigation

- Route definitions: `lib/routes/app_routes.dart`
- Navigation service: `lib/core/utils/navigator_service.dart`
- Named routes with `NavigatorService.pushNamed()`
- Drawer navigation from Home screen to all feature screens

## RTL Convention

All Quran/Arabic text MUST use `textDirection: TextDirection.rtl` regardless of app locale:
- Verse text (arabicText)
- Surah Arabic names (nameArabic)
- Tafsir and translation text
- Voice verification text
- Surah navigation arrows follow RTL semantics (next = left, prev = right)

## Testing

- **Unit/Widget Tests**: `test/` directory, mirrors `lib/` structure
- **BLoC Tests**: Use `bloc_test` package with `mocktail` for mocking
- **Integration Tests**: `integration_test/` directory
- Run: `flutter test` (unit), `flutter test integration_test/` (integration)
