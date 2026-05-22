import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_bloc.dart';
import 'package:hafiz_app/presentation/hifz/bloc/hifz_event.dart';

class HifzErrorView extends StatelessWidget {
  final String message;

  const HifzErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message.tr, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.read<HifzBloc>().add(LoadHifzEntries()),
              child: Text('lbl_retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
