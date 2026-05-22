import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/core/notifications/notification_service.dart';
import 'package:hafiz_app/core/utils/rtl_utils.dart';
import 'package:hafiz_app/presentation/settings_screen/widgets/settings_utils.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  late bool _dailyVerseEnabled;
  late TimeOfDay _dailyVerseTime;
  late bool _readingReminderEnabled;
  late TimeOfDay _readingReminderTime;
  late bool _fridayKahfEnabled;
  late TimeOfDay _fridayKahfTime;

  @override
  void initState() {
    super.initState();
    _dailyVerseEnabled = PrefUtils().isDailyVerseEnabled();
    _dailyVerseTime = parseTime(PrefUtils().getDailyVerseTime());
    _readingReminderEnabled = PrefUtils().isReadingReminderEnabled();
    _readingReminderTime = parseTime(PrefUtils().getReadingReminderTime());
    _fridayKahfEnabled = PrefUtils().isFridayKahfEnabled();
    _fridayKahfTime = parseTime(PrefUtils().getFridayKahfTime());
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: [
        _buildDailyVerseTile(),
        const Divider(height: 1),
        _buildDailyVerseTimeTile(),
        const Divider(height: 1),
        _buildReadingReminderTile(),
        const Divider(height: 1),
        _buildReadingReminderTimeTile(),
        const Divider(height: 1),
        _buildFridayKahfTile(),
        const Divider(height: 1),
        _buildFridayKahfTimeTile(),
      ],
    );
  }

  Widget _buildDailyVerseTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_outlined),
      title: Text('lbl_daily_verse_notification'.tr),
      subtitle: Text('msg_daily_verse_desc'.tr),
      value: _dailyVerseEnabled,
      onChanged: (val) async {
        setState(() => _dailyVerseEnabled = val);
        await PrefUtils().setDailyVerseEnabled(val);
        final notificationService = NotificationService();
        if (val) {
          final ok = await notificationService.scheduleDailyVerse();
          if (!ok && mounted) {
            setState(() => _dailyVerseEnabled = false);
            await PrefUtils().setDailyVerseEnabled(false);
            if (mounted) {
              SnackBarHelper.show(
                context,
                message: 'msg_notification_permission_denied'.tr,
                type: SnackBarType.warning,
              );
            }
          }
        } else {
          await notificationService.cancelDailyVerse();
        }
      },
    );
  }

  Widget _buildDailyVerseTimeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('lbl_daily_verse_time'.tr),
      subtitle: Text(_dailyVerseTime.format(context)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _dailyVerseTime,
        );
        if (picked != null && picked != _dailyVerseTime) {
          setState(() => _dailyVerseTime = picked);
          await PrefUtils().setDailyVerseTime(formatTime(picked));
          await NotificationService().scheduleDailyVerse();
        }
      },
    );
  }

  Widget _buildReadingReminderTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.access_time),
      title: Text('lbl_reading_reminder'.tr),
      subtitle: Text('msg_reading_reminder_desc'.tr),
      value: _readingReminderEnabled,
      onChanged: (val) async {
        setState(() => _readingReminderEnabled = val);
        await PrefUtils().setReadingReminderEnabled(val);
        final notificationService = NotificationService();
        if (val) {
          final ok = await notificationService.scheduleReadingReminder();
          if (!ok && mounted) {
            setState(() => _readingReminderEnabled = false);
            await PrefUtils().setReadingReminderEnabled(false);
            if (mounted) {
              SnackBarHelper.show(
                context,
                message: 'msg_notification_permission_denied'.tr,
                type: SnackBarType.warning,
              );
            }
          }
        } else {
          await notificationService.cancelReadingReminder();
        }
      },
    );
  }

  Widget _buildReadingReminderTimeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('lbl_reading_reminder_time'.tr),
      subtitle: Text(_readingReminderTime.format(context)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _readingReminderTime,
        );
        if (picked != null && picked != _readingReminderTime) {
          setState(() => _readingReminderTime = picked);
          await PrefUtils().setReadingReminderTime(formatTime(picked));
          await NotificationService().scheduleReadingReminder();
        }
      },
    );
  }

  Widget _buildFridayKahfTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.mosque_outlined),
      title: Text('lbl_friday_kahf'.tr),
      subtitle: Text('msg_friday_kahf_desc'.tr),
      value: _fridayKahfEnabled,
      onChanged: (val) async {
        setState(() => _fridayKahfEnabled = val);
        await PrefUtils().setFridayKahfEnabled(val);
        final notificationService = NotificationService();
        if (val) {
          final ok = await notificationService.scheduleFridayKahf();
          if (!ok && mounted) {
            setState(() => _fridayKahfEnabled = false);
            await PrefUtils().setFridayKahfEnabled(false);
            if (mounted) {
              SnackBarHelper.show(
                context,
                message: 'msg_notification_permission_denied'.tr,
                type: SnackBarType.warning,
              );
            }
          }
        } else {
          await notificationService.cancelFridayKahf();
        }
      },
    );
  }

  Widget _buildFridayKahfTimeTile() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text('lbl_friday_kahf_time'.tr),
      subtitle: Text(_fridayKahfTime.format(context)),
      trailing: Icon(rtlChevron(context)),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _fridayKahfTime,
        );
        if (picked != null && picked != _fridayKahfTime) {
          setState(() => _fridayKahfTime = picked);
          await PrefUtils().setFridayKahfTime(formatTime(picked));
          await NotificationService().scheduleFridayKahf();
        }
      },
    );
  }
}
