import 'dart:convert';
import 'dart:typed_data';

import 'package:asisteqr_baker/features/people/application/person_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('recorta y normaliza la fotografía institucional a 640 px', () {
    final original = image.Image(width: 900, height: 600);
    image.fill(original, color: image.ColorRgb8(25, 80, 140));
    final source = PersonImageSource.decode(
      Uint8List.fromList(image.encodePng(original)),
    );

    final dataUrl = source.encodeSquare(
      centerX: source.width / 2,
      centerY: source.height / 2,
      zoom: 1.5,
    );
    final decoded = image.decodeJpg(
      base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1)),
    );

    expect(dataUrl, startsWith('data:image/jpeg;base64,'));
    expect(decoded, isNotNull);
    expect(decoded!.width, 640);
    expect(decoded.height, 640);
  });

  test('rechaza archivos que no son imágenes', () {
    expect(
      () => PersonImageSource.decode(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<PersonImageException>()),
    );
  });
}
