import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:asisteqr_baker/core/widgets/institution_mark.dart';
import 'package:flutter/material.dart';

class BrandedWorkspace extends StatelessWidget {
  const BrandedWorkspace({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final markSize = wide
              ? (constraints.maxWidth * 0.42).clamp(360.0, 560.0)
              : (constraints.maxWidth * 0.82).clamp(230.0, 330.0);

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: wide ? -markSize * 0.08 : -markSize * 0.22,
                bottom: wide ? -markSize * 0.14 : markSize * 0.08,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: wide ? 0.045 : 0.035,
                      child: Image.asset(
                        InstitutionMark.blueAsset,
                        width: markSize,
                        height: markSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          );
        },
      ),
    );
  }
}
