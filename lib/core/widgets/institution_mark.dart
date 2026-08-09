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

  final double size;
  final InstitutionMarkVariant variant;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Unidad Educativa Baker',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: Image.asset(
        variant == InstitutionMarkVariant.white ? whiteAsset : blueAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    ),
  );
}
