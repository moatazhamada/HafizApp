# 🚨 CRITICAL FIXES REQUIRED - IMMEDIATE ACTION

## Priority 1: Memory Leaks (Fix Today)

### 1. AudioPlayerHandler Memory Leak
**File**: `lib/injection_container.dart` line 60
```dart
// WRONG - Creates new instance every time, never disposed
sl.registerFactory(() => AudioPlayerHandler());

// FIX - Use singleton
sl.registerLazySingleton(() => AudioPlayerHandler());
```

### 2. BLoCs Not Closed in MyApp
**File**: `lib/main.dart` line 88-92
```dart
// ADD this dispose method to _MyAppState:
@override
void dispose() {
  _deepLinkService.dispose();
  themeBloc.close();
  bookmarkBloc.close();
  recitationErrorBloc.close();
  super.dispose();
}
```

### 3. Duplicate Hive Initialization
**File**: `lib/main.dart` lines 127-130 and 165-170
```dart
// REMOVE duplicate initialization in _postInitHeavyTasks()
// Keep only in _init() method
```

---

## Priority 2: Crash Bugs (Fix This Week)

### 4. PrefUtils Thread Safety
**File**: `lib/core/utils/pref_utils.dart`
```dart
// ADD synchronized package to pubspec.yaml
// synchronized: ^3.1.0

import 'package:synchronized/synchronized.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;
  static final _initLock = Lock();
  
  Future<void> init() async {
    if (_sharedPreferences != null) return;
    
    await _initLock.synchronized(() async {
      if (_sharedPreferences != null) return;
      _sharedPreferences = await SharedPreferences.getInstance();
    });
  }
}
```

### 5. Search Worker Type Safety
**File**: `lib/data/datasource/surah/surah_local_data_source.dart` line 75
```dart
Future<List<Map<String, dynamic>>> _searchWorker(
  Map<String, Object?> args,
) async {
  try {
    // Validate all inputs
    final token = args['token'];
    if (token is! RootIsolateToken) return [];
    
    final basePath = args['basePath'];
    if (basePath is! String) return [];
    
    final query = args['query'];
    if (query is! String || query.isEmpty) return [];
    
    // ... rest of implementation
  } catch (e, stackTrace) {
    debugPrint('Fatal error in search worker: $e\n$stackTrace');
    return [];
  }
}
```

---

## Priority 3: Performance Issues (Fix This Sprint)

### 6. Search Result Limit
**File**: `lib/data/datasource/surah/surah_local_data_source.dart`
```dart
Future<List<VerseModel>> searchVerses(
  String query, {
  int maxResults = 50,  // ADD limit parameter
}) async {
  // Pass maxResults to worker
  final rawMatches = await compute(
    _searchWorker,
    <String, Object?>{
      'token': token,
      'basePath': basePath,
      'query': query,
      'maxResults': maxResults,  // ADD this
    },
  );
  return rawMatches.map(VerseModel.fromJson).toList();
}

// In worker, add early exit:
for (int i = 1; i <= 114; i++) {
  if (allMatches.length >= maxResults) break;  // ADD this
  // ... search logic
}
```

### 7. Request Deduplication in Repository
**File**: `lib/data/repository/surah/surah_repository_impl.dart`
```dart
class SurahRepositoryImpl implements SurahRepository {
  final Map<String, Future<Either<Failure, List<Verse>>>> _pendingRequests = {};

  @override
  Future<Either<Failure, List<Verse>>> getSurah(String surahId) async {
    if (_pendingRequests.containsKey(surahId)) {
      return _pendingRequests[surahId]!;
    }
    
    final request = _getSurahInternal(surahId);
    _pendingRequests[surahId] = request;
    
    try {
      return await request;
    } finally {
      _pendingRequests.remove(surahId);
    }
  }
  
  Future<Either<Failure, List<Verse>>> _getSurahInternal(String surahId) async {
    // Move existing getSurah logic here
  }
}
```

### 8. Theme Mode from BLoC State
**File**: `lib/main.dart` line 137-142
```dart
// REMOVE _getThemeMode() method
// USE BLoC state instead:

@override
Widget build(BuildContext context) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: themeBloc),
      // ...
    ],
    child: BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.notifier,
          builder: (_, locale, _) => MaterialApp(
            themeMode: themeState.themeMode,  // From BLoC
            // ...
          ),
        );
      },
    ),
  );
}
```

---

## Priority 4: Error Handling (Fix Next Sprint)

### 9. Audio Player Error Boundary
**File**: `lib/presentation/audio_player/audio_player_screen.dart`
```dart
String? _errorMessage;

Future<void> _initAudioService() async {
  try {
    // ... initialization code ...
  } catch (e, stackTrace) {
    Logger.error(
      'Error initializing audio: $e',
      feature: 'AudioPlayer',
      error: e,
      stackTrace: stackTrace,
    );
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load audio. Please try again.';
      });
    }
  }
}

// Add error UI in build():
if (_errorMessage != null) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _initAudioService();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
```

### 10. Mounted Check in Timer
**File**: `lib/presentation/audio_player/audio_player_screen.dart`
```dart
void _setSleepTimer(Duration duration) {
  _sleepTimer?.cancel();
  _remainingSleepTime = duration;

  _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!mounted) {  // ADD this check
      timer.cancel();
      return;
    }
    
    setState(() {
      _remainingSleepTime = _remainingSleepTime! - const Duration(seconds: 1);
      if (_remainingSleepTime!.inSeconds <= 0) {
        _audioHandler?.pause();
        _cancelSleepTimer();
      }
    });
  });
}
```

---

## Testing Required After Fixes

```bash
# 1. Run all tests
flutter test

# 2. Check for memory leaks
# Use Flutter DevTools Memory tab
# Profile audio player usage for 5 minutes

# 3. Test search performance
# Search for common words (الله, في, من)
# Verify results limited to 50

# 4. Test concurrent requests
# Open multiple Surahs quickly
# Verify no duplicate network calls

# 5. Test error scenarios
# Disable network
# Test audio player with invalid URLs
# Test deep links with invalid data
```

---

## Estimated Impact

| Issue | Severity | Users Affected | Fix Time |
|-------|----------|----------------|----------|
| AudioPlayerHandler leak | CRITICAL | 100% | 5 min |
| BLoCs not closed | CRITICAL | 100% | 5 min |
| Duplicate Hive init | CRITICAL | 100% | 10 min |
| PrefUtils thread safety | HIGH | 20% | 30 min |
| Search worker crashes | HIGH | 50% | 20 min |
| Search performance | HIGH | 80% | 45 min |
| Request deduplication | MEDIUM | 30% | 1 hour |
| Theme mode performance | MEDIUM | 100% | 1 hour |
| Audio error handling | MEDIUM | 10% | 30 min |
| Timer mounted check | LOW | 5% | 5 min |

**Total Fix Time**: ~4-5 hours
**Total Users Impacted**: 100% will see improvements

---

## Deployment Plan

1. **Hotfix Release (v3.0.1)** - Critical fixes only
   - AudioPlayerHandler leak
   - BLoCs not closed
   - Duplicate Hive init
   - Deploy within 24 hours

2. **Patch Release (v3.0.2)** - High priority fixes
   - PrefUtils thread safety
   - Search worker crashes
   - Search performance
   - Deploy within 1 week

3. **Minor Release (v3.1.0)** - All remaining fixes
   - Request deduplication
   - Theme mode optimization
   - Error handling improvements
   - Deploy within 2 weeks
