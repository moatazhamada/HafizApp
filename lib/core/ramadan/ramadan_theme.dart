import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ramadan_date_manager.dart';
import '../../localization/app_localization.dart';

/// Ramadan Theme Manager
/// Automatically detects Ramadan dates based on user's region
/// Supports multiple moon sighting dates for different countries
/// Auto-expires after Eid Al-Fitr
class RamadanTheme {
  /// Check if current date is within Ramadan period
  static bool get isRamadan => RamadanDateManager.isRamadan;

  /// Check if we're in Ramadan month (before Eid)
  static bool get isRamadanMonth => RamadanDateManager.isRamadanMonth;

  /// Get days remaining until Eid
  static int get daysUntilEid => RamadanDateManager.daysUntilEid;

  /// Get Ramadan day number (1-30)
  static int? get currentRamadanDay => RamadanDateManager.currentRamadanDay;

  /// Ramadan color scheme - Soft, comfortable colors
  static ThemeData get ramadanTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ramadanPrimary,
        brightness: Brightness.light,
        primary: ramadanPrimary,
        secondary: ramadanSecondary,
        surface: ramadanSurface,
      ),
      scaffoldBackgroundColor: ramadanBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: ramadanPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle:
            SystemUiOverlayStyle.light, // Fix status bar contrast
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: Colors.grey[700], size: 24),
      cardTheme: const CardThemeData(elevation: 2),
      fontFamily: 'Poppins',
    );
  }

  /// Ramadan dark theme
  static ThemeData get ramadanDarkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ramadanPrimary,
        brightness: Brightness.dark,
        primary: ramadanPrimary,
        secondary: ramadanSecondary,
        surface: const Color(0xFF1E3320),
      ),
      scaffoldBackgroundColor: const Color(0xFF121F14),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E3320),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(color: Colors.grey[400], size: 24),
      cardTheme: const CardThemeData(elevation: 2),
      fontFamily: 'Poppins',
    );
  }

  // Ramadan Colors - Premium, rich palette
  static const Color ramadanPrimary = Color(0xFF1A4326); // Deep Forest Green
  static const Color ramadanSecondary = Color(0xFFD4AF37); // Metallic Gold
  static const Color ramadanBackground = Color(0xFFFDFBF7); // Warm Ivory
  static const Color ramadanSurface = Color(0xFFFFFFFF);
  static const Color ramadanAccent = Color(0xFFFFD700); // Bright Gold

  /// Get greeting based on time
  static String get greeting {
    if (!isRamadan) return '';

    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 6) {
      return 'lbl_ramadan_kareem_suhoor'.tr;
    } else if (hour >= 6 && hour < 17) {
      return 'lbl_ramadan_kareem_fasting'.tr;
    } else if (hour >= 17 && hour < 19) {
      return 'lbl_ramadan_kareem_iftar'.tr;
    } else {
      return 'lbl_ramadan_kareem_evening'.tr;
    }
  }

  /// Decorative pattern widget for Ramadan
  static Widget buildDecorativePattern({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ramadanPrimary, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: ramadanPrimary.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(Icons.mosque, size: size * 0.5, color: ramadanAccent),
    );
  }

  /// Ramadan badge widget
  static Widget buildRamadanBadge({double size = 24}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RamadanTheme.ramadanPrimary, Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: RamadanTheme.ramadanPrimary.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mosque,
            size: size * 0.6,
            color: RamadanTheme.ramadanAccent,
          ),
          const SizedBox(width: 4),
          Text(
            'lbl_ramadan'.tr,
            style: TextStyle(
              fontSize: size * 0.4,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that conditionally shows Ramadan content
class RamadanWrapper extends StatelessWidget {
  final Widget child;
  final Widget? ramadanOverlay;
  final bool showBadge;

  const RamadanWrapper({
    super.key,
    required this.child,
    this.ramadanOverlay,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!RamadanTheme.isRamadan) return child;

    return Stack(
      children: [
        child,
        if (showBadge)
          Positioned(top: 8, right: 8, child: RamadanTheme.buildRamadanBadge()),
        ?ramadanOverlay,
      ],
    );
  }
}

/// Ramadan countdown widget
class RamadanCountdown extends StatelessWidget {
  const RamadanCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    if (!RamadanTheme.isRamadan) return const SizedBox.shrink();

    final daysLeft = RamadanTheme.daysUntilEid;
    final ramadanDay = RamadanTheme.currentRamadanDay;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A24), // Dark forest green
            Color(0xFF112615), // Deepest green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: RamadanTheme.ramadanSecondary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: RamadanTheme.ramadanPrimary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background decorative icon
            const Positioned(
              right: -30,
              bottom: -30,
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.mosque,
                    size: 180,
                    color: RamadanTheme.ramadanAccent,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: RamadanTheme.ramadanAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'lbl_ramadan_kareem'.tr,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            if (ramadanDay != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'lbl_day_of_ramadan'.tr.replaceAll(
                                  '{day}',
                                  ramadanDay.toString(),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: RamadanTheme.ramadanSecondary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: RamadanTheme.ramadanSecondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.date_range_rounded,
                          color: RamadanTheme.ramadanAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'lbl_days_until_eid'.tr.replaceAll(
                              '{days}',
                              daysLeft.toString(),
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: RamadanTheme.ramadanAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
