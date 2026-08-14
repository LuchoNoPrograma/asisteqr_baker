import 'package:flutter/material.dart';

enum InstitutionMarkVariant { blue, white }

class InstitutionMark extends StatelessWidget {
  const InstitutionMark({
    super.key,
    this.size = 24,
    this.variant = InstitutionMarkVariant.blue,
  });

  static const blueAsset = 'assets/branding/baker-mark-blue.png';
  static const whiteAsset = 'assets/branding/baker-mark-white.png';
  static const compactAsset = 'assets/branding/baker-app-icon.png';

  final double size;
  final InstitutionMarkVariant variant;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Unidad Educativa Baker',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.18),
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          variant == InstitutionMarkVariant.white ? whiteAsset : compactAsset,
          fit: BoxFit.contain,
          cacheWidth: (size * 4).round(),
          cacheHeight: (size * 4).round(),
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
