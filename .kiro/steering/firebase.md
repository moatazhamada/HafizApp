# Firebase Integration

## Services Used

### Firebase Core
- Required for all Firebase services
- Initialized in `main.dart` before app starts
- Platform-specific config files:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
  - macOS: `macos/Runner/GoogleService-Info.plist`

### Firebase Crashlytics
- Automatic crash reporting
- Non-fatal error tracking
- Custom logging and context

### Firebase Analytics
- User behavior tracking
- Screen view tracking
- Custom event logging

### Firebase Performance
- Automatic performance monitoring
- Network request tracking
- Custom trace monitoring

### Cloud Firestore
- Cloud data synchronization
- Real-time updates
- Offline persistence

## Crashlytics Usage

### Initialization
```dart
// In main.dart
final crashlytics = FirebaseCrashlytics.instance;
Logger.init(
  kDebugMode ? LogMode.debug : LogMode.live,
  crashlytics: crashlytics,
);

// Catch Flutter errors
FlutterError.onError = (errorDetails) {
  Logger.error(
    'Flutter error: ${errorDetails.exception}',
    feature: 'Flutter',
    error: errorDetails.exception,
    stackTrace: errorDetails.stack,
    fatal: true,
  );
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

// Catch platform errors
PlatformDispatcher.instance.onError = (error, stack) {
  Logger.error(
    'Platform error: $error',
    feature: 'Platform',
    error: error,
    stackTrace: stack,
    fatal: true,
  );
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

### Recording Errors
```dart
// Fatal errors (crashes)
try {
  criticalOperation();
} catch (e, stackTrace) {
  Logger.error(
    'Critical failure',
    feature: 'FeatureName',
    error: e,
    stackTrace: stackTrace,
    fatal: true,
  );
}

// Non-fatal errors
try {
  riskyOperation();
} catch (e, stackTrace) {
  Logger.recordNonFatal(
    e,
    stackTrace: stackTrace,
    reason: 'Failed to load optional data',
  );
}
```

### Custom Keys
```dart
// Add context to crash reports
Logger.setCustomKey('user_type', 'premium');
Logger.setCustomKey('last_surah', surahId);
Logger.setCustomKey('app_state', 'reading');

// Set user identifier (anonymized)
Logger.setUserId(hashedUserId);
```

### Best Practices
- Record all unexpected errors
- Add context with custom keys before errors
- Use `fatal: true` for crashes, `fatal: false` for recoverable errors
- Never log PII (personally identifiable information)
- Test crash reporting in debug builds

## Analytics Usage

### Screen Tracking
```dart
// Automatic via AnalyticsRouteObserver
// Registered in main.dart:
navigatorObservers: [sl<AnalyticsRouteObserver>()]

// Manual screen tracking
AnalyticsService().logScreenView(
  screenName: 'surah_screen',
  screenClass: 'SurahScreen',
);
```

### Event Logging
```dart
// Simple event
AnalyticsService().logEvent(name: 'bookmark_added');

// Event with parameters
AnalyticsService().logEvent(
  name: 'surah_opened',
  parameters: {
    'surah_id': surahId,
    'surah_name': surahName,
    'source': 'home_screen',
  },
);

// Predefined events
AnalyticsService().logSearch(searchTerm: query);
AnalyticsService().logShare(
  contentType: 'verse',
  itemId: verseId,
  method: 'image',
);
```

### Event Naming Conventions
- Use snake_case: `surah_opened`, `bookmark_added`
- Be specific: `audio_played` not `play`
- Include context: `search_performed_home`, `search_performed_surah`
- Keep parameter names consistent across events

### Common Events to Track
```dart
// User actions
'surah_opened'
'verse_bookmarked'
'audio_played'
'audio_paused'
'search_performed'
'share_verse'

// Feature usage
'voice_verification_started'
'voice_verification_completed'
'mushaf_type_changed'
'theme_changed'

