import 'package:flutter/material.dart';
import '../core/app_export.dart';

/// Modern, scalable AppBar that handles overflow gracefully
/// - Shows only essential actions
/// - Moves overflow items to a popup menu
/// - Adapts to different screen sizes
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final List<Widget> actions;
  final List<PopupMenuItem<String>>? popupMenuItems;
  final Function(String)? onMenuItemSelected;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;

  const ModernAppBar({
    super.key,
    this.title = '',
    this.titleWidget,
    this.leadingIcon,
    this.onLeadingPressed,
    this.actions = const [],
    this.popupMenuItems,
    this.onMenuItemSelected,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? _buildTitle(),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leadingIcon != null
          ? IconButton(icon: Icon(leadingIcon), onPressed: onLeadingPressed)
          : null,
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    final actionWidgets = <Widget>[];

    // Add visible actions (max 2 to prevent overflow)
    final visibleActions = actions.take(2).toList();
    actionWidgets.addAll(visibleActions);

    // Add popup menu if there are more actions or menu items
    if (actions.length > 2 ||
        (popupMenuItems != null && popupMenuItems!.isNotEmpty)) {
      actionWidgets.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: onMenuItemSelected,
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];

            // Add overflow actions
            if (actions.length > 2) {
              for (var i = 2; i < actions.length; i++) {
                // Try to extract icon and text from the action widget
                if (actions[i] is IconButton) {
                  final button = actions[i] as IconButton;
                  items.add(
                    PopupMenuItem(
                      value: 'action_$i',
                      child: Row(
                        children: [
                          Icon((button.icon as Icon).icon, size: 20),
                          const SizedBox(width: 8),
                          Text(button.tooltip ?? 'lbl_action'.tr),
                        ],
                      ),
                    ),
                  );
                }
              }
              if (popupMenuItems != null && popupMenuItems!.isNotEmpty) {
                items.add(const PopupMenuDivider());
              }
            }

            // Add custom menu items
            if (popupMenuItems != null) {
              items.addAll(popupMenuItems!);
            }

            return items;
          },
        ),
      );
    }

    return actionWidgets;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Help/Onboarding button that shows feature documentation
class HelpButton extends StatelessWidget {
  final String title;
  final List<HelpSection> sections;

  const HelpButton({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline),
      onPressed: () => _showHelpDialog(context),
      tooltip: 'lbl_help'.tr,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return ExpansionTile(
                title: Text(
                  section.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(section.content),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('lbl_close'.tr),
          ),
        ],
      ),
    );
  }
}

class HelpSection {
  final String title;
  final String content;

  const HelpSection({required this.title, required this.content});
}
