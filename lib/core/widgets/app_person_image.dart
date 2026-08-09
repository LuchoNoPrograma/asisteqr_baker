import 'dart:convert';

import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppPersonImage extends StatelessWidget {
  const AppPersonImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.fallback,
    this.width,
    this.height,
  });

  final String? source;
  final BoxFit fit;
  final Widget? fallback;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final value = source?.trim();
    final placeholder =
        fallback ??
        const ColoredBox(
          color: AppColors.blueSoft,
          child: Center(
            child: Icon(LucideIcons.userRound, color: AppColors.navy, size: 28),
          ),
        );
    Widget sized(Widget child) => width == null && height == null
        ? child
        : SizedBox(width: width, height: height, child: child);
    if (value == null || value.isEmpty) return sized(placeholder);

    final comma = value.indexOf(',');
    if (value.startsWith('data:image/') && comma > 0) {
      try {
        return Image.memory(
          base64Decode(value.substring(comma + 1)),
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => placeholder,
        );
      } on FormatException {
        return sized(placeholder);
      }
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return Image.asset(
      value,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class AppPersonAvatar extends StatelessWidget {
  const AppPersonAvatar({
    super.key,
    required this.source,
    required this.fallback,
    this.size = 40,
  });

  final String? source;
  final String fallback;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipOval(
      child: AppPersonImage(
        source: source,
        fallback: ColoredBox(
          color: AppColors.blueSoft,
          child: Center(
            child: Text(
              fallback,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
