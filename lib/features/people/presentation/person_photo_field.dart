import 'dart:convert';

import 'package:asisteqr_baker/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PersonPhotoField extends StatelessWidget {
  const PersonPhotoField({
    super.key,
    required this.photoUrl,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final String? photoUrl;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 470;
        final preview = Container(
          width: compact ? 104 : 124,
          height: compact ? 104 : 124,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _PersonPhoto(photoUrl: photoUrl),
        );
        final controls = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              'Fotografía institucional',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Se guardará en formato cuadrado para credenciales y asistencia.',
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.center : WrapAlignment.start,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('pick_person_photo'),
                  onPressed: busy ? null : onPick,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.imagePlus, size: 18),
                  label: Text(
                    photoUrl == null ? 'Elegir fotografía' : 'Cambiar',
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Quitar fotografía',
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(LucideIcons.trash2, size: 18),
                  ),
              ],
            ),
          ],
        );
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: compact
              ? Column(
                  children: [preview, const SizedBox(height: 12), controls],
                )
              : Row(
                  children: [
                    preview,
                    const SizedBox(width: 16),
                    Expanded(child: controls),
                  ],
                ),
        );
      },
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.photoUrl,
    required this.fallback,
    this.size = 40,
  });

  final String? photoUrl;
  final String fallback;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      color: AppColors.blueSoft,
      shape: BoxShape.circle,
    ),
    child: photoUrl == null
        ? Center(
            child: Text(
              fallback,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : ClipOval(child: _PersonPhoto(photoUrl: photoUrl)),
  );
}

class _PersonPhoto extends StatelessWidget {
  const _PersonPhoto({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final source = photoUrl;
    if (source == null || source.isEmpty) {
      return const Center(
        child: Icon(LucideIcons.userRound, size: 36, color: AppColors.navy),
      );
    }
    final comma = source.indexOf(',');
    if (source.startsWith('data:image/') && comma > 0) {
      try {
        return Image.memory(
          base64Decode(source.substring(comma + 1)),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _PhotoFallback(),
        );
      } on FormatException {
        return const _PhotoFallback();
      }
    }
    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _PhotoFallback(),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(LucideIcons.userRound, size: 34, color: AppColors.navy),
  );
}
