import 'package:flutter/material.dart';
import 'package:hafiz_app/core/app_export.dart';
import '../bloc/verse_study_bloc.dart';

class ReflectionCard extends StatelessWidget {
  final String text;
  final String date;
  final String postId;

  const ReflectionCard({
    super.key,
    required this.text,
    required this.date,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'lbl_delete'.tr,
                  onPressed: () => context.read<VerseStudyBloc>().add(
                    DeleteReflection(postId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
