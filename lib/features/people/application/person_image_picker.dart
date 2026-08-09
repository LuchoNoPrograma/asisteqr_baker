import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart' as image;

final class PersonImageException implements Exception {
  const PersonImageException(this.message);

  final String message;
}

final class PersonImageSource {
  PersonImageSource._(this._image, this.previewBytes);

  static const _outputSize = 640;
  static const _outputQuality = 84;

  final image.Image _image;
  final Uint8List previewBytes;

  static PersonImageSource decode(Uint8List bytes) {
    image.Image? decoded;
    try {
      decoded = image.decodeImage(bytes);
    } catch (_) {
      throw const PersonImageException('No se pudo leer esa imagen.');
    }
    if (decoded == null) {
      throw const PersonImageException('No se pudo leer esa imagen.');
    }
    final oriented = image.bakeOrientation(decoded);
    final longestSide = math.max(oriented.width, oriented.height);
    final working = longestSide <= PersonImagePicker._maxWorkingDimension
        ? oriented
        : oriented.width >= oriented.height
        ? image.copyResize(
            oriented,
            width: PersonImagePicker._maxWorkingDimension,
            interpolation: image.Interpolation.cubic,
          )
        : image.copyResize(
            oriented,
            height: PersonImagePicker._maxWorkingDimension,
            interpolation: image.Interpolation.cubic,
          );
    return PersonImageSource._(
      working,
      Uint8List.fromList(image.encodeJpg(working, quality: 86)),
    );
  }

  int get width => _image.width;
  int get height => _image.height;

  String encodeSquare({
    required double centerX,
    required double centerY,
    required double zoom,
  }) {
    final shortestSide = math.min(width, height);
    final cropSize = (shortestSide / zoom.clamp(1, 4)).round().clamp(
      1,
      shortestSide,
    );
    final x = (centerX - cropSize / 2).round().clamp(0, width - cropSize);
    final y = (centerY - cropSize / 2).round().clamp(0, height - cropSize);
    final cropped = image.copyCrop(
      _image,
      x: x,
      y: y,
      width: cropSize,
      height: cropSize,
    );
    final square = image.copyResize(
      cropped,
      width: _outputSize,
      height: _outputSize,
      interpolation: image.Interpolation.cubic,
    );
    final encoded = image.encodeJpg(square, quality: _outputQuality);
    return 'data:image/jpeg;base64,${base64Encode(encoded)}';
  }
}

abstract final class PersonImagePicker {
  static const _maxInputBytes = 12 * 1024 * 1024;
  static const _maxWorkingDimension = 1600;

  static Future<PersonImageSource?> pick() async {
    const group = XTypeGroup(
      label: 'fotografías',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxInputBytes) {
      throw const PersonImageException(
        'La imagen supera 12 MB. Elige una fotografía más liviana.',
      );
    }
    return PersonImageSource.decode(bytes);
  }
}
