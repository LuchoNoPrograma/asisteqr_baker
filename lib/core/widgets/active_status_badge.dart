import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ActiveStatusBadge extends StatelessWidget {
  const ActiveStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final label = active ? 'ACTIVO' : 'INACTIVO';
    return Semantics(
      label: 'Estado $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.greenSoft : AppColors.redSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.green : AppColors.red,
            ),
          ),
        ),
      ),
    );
  }
}
