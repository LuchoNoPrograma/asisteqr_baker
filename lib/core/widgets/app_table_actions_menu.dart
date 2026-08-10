import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppTableAction {
  const AppTableAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
    this.dividerBefore = false,
  });

  const AppTableAction.deactivate({required this.onSelected})
    : label = 'Desactivar',
      icon = LucideIcons.circleOff,
      destructive = true,
      dividerBefore = true;

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
  final bool dividerBefore;
}

class AppTableActionsMenu extends StatelessWidget {
  const AppTableActionsMenu({
    super.key,
    required this.tooltip,
    required this.actions,
  });

  final String tooltip;
  final List<AppTableAction> actions;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AppTableAction>(
    tooltip: tooltip,
    icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
    position: PopupMenuPosition.under,
    constraints: const BoxConstraints(minWidth: 190, maxWidth: 260),
    onSelected: (action) => action.onSelected(),
    itemBuilder: (context) {
      final entries = <PopupMenuEntry<AppTableAction>>[];
      for (final action in actions) {
        if (action.dividerBefore && entries.isNotEmpty) {
          entries.add(const PopupMenuDivider());
        }
        entries.add(
          PopupMenuItem<AppTableAction>(
            value: action,
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: 18,
                  color: action.destructive ? AppColors.red : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: action.destructive
                        ? const TextStyle(color: AppColors.red)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return entries;
    },
  );
}
