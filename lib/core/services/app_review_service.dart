import 'package:hafiz_app/core/app_export.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  static const _launchCountKey = 'app_review_launch_count';
  static const _lastAskedKey = 'app_review_last_asked';
  static const _minLaunches = 5;
  static const _minDaysBetweenPrompts = 30;

  /// Call this on app launch. Triggers the in-app review dialog when
  /// conditions are met (minimum launches + cooldown period).
  static Future<void> maybeRequestReview() async {
    try {
      final prefs = PrefUtils();

      final count = prefs.getInt(_launchCountKey) ?? 0;
      final newCount = count + 1;
      await prefs.setInt(_launchCountKey, newCount);

      if (newCount < _minLaunches) return;

      final lastAsked = prefs.getInt(_lastAskedKey);
      if (lastAsked != null) {
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastAsked);
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < _minDaysBetweenPrompts) return;
      }

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await prefs.setInt(
          _lastAskedKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        await inAppReview.requestReview();
      }
    } catch (e) {
      // In-app review not available on this platform (web, desktop)
      Logger.warning('App review not available: $e', feature: 'AppReview');
    }
  }
}
