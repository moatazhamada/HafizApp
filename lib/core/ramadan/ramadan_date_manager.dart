import 'package:flutter/material.dart';
import '../utils/pref_utils.dart';

/// Ramadan Region - Different regions may have different moon sighting dates
enum RamadanRegion {
  auto, // Auto-detect based on device locale
  mecca, // Saudi Arabia / Umm al-Qura calendar
  egypt, // Egypt
  turkey, // Turkey
  uae, // UAE
  pakistan, // Pakistan
  india, // India
  indonesia, // Indonesia
  malaysia, // Malaysia
  morocco, // Morocco
  usa, // USA/ISNA
  uk, // UK
  custom, // User manually sets dates
}

/// Ramadan Date Manager
/// Handles regional variations in Ramadan dates based on moon sightings
class RamadanDateManager {
  // Current year (2026) estimated dates by region
  // These are approximate and may vary based on actual moon sightings
  static final Map<RamadanRegion, RamadanDates> _dates2026 = {
    RamadanRegion.mecca: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
    RamadanRegion.egypt: RamadanDates(
      start: DateTime(2026, 2, 19), // 1 day later
      end: DateTime(2026, 3, 20),
      eid: DateTime(2026, 3, 21),
    ),
    RamadanRegion.turkey: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
    RamadanRegion.uae: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
    RamadanRegion.pakistan: RamadanDates(
      start: DateTime(2026, 2, 19), // 1 day later
      end: DateTime(2026, 3, 20),
      eid: DateTime(2026, 3, 21),
    ),
    RamadanRegion.india: RamadanDates(
      start: DateTime(2026, 2, 19),
      end: DateTime(2026, 3, 20),
      eid: DateTime(2026, 3, 21),
    ),
    RamadanRegion.indonesia: RamadanDates(
      start: DateTime(2026, 2, 19),
      end: DateTime(2026, 3, 20),
      eid: DateTime(2026, 3, 21),
    ),
    RamadanRegion.malaysia: RamadanDates(
      start: DateTime(2026, 2, 19),
      end: DateTime(2026, 3, 20),
      eid: DateTime(2026, 3, 21),
    ),
    RamadanRegion.morocco: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
    RamadanRegion.usa: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
    RamadanRegion.uk: RamadanDates(
      start: DateTime(2026, 2, 18),
      end: DateTime(2026, 3, 19),
      eid: DateTime(2026, 3, 20),
    ),
  };

  /// Get the current selected region
  static RamadanRegion get selectedRegion {
    final regionStr = PrefUtils().getString('ramadan_region');
    if (regionStr == null) return RamadanRegion.auto;
    return RamadanRegion.values.firstWhere(
      (r) => r.name == regionStr,
      orElse: () => RamadanRegion.auto,
    );
  }

  /// Save selected region
  static Future<void> setRegion(RamadanRegion region) async {
    await PrefUtils().setString('ramadan_region', region.name);
  }

  /// Get region display name
  static String getRegionName(RamadanRegion region) {
    switch (region) {
      case RamadanRegion.auto:
        return 'Auto-detect';
      case RamadanRegion.mecca:
        return 'Saudi Arabia (Mecca)';
      case RamadanRegion.egypt:
        return 'Egypt';
      case RamadanRegion.turkey:
        return 'Turkey';
      case RamadanRegion.uae:
        return 'United Arab Emirates';
      case RamadanRegion.pakistan:
        return 'Pakistan';
      case RamadanRegion.india:
        return 'India';
      case RamadanRegion.indonesia:
        return 'Indonesia';
      case RamadanRegion.malaysia:
        return 'Malaysia';
      case RamadanRegion.morocco:
        return 'Morocco';
      case RamadanRegion.usa:
        return 'United States (ISNA)';
      case RamadanRegion.uk:
        return 'United Kingdom';
      case RamadanRegion.custom:
        return 'Custom Dates';
    }
  }

  /// Get Ramadan dates for the selected region
  static RamadanDates getDates() {
    final region = selectedRegion;

    // If custom dates are set, use those
    if (region == RamadanRegion.custom) {
      final customDates = _getCustomDates();
      if (customDates != null) return customDates;
    }

    // If auto-detect, try to determine from device locale
    if (region == RamadanRegion.auto) {
      final autoRegion = _detectRegionFromLocale();
      return _dates2026[autoRegion] ?? _dates2026[RamadanRegion.mecca]!;
    }

    // Return dates for selected region
    return _dates2026[region] ?? _dates2026[RamadanRegion.mecca]!;
  }

  /// Detect region based on device locale and timezone
  static RamadanRegion _detectRegionFromLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode?.toUpperCase();

    // First try explicit locale if it's a strongly typed Islamic region
    if (countryCode != null) {
      switch (countryCode) {
        case 'SA':
          return RamadanRegion.mecca;
        case 'EG':
          return RamadanRegion.egypt;
        case 'TR':
          return RamadanRegion.turkey;
        case 'AE':
          return RamadanRegion.uae;
        case 'PK':
          return RamadanRegion.pakistan;
        case 'IN':
          return RamadanRegion.india;
        case 'ID':
          return RamadanRegion.indonesia;
        case 'MY':
          return RamadanRegion.malaysia;
        case 'MA':
          return RamadanRegion.morocco;
      }
    }

    // Fallback to timezone offset for more reliable geographic estimation
    final timeZoneOffset = DateTime.now().timeZoneOffset;
    final offsetHours = timeZoneOffset.inHours;

