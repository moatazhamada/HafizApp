# ⚡ Performance Optimization Guide

## Memory Optimizations

### 1. Implement Verse Pagination
**Current**: Loads entire Surah (up to 286 verses) at once
**Impact**: 2-5 MB memory per Surah

```dart
// lib/presentation/surah_screen/surah_screen.dart
class SurahScreen extends StatefulWidget {
  final Surah surah;
  final int initialPage;
  
  const SurahScreen({
    required this.surah,
    this.initialPage = 0,
  });
}

class _SurahScreenState extends State<SurahScreen> {
  static const int _pageSize = 20;  // Load 20 verses at a time
  final List<Verse> _loadedVerses = [];
  int _currentPage = 0;
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }
  
  Future<void> _loadPage(int page) async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.surah.verseCount);
    
    // Load verses for this page
    final verses = await _loadVerses(start, end);
    
    setState(() {
      _loadedVerses.addAll(verses);
      _currentPage = page;
      _isLoadingMore = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _loadedVerses.length + 1,
      itemBuilder: (context, index) {
        if (index == _loadedVerses.length) {
          // Load more trigger
          if (!_isLoadingMore && _loadedVerses.length < widget.surah.verseCount) {
            _loadPage(_currentPage + 1);
          }
          return const Center(child: CircularProgressIndicator());
        }
        
        return VerseWidget(verse: _loadedVerses[index]);
      },
    );
  }
}
```

**Savings**: 80% memory reduction for large Surahs

---

### 2. Image Caching Strategy
**Current**: No explicit cache limits
**Impact**: Unbounded memory growth

```dart
// lib/core/utils/image_cache_manager.dart
import 'package:flutter/painting.dart';

class ImageCacheManager {
  static void configure() {
    // Limit image cache size
    PaintingBinding.instance.imageCache.maximumSize = 100;  // 100 images
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;  // 50 MB
  }
}

// In main.dart:
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ImageCacheManager.configure();  // ADD this
  // ... rest of init
}
```

---

### 3. Dispose Unused Resources
**Current**: Some resources not properly disposed

```dart
// Create a base class for screens with resources
abstract class DisposableScreen extends StatefulWidget {
  const DisposableScreen({super.key});
}

abstract class DisposableScreenState<T extends DisposableScreen> 
    extends State<T> {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<ScrollController> _controllers = [];
  
  void addSubscription(StreamSubscription sub) => _subscriptions.add(sub);
  void addTimer(Timer timer) => _timers.add(timer);
  void addController(ScrollController controller) => _controllers.add(controller);
  
  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
```

---

## CPU Optimizations

### 4. Optimize Arabic Text Rendering
**Current**: Text widgets rebuild frequently
**Impact**: High CPU usage during scrolling

```dart
// lib/widgets/verse_text_widget.dart
class VerseTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  
  const VerseTextWidget({
    super.key,
    required this.text,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(  // Isolate repaints
      child: Text(
        text,
        style: style ?? const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 24,
          height: 2.0,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
      ),
    );
  }
}
```

---

### 5. Debounce Search Input
**Current**: Searches on every keystroke
**Impact**: Excessive CPU usage, poor UX

```dart
// lib/presentation/search/search_screen.dart
import 'dart:async';

class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounceTimer;
  final _searchController = TextEditingController();
  
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.length < 3) return;  // Minimum 3 characters
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchBloc>().add(SearchQueryEvent(query));
    });
  }
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
```

---

### 6. Lazy Load Surah List
**Current**: Loads all 114 Surahs at once
**Impact**: Slow initial render

```dart
// lib/presentation/home_screen/home_screen.dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: QuranIndex.quranSurahs.length,
      itemBuilder: (context, index) {
        // Only build visible items
        return SurahListItem(
          surah: QuranIndex.quranSurahs[index],
        );
      },
      // Add caching for better performance
      cacheExtent: 500,  // Cache 500 pixels ahead
    );
  }
}
```

---

## Network Optimizations

### 7. Implement HTTP Caching Headers
**Current**: No cache control
**Impact**: Redundant network requests

```dart
// lib/core/network/network_manager.dart
class NetworkManagerImpl extends NetworkManagerI {
  final Dio _dio;

  NetworkManagerImpl(this._dio) {
    // Add cache interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add cache headers
          options.headers['Cache-Control'] = 'max-age=86400';  // 24 hours
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Cache successful responses
          if (response.statusCode == 200) {
            _cacheResponse(response);
          }
          return handler.next(response);
        },
      ),
    );
  }
}
```

