import 'package:flutter/material.dart';

/// Shows a modal bottom sheet with the app's standard styling.
///
/// Features:
/// - Rounded top corners (20px radius)
/// - Optional drag handle
/// - Optional [DraggableScrollableSheet] wrapper for scrollable content
/// - Returns the result from the sheet
///
/// For simple non-scrollable sheets (e.g., a short list of options), set
/// [useDraggable] to `false` (the default).
///
/// For scrollable sheets that should be draggable, set [useDraggable] to `true`
/// and provide [initialSize], [minSize], and [maxSize]. The [builder] will
/// receive a [ScrollController] that should be passed to the scrollable widget.
///
/// Example — simple sheet:
/// ```dart
/// final result = await showAppBottomSheet<String>(
///   context: context,
///   builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [...]),
/// );
/// ```
///
/// Example — draggable sheet:
/// ```dart
/// final result = await showAppBottomSheet<String>(
///   context: context,
///   useDraggable: true,
///   initialSize: 0.7,
///   minSize: 0.5,
///   maxSize: 0.9,
///   builder: (context, scrollController) => ListView(controller: scrollController, ...),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController? scrollController)
      builder,
  bool useDraggable = false,
  bool showDragHandle = true,
  double initialSize = 0.5,
  double minSize = 0.3,
  double maxSize = 0.8,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: useDraggable,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      Widget content;
      if (useDraggable) {
        content = DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          expand: false,
          builder: (context, scrollController) {
            return builder(context, scrollController);
          },
        );
      } else {
        content = builder(context, null);
      }

      if (showDragHandle) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            Flexible(child: content),
          ],
        );
      }

      return SafeArea(child: content);
    },
  );
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