    if (offsetHours == 2) return RamadanRegion.egypt;
    if (offsetHours == 3) return RamadanRegion.mecca;
    if (offsetHours == 4) return RamadanRegion.uae;
    if (offsetHours == 5) {
      if (timeZoneOffset.inMinutes % 60 != 0) return RamadanRegion.india;
      return RamadanRegion.pakistan;
    }
    if (offsetHours >= 7 && offsetHours <= 9) return RamadanRegion.indonesia;
    if (offsetHours == 1) return RamadanRegion.morocco;
    if (offsetHours == 0) return RamadanRegion.uk;
    if (offsetHours < 0) return RamadanRegion.usa;

    return RamadanRegion.mecca; // Default to Mecca
  }

  /// Save custom dates
  static Future<void> setCustomDates(
    DateTime start,
    DateTime end,
    DateTime eid,
  ) async {
    await PrefUtils().setString(
      'ramadan_custom_start',
      start.millisecondsSinceEpoch.toString(),
    );
    await PrefUtils().setString(
      'ramadan_custom_end',
      end.millisecondsSinceEpoch.toString(),
    );
    await PrefUtils().setString(
      'ramadan_custom_eid',
      eid.millisecondsSinceEpoch.toString(),
    );
    await setRegion(RamadanRegion.custom);
  }

  /// Get custom dates from preferences
  static RamadanDates? _getCustomDates() {
    final startStr = PrefUtils().getString('ramadan_custom_start');
    final endStr = PrefUtils().getString('ramadan_custom_end');
    final eidStr = PrefUtils().getString('ramadan_custom_eid');

    if (startStr == null || endStr == null || eidStr == null) return null;

    try {
      final start = DateTime.fromMillisecondsSinceEpoch(int.parse(startStr));
      final end = DateTime.fromMillisecondsSinceEpoch(int.parse(endStr));
      final eid = DateTime.fromMillisecondsSinceEpoch(int.parse(eidStr));
      return RamadanDates(start: start, end: end, eid: eid);
    } catch (_) {
      return null;
    }
  }

  /// Helper to get current date without time
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Check if currently in Ramadan
  static bool get isRamadan {
    final dates = getDates();
    final today = _today;
    final start = DateTime.utc(
      dates.start.year,
      dates.start.month,
      dates.start.day,
    );
    final expiry = DateTime.utc(
      dates.eid.year,
      dates.eid.month,
      dates.eid.day,
    ).add(const Duration(days: 3));
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    return !todayUtc.isBefore(start) && todayUtc.isBefore(expiry);
  }

  /// Check if in Ramadan month (before Eid)
  static bool get isRamadanMonth {
    final dates = getDates();
    final today = _today;
    final start = DateTime.utc(
      dates.start.year,
      dates.start.month,
      dates.start.day,
    );
    final eid = DateTime.utc(dates.eid.year, dates.eid.month, dates.eid.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    return !todayUtc.isBefore(start) && todayUtc.isBefore(eid);
  }

  /// Get current Ramadan day number
  static int? get currentRamadanDay {
    if (!isRamadanMonth) return null;
    final dates = getDates();
    final today = _today;
    final start = DateTime.utc(
      dates.start.year,
      dates.start.month,
      dates.start.day,
    );
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    return todayUtc.difference(start).inDays + 1;
  }

  /// Get days until Eid
  static int get daysUntilEid {
    if (!isRamadan) return 0;
    final dates = getDates();
    final today = _today;
    final eid = DateTime.utc(dates.eid.year, dates.eid.month, dates.eid.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    return eid.difference(todayUtc).inDays;
  }

  /// Show region selector dialog
  static Future<void> showRegionSelector(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Region'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: RamadanRegion.values.length,
            itemBuilder: (context, index) {
              final region = RamadanRegion.values[index];
              final isSelected = region == selectedRegion;

              return ListTile(
                title: Text(getRegionName(region)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.teal)
                    : null,
                onTap: () async {
                  await setRegion(region);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  // If custom selected, show date picker
                  if (region == RamadanRegion.custom && context.mounted) {
                    await _showCustomDatePicker(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show custom date picker
  static Future<void> _showCustomDatePicker(BuildContext context) async {
    final dates = getDates();

    DateTime? start = dates.start;
    DateTime? end = dates.end;
    DateTime? eid = dates.eid;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Dates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Ramadan Start'),
              subtitle: Text(
                start != null ? _formatDate(start!) : 'Select date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: start ?? DateTime(2026, 2, 18),
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                );
                if (picked != null) start = picked;
              },
            ),
            ListTile(
              title: const Text('Ramadan End'),
              subtitle: Text(end != null ? _formatDate(end!) : 'Select date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: end ?? DateTime(2026, 3, 19),
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                );
                if (picked != null) end = picked;
              },
            ),
            ListTile(
              title: const Text('Eid Al-Fitr'),
              subtitle: Text(eid != null ? _formatDate(eid!) : 'Select date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: eid ?? DateTime(2026, 3, 20),
                  firstDate: DateTime(2026, 1, 1),
                  lastDate: DateTime(2026, 12, 31),
                );
                if (picked != null) eid = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (start != null && end != null && eid != null) {
                await setCustomDates(start!, end!, eid!);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Ramadan dates data class
class RamadanDates {
  final DateTime start;
  final DateTime end;
  final DateTime eid;

  const RamadanDates({
    required this.start,
    required this.end,
    required this.eid,
  });
}
