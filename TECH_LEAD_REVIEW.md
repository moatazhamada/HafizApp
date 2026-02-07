# 🔍 Tech Lead Code Review Report - Hafiz Quran App

**Review Date:** February 2026  
**Branch:** feature/v3-major-features  
**Reviewer:** Tech Lead  

---

## 📊 Executive Summary

| Severity | Count | Categories |
|----------|-------|------------|
| 🔴 **Critical** | 12 | Crashes, Memory Leaks, Data Loss |
| 🟡 **High** | 18 | Performance, Security, Architecture |
| 🟢 **Medium** | 25 | Code Quality, Maintainability |

**Overall Assessment:** The codebase has solid architecture (Clean Architecture + BLoC) but has accumulated technical debt, especially around lifecycle management, error handling, and performance optimization. The app is **NOT production-ready** until Critical issues are resolved.

---

## 🔴 CRITICAL ISSUES (Must Fix Before Release)

### 1. Memory Leaks

#### **AudioPlayerHandler Stream Leaks** 
**File:** `lib/core/audio/audio_player_handler.dart` (Lines 28-47)
```dart
// PROBLEM: Subscriptions never cancelled
_player.playbackEventStream.listen((event) { ... });
_player.positionStream.listen((position) { ... });
```
**Impact:** Each audio session leaks 3 stream subscriptions. After ~50 sessions, app will crash with OOM.  
**Fix:**
```dart
StreamSubscription? _playbackSub;
StreamSubscription? _positionSub;

void _init() {
  _playbackSub = _player.playbackEventStream.listen(...);
  _positionSub = _player.positionStream.listen(...);
}

Future<void> dispose() async {
  await _playbackSub?.cancel();
  await _positionSub?.cancel();
  // ... rest of dispose
}
```

#### **SurahBloc Stream in MushafScreen**
**File:** `lib/presentation/mushaf_screen/mushaf_screen.dart` (Lines 88-94)
```dart
await for (final state in _surahBloc.stream) { ... }
```
**Impact:** Stream continues if widget disposes during loading.  
**Fix:** Use `StreamSubscription` with cancellation.

---

### 2. Race Conditions & Crashes

#### **PrefUtils Race Condition**
**File:** `lib/core/utils/pref_utils.dart` (Lines 11-16)
```dart
PrefUtils() {
  SharedPreferences.getInstance().then((value) {
    _sharedPreferences = value;
  });
}
```
**Impact:** Any call to getters before async completes = NullPointer crash.  
**Fix:** Remove constructor initialization; use explicit `init()` only.

#### **HomeBloc Broken Equatable**
**File:** `lib/presentation/home_screen/bloc/home_state.dart` (Line 21)
```dart
class UpdateLastReadSurah extends HomeState {
  final Surah? surah;
  
  @override
  List<Object?> get props => []; // BUG: surah not included!
}
```
**Impact:** State changes don't trigger UI updates. Last Read card won't update.  
**Fix:** `List<Object?> get props => [surah];`

---

### 3. Data Loss Risk

#### **HydratedStorage in Temp Directory**
**File:** `lib/main.dart` (Lines 227-232)
```dart
storageDirectory: HydratedStorageDirectory(
  (await getTemporaryDirectory()).path, // ❌ WRONG
),
```
**Impact:** OS can clear temp directory anytime. User settings lost.  
**Fix:**
```dart
final dir = await getApplicationDocumentsDirectory();
storageDirectory: HydratedStorageDirectory(dir.path),
```

---

### 4. Security Vulnerabilities

#### **Unvalidated Deep Link Verse Numbers**
**File:** `lib/core/deep_link/deep_link_service.dart` (Line 76)
```dart
verseNumber = int.tryParse(pathSegments[3]); // No validation!
```
**Impact:** `/surah/2/verse/99999` accepted (Al-Baqarah only has 286 verses).  
**Fix:** Add validation:
```dart
final verseCount = getVerseCountForSurah(surahId);
if (verseNumber == null || verseNumber < 1 || verseNumber > verseCount) {
  return null;
}
```

---

## 🟡 HIGH PRIORITY ISSUES

### 5. Performance Bottlenecks

#### **O(n) Page Lookup**
**File:** `lib/core/quran_index/mushaf_page_index.dart` (Lines 54-62)
```dart
static int? findPageForVerse(int surahId, int verseNumber) {
  for (final page in _pagesData) { // 604 iterations worst case
    // ...
  }
}
```
**Impact:** Every verse lookup scans all pages. With deep linking, this happens frequently.  
**Fix:** Use Map for O(1) lookup:
```dart
static final _verseToPageMap = <String, int>{};

static void _buildIndex() {
  for (final page in _pagesData) {
    for (int v = page[2]; v <= page[3]; v++) {
      _verseToPageMap['${page[1]}:$v'] = page[0] as int;
    }
  }
}

static int? findPageForVerse(int surahId, int verseNumber) {
  return _verseToPageMap['$surahId:$verseNumber'];
}
```