// Errors
'api_error'
'cache_error'
'permission_denied'
```

### User Properties
```dart
// Set once during onboarding
AnalyticsService().setUserProperty(
  name: 'preferred_mushaf',
  value: 'madani',
);

AnalyticsService().setUserProperty(
  name: 'preferred_language',
  value: 'ar',
);
```

## Performance Monitoring

### Automatic Monitoring
- App start time
- Screen rendering
- Network requests (via Dio)

### Custom Traces
```dart
// Measure specific operations
final trace = FirebasePerformance.instance.newTrace('load_surah');
await trace.start();

try {
  await loadSurahData();
  trace.setMetric('verse_count', verseCount);
} finally {
  await trace.stop();
}
```

### Network Request Monitoring
```dart
// Automatic via Dio interceptor
// Already configured in NetworkManager

// Manual HTTP metric
final metric = FirebasePerformance.instance
    .newHttpMetric('https://api.quran.com/api/v4/chapters/1', HttpMethod.Get);

await metric.start();
// Make request
metric.responseCode = 200;
metric.responsePayloadSize = responseSize;
await metric.stop();
```

## Firestore Usage

### Data Structure
```
users/{userId}/
  ├── bookmarks/{bookmarkId}
  ├── progress/{progressId}
  └── settings/

shared/
  ├── qiraat/{qiraatId}
  └── reciters/{reciterId}
```

### Reading Data
```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('bookmarks')
    .get();

final bookmarks = snapshot.docs
    .map((doc) => Bookmark.fromFirestore(doc))
    .toList();
```

### Writing Data
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('bookmarks')
    .doc(bookmarkId)
    .set(bookmark.toMap());
```

### Real-time Updates
```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('bookmarks')
    .snapshots()
    .listen((snapshot) {
      final bookmarks = snapshot.docs
          .map((doc) => Bookmark.fromFirestore(doc))
          .toList();
      // Update UI
    });
```

### Offline Persistence
```dart
// Enable offline persistence (already enabled by default)
await FirebaseFirestore.instance
    .enablePersistence(const PersistenceSettings(synchronizeTabs: true));
```

## Configuration

### Environment Variables
```bash
# Build with custom Firebase config
flutter build apk \
  --dart-define=QF_USE_CONTENT=true \
  --dart-define=QF_CLIENT_ID=your_client_id \
  --dart-define=QF_CLIENT_SECRET=your_secret
```

### Debug vs Production
- Debug: All logs printed, test mode enabled
- Production: Only errors sent to Crashlytics, analytics enabled

### Testing Firebase
```dart
// Disable analytics in tests
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);

// Use Firestore emulator
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

## Security Rules

### Firestore Rules Example
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only owner can read/write
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared data - authenticated users can read
    match /shared/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Admin only
    }
  }
}
```

## Privacy & Compliance

### Data Collection
- Analytics: User behavior, screen views, events
- Crashlytics: Error logs, device info, stack traces
- Firestore: User bookmarks, progress, settings

### User Consent
- Analytics can be disabled in settings
- Crashlytics always enabled for stability
- Firestore sync optional (local-only mode available)

### Data Retention
- Analytics: 14 months (Firebase default)
- Crashlytics: 90 days
- Firestore: User-controlled (can delete account)

## Troubleshooting

### Crashlytics Not Reporting
- Check Firebase console for app registration
- Verify google-services.json is up to date
- Force a test crash: `FirebaseCrashlytics.instance.crash()`
- Check logs for initialization errors

### Analytics Not Tracking
- Enable debug mode: `adb shell setprop debug.firebase.analytics.app com.hafiz.app.hafiz_app`
- Check DebugView in Firebase console
- Verify events are logged: `Logger.debug('Analytics event sent')`

### Performance Issues
- Check network request sizes
- Monitor trace durations in console
- Optimize heavy operations
- Use custom traces for bottlenecks
