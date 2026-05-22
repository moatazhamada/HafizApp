import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/appearance_section.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/home_layout_section.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/notification_section.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/profile_card.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/reading_section.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/recitation_coach_section.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/storage_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lbl_settings'.tr)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 900;
          final horizontalPadding = isLarge ? 32.0 : 16.0;

          Widget content = ListView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            children: [
              const ProfileCard(),
              const SizedBox(height: 20),
              SectionLabel('lbl_appearance'.tr),
              const AppearanceSection(),
              const SizedBox(height: 20),
              SectionLabel('lbl_home_layout'.tr),
              const HomeLayoutSection(),
              const SizedBox(height: 20),
              SectionLabel('lbl_reading'.tr),
              const ReadingSection(),
              const SizedBox(height: 20),
              SectionLabel('lbl_notification_settings'.tr),
              const NotificationSection(),
              const SizedBox(height: 20),
              SectionLabel('lbl_recitation_coach'.tr),
              const RecitationCoachSection(),
              const SizedBox(height: 20),
              SectionLabel('lbl_storage'.tr),
              const StorageSection(),
              const SizedBox(height: 32),
            ],
          );

          if (isLarge) {
            content = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: content,
              ),
            );
          }

          return content;
        },
      ),
    );
  }
}
