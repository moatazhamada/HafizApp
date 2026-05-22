import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

class LocalDataNote extends StatelessWidget {
  const LocalDataNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline, color: AppColors.of(context).notStartedStatus),
        title: Text('msg_recitation_progress'.tr),
        subtitle: Text('msg_local_data_note'.tr),
      ),
    );
  }
}