---

### 8. Batch API Requests
**Current**: Individual requests for each verse audio
**Impact**: High latency, poor UX

```dart
// lib/data/datasource/audio/audio_remote_data_source.dart
abstract class AudioRemoteDataSource {
  Future<List<AudioUrl>> getSurahAudioUrls(int surahId, String reciterId);
}

class AudioRemoteDataSourceImpl implements AudioRemoteDataSource {
  final NetworkManager networkManager;
  
  @override
  Future<List<AudioUrl>> getSurahAudioUrls(int surahId, String reciterId) async {
    // Single request for all verse URLs
    final response = await networkManager.get(
      '/recitations/$reciterId/by_chapter/$surahId',
    );
    
    return (response.data['audio_files'] as List)
        .map((url) => AudioUrl.fromJson(url))
        .toList();
  }
}
```

---

## Storage Optimizations

### 9. Compress Hive Boxes
**Current**: Uncompressed storage
**Impact**: Larger app size, slower I/O

```dart
// lib/main.dart
Future<void> _openAllHiveBoxes() async {
  await Future.wait([
    Hive.openBox('surah_cache', compactionStrategy: (entries, deletedEntries) {
      return deletedEntries > 20;  // Compact after 20 deletions
    }),
    Hive.openBox('bookmarks'),
    Hive.openBox('recitation_errors'),
    Hive.openBox('qiraat_cache'),
    Hive.openBox('audio_cache', compactionStrategy: (entries, deletedEntries) {
      return deletedEntries > 10;  // More aggressive for audio
    }),
  ]);
}
```

---

### 10. Implement Cache Expiration
**Current**: Cache never expires
**Impact**: Stale data, wasted storage

```dart
// lib/data/model/cached_item.dart
class CachedItem<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;
  
  CachedItem({
    required this.data,
    required this.cachedAt,
    this.ttl = const Duration(days: 30),
  });
  
  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'ttl': ttl.inSeconds,
  };
  
  factory CachedItem.fromJson(Map<String, dynamic> json) {
    return CachedItem(
      data: json['data'],
      cachedAt: DateTime.parse(json['cachedAt']),
      ttl: Duration(seconds: json['ttl']),
    );
  }
}

// In repository:
Future<Either<Failure, List<Verse>>> getSurah(String surahId) async {
  final box = Hive.box('surah_cache');
  final cached = box.get(surahId);
  
  if (cached != null) {
    final cachedItem = CachedItem.fromJson(cached);
    if (!cachedItem.isExpired) {
      return Right(cachedItem.data);
    }
    // Expired, remove from cache
    await box.delete(surahId);
  }
  
  // Fetch fresh data...
}
```

---

## UI Optimizations

### 11. Use const Constructors Everywhere
**Current**: Many widgets not const
**Impact**: Unnecessary rebuilds

```bash
# Run this command to find non-const widgets:
grep -r "Widget build" lib/ | grep -v "const"

# Then add const where possible:
# BEFORE:
return Text('Hello');

# AFTER:
return const Text('Hello');
```

---

### 12. Implement Shimmer Loading
**Current**: Blank screen during loading
**Impact**: Poor perceived performance

```dart
// lib/widgets/shimmer_loading.dart
import 'package:shimmer/shimmer.dart';

class VerseShimmer extends StatelessWidget {
  const VerseShimmer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Benchmarking

### Performance Targets

| Metric | Current | Target | Priority |
|--------|---------|--------|----------|
| App startup time | 3.5s | <2s | HIGH |
| Surah load time | 800ms | <300ms | HIGH |
| Search response | 2s | <500ms | CRITICAL |
| Memory usage (idle) | 150MB | <100MB | MEDIUM |
| Memory usage (active) | 300MB | <200MB | HIGH |
| Frame rate (scrolling) | 45fps | 60fps | MEDIUM |
| APK size | 45MB | <35MB | LOW |

### Measurement Tools

```dart
// lib/core/utils/performance_monitor.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceMonitor {
  static Future<T> measure<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    
    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}

// Usage:
final verses = await PerformanceMonitor.measure(
  'load_surah',
  () => repository.getSurah(surahId),
);
```

---

## Implementation Priority

1. **Week 1**: Critical memory leaks + search optimization
2. **Week 2**: Network optimizations + caching strategy
3. **Week 3**: UI optimizations + shimmer loading
4. **Week 4**: Benchmarking + fine-tuning

**Expected Results**:
- 40% faster app startup
- 60% less memory usage
- 75% faster search
- 90% better perceived performance
