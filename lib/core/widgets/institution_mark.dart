import 'package:sis_amerinst/core/config/app_brand.dart';
import 'package:flutter/material.dart';

enum InstitutionMarkVariant { blue, white }

class InstitutionMark extends StatelessWidget {
  const InstitutionMark({
    super.key,
    this.size = 24,
    this.variant = InstitutionMarkVariant.blue,
  });

  static const blueAsset = AppBrand.crestAsset;
  static const whiteAsset = AppBrand.crestAsset;
  static const compactAsset = AppBrand.crestAsset;

  final double size;
  final InstitutionMarkVariant variant;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppBrand.institution,
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
