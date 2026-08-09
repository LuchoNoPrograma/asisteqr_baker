import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      AttendanceStatus.punctual => (
        AppColors.greenSoft,
        const Color(0xFF166534),
        LucideIcons.circleCheck,
      ),
      AttendanceStatus.late => (
        AppColors.amberSoft,
        const Color(0xFF92400E),
        LucideIcons.clock3,
      ),
      AttendanceStatus.absent => (
        AppColors.redSoft,
        const Color(0xFF991B1B),
        LucideIcons.circleX,
      ),
    };
    return Semantics(
      label: 'Estado ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
            Text(
              status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
