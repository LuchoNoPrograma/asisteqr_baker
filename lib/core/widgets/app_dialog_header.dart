import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppDialogHeader extends StatelessWidget {
  const AppDialogHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      const SizedBox(width: 12),
      IconButton.filled(
        tooltip: 'Cerrar',
        onPressed: () => Navigator.pop(context),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.redSoft,
          foregroundColor: AppColors.red,
          minimumSize: const Size.square(40),
          maximumSize: const Size.square(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(LucideIcons.x, size: 20),
      ),
    ],
  );
}