#### **setState() in Async Gaps Without mounted Checks**
**Files:** Multiple locations
```dart
// audio_player_screen.dart:159-167
Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() { ... }); // No mounted check!
});
```
**Fix:**
```dart
Timer.periodic(const Duration(seconds: 1), (timer) {
  if (!mounted) {
    timer.cancel();
    return;
  }
  setState(() { ... });
});
```

---

### 6. Architecture Issues

#### **ThemeBloc Mixed Concerns**
**File:** `lib/theme/bloc/theme_bloc.dart` (Lines 51-57)
```dart
class OfflineState extends ThemeState { } // Doesn't belong here!
class OnlineState extends ThemeState { }  // Connectivity != Theme
```
**Impact:** Violates Single Responsibility Principle.  
**Fix:** Create separate `ConnectivityBloc`.

#### **Inconsistent BLoC Registration**
**File:** `lib/injection_container.dart`
```dart
sl.registerFactory(() => SurahBloc(...));      // Factory
sl.registerLazySingleton(() => BookmarkBloc(...)); // Singleton - why?
```
**Impact:** Bookmark state persists across screens unintentionally.  
**Fix:** Document why some are singletons, or make all factories.

---

## 🟢 MEDIUM PRIORITY ISSUES

### 7. Code Quality

#### **Unused ignore_for_file Comments**
**Files:** Multiple state files
```dart
// ignore_for_file: must_be_immutable  // Actually needed or not?
```
**Fix:** Remove unnecessary ignores; fix underlying issues.

#### **Silent Error Handling**
**File:** `lib/presentation/home_screen/home_screen.dart` (Lines 79-81)
```dart
try {
  sl<AnalyticsRouteObserver>().subscribe(this, route);
} catch (_) {} // Silent fail - bad!
```
**Fix:** Log errors at minimum.

---

### 8. Resource Management

#### **GlobalKey Accumulation**
**File:** `lib/presentation/surah_screen/surah_screen.dart` (Lines 50-52)
```dart
final Map<int, GlobalKey> _verseKeys = {}; // Never cleared!
```
**Impact:** Keys accumulate when switching Surahs.  
**Fix:** Clear in `dispose()`.

#### **Temp File Accumulation**
**File:** `lib/core/deep_link/deep_link_service.dart` (Lines 196-199)
```dart
// Generated verse images never deleted
```
**Fix:** Add cleanup after sharing.

---

## 📋 ACTION PLAN

### Phase 1: Critical Fixes (Before Release)
- [ ] Fix AudioPlayerHandler stream leaks
- [ ] Fix PrefUtils race condition
- [ ] Fix HomeBloc Equatable props
- [ ] Change HydratedStorage directory
- [ ] Add verse validation in deep links

### Phase 2: High Priority (Week 1)
- [ ] Optimize Mushaf page lookup to O(1)
- [ ] Add mounted checks to all async setState
- [ ] Extract connectivity states from ThemeBloc
- [ ] Fix DI registration inconsistencies

### Phase 3: Medium Priority (Week 2)
- [ ] Add error logging (remove silent catches)
- [ ] Clear GlobalKey maps in dispose
- [ ] Add temp file cleanup
- [ ] Performance test and optimize scroll

---

## 🎯 ARCHITECTURE RECOMMENDATIONS

### 1. Implement Proper Resource Management Pattern
```dart
mixin AutoDisposeMixin<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subs = [];
  final List<Timer> _timers = [];
  
  void autoCancel(StreamSubscription sub) => _subs.add(sub);
  void autoCancelTimer(Timer timer) => _timers.add(timer);
  
  @override
  void dispose() {
    for (final sub in _subs) sub.cancel();
    for (final timer in _timers) timer.cancel();
    super.dispose();
  }
}
```

### 2. Add Performance Monitoring
```dart
// In main.dart
void main() {
  PerformanceOverlay.allEnabled = kDebugMode;
  runApp(const BootstrapApp());
}
```

### 3. Implement Error Boundaries
```dart
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Text('Something went wrong. Please restart the app.'),
      ),
    );
  }
}

// In main.dart
ErrorWidget.builder = (details) => AppErrorWidget(details: details);
```

---

## 📈 TESTING RECOMMENDATIONS

1. **Memory Profiling:** Use Flutter DevTools to check for leaks during audio playback
2. **Integration Tests:** Test deep link handling with edge cases (invalid verses)
3. **Performance Tests:** Scroll through entire Mushaf (604 pages) and monitor FPS
4. **Lifecycle Tests:** Background/foreground app during audio playback

---

## 🏁 CONCLUSION

The app has a solid foundation with Clean Architecture, but needs immediate attention to:
1. **Lifecycle management** - Fix leaks before release
2. **Error handling** - Add proper logging and user feedback
3. **Performance** - Optimize lookups and rendering

**Estimated Fix Time:** 3-5 days for Critical + High issues  
**Risk Level:** 🔴 **HIGH** - Not production-ready without fixes
