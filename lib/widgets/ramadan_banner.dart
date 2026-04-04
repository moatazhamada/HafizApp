import 'package:flutter/material.dart';
import '../../core/ramadan/ramadan_theme.dart';
import '../../core/ramadan/ramadan_date_manager.dart';
import '../../localization/app_localization.dart';
import '../../core/utils/number_converter.dart';

class RamadanBanner extends StatelessWidget {
  const RamadanBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!RamadanTheme.isRamadan) return const SizedBox.shrink();

    final daysUntilEid = RamadanDateManager.daysUntilEid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37), // Golden color
            const Color(0xFFB8860B).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'lbl_ramadan_kareem'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'msg_ramadan_blessings'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) => Text(
                      daysUntilEid > 0
                          ? 'lbl_days_until_eid'.tr.replaceAll(
                              '{days}',
                              daysUntilEid.toLocalizedNumber(context),
                            )
                          : 'lbl_eid_mubarak'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
