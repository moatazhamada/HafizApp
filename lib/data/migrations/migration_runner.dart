import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/pref_utils.dart';

/// Lightweight version-based migration runner.
///
/// Reads [lastRunVersion] from preferences, compares with the current
/// app version, and executes any registered migrations that have not
/// yet run.
class MigrationRunner {
  final List<Migration> _migrations;

  const MigrationRunner(this._migrations);

  Future<void> run() async {
    final lastVersion = PrefUtils().getLastRunVersion();
    String currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (e) {
      Logger.warning('MigrationRunner: Could not read package info: $e', feature: 'Migration');
      return;
    }

    if (lastVersion == currentVersion) {
      return; // Nothing to do
    }

    Logger.info(
      'MigrationRunner: $lastVersion → $currentVersion',
      feature: 'Migration',
    );

    for (final migration in _migrations) {
      try {
        await migration.run();
      } catch (e, stackTrace) {
        Logger.error(
          'Migration ${migration.name} failed: $e',
          feature: 'Migration',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue with other migrations — don't block startup
      }
    }

    PrefUtils().setLastRunVersion(currentVersion);
    Logger.info('MigrationRunner: completed', feature: 'Migration');
  }
}

abstract class Migration {
  String get name;
  Future<void> run();
}

/// v3.2.0 — Ensure all reading log entries have a syncStatus field.
class EnsureReadingLogSyncStatusMigration implements Migration {
  @override
  String get name => 'ensure_reading_log_sync_status_v3_2_0';

  @override
  Future<void> run() async {
    if (!Hive.isBoxOpen('reading_logs')) return;
    final box = Hive.box('reading_logs');
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (!map.containsKey('syncStatus')) {
        map['syncStatus'] = 'pending';
        await box.put(key, map);
      }
    }
    Logger.info('Ensured syncStatus on reading_logs', feature: 'Migration');
  }
}
