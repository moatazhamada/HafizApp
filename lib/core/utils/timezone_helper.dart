import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hafiz_app/core/utils/logger.dart';

/// Builds a Dio [Options] with the device's local IANA timezone
/// in the `x-timezone` header. Falls back to `UTC` on failure.
Future<Options> buildTzOptions() async {
  try {
    final tz = await FlutterTimezone.getLocalTimezone();
    return Options(headers: {'x-timezone': tz.identifier});
  } catch (e) {
    Logger.warning('Failed to get local timezone: $e', feature: 'Timezone');
    return Options(headers: {'x-timezone': 'UTC'});
  }
}
