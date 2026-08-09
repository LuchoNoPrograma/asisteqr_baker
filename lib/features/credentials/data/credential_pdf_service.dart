import 'dart:convert';
import 'dart:io';

import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CredentialPdfService {
  static const _cardsPerPage = 8;
  static const _cardWidth = 85.6 * PdfPageFormat.mm;
  static const _cardHeight = 54 * PdfPageFormat.mm;

  Future<Uint8List> build({
    required List<CredentialStudent> students,
    required CredentialPrintMode mode,
    int managementYear = 2026,
  }) async {
    final document = pw.Document(
      title: 'Credenciales estudiantiles $managementYear',
      author: 'AsisteQR Baker',
      subject: 'Credenciales QR listas para imprimir',
    );
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'),
    );
    final whiteMark = pw.MemoryImage(
      _bytes(await rootBundle.load('assets/branding/baker-mark-white.png')),
    );
    final blueMark = pw.MemoryImage(
      _bytes(await rootBundle.load('assets/branding/baker-mark-blue.png')),
    );
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    final photos = <String, pw.MemoryImage>{};
    for (final student in students) {
      final source = student.photoSource?.trim();
      if (source == null || source.isEmpty || photos.containsKey(source)) {
        continue;
      }
      final bytes = await _loadPhoto(source);
      if (bytes != null) photos[source] = pw.MemoryImage(bytes);
    }

    for (var start = 0; start < students.length; start += _cardsPerPage) {
      final end = (start + _cardsPerPage).clamp(0, students.length).toInt();
      final batch = students.sublist(start, end);
      document.addPage(
        _sheet(
          batch,
          photos,
          managementYear,
          theme,
          whiteMark: whiteMark,
          blueMark: blueMark,
          back: false,
        ),
      );
      if (mode == CredentialPrintMode.doubleSided) {
        document.addPage(
          _sheet(
            batch,
            photos,
            managementYear,
            theme,
            whiteMark: whiteMark,
            blueMark: blueMark,
            back: true,
          ),
        );
      }
    }
    return document.save();
  }

  pw.Page _sheet(
    List<CredentialStudent> students,
    Map<String, pw.MemoryImage> photos,
    int managementYear,
    pw.ThemeData theme, {
    required pw.MemoryImage whiteMark,
    required pw.MemoryImage blueMark,
    required bool back,
  }) {
    final slots = List<CredentialStudent?>.filled(_cardsPerPage, null);
    for (var index = 0; index < students.length; index++) {
      final slot = back ? _mirroredSlot(index) : index;
      slots[slot] = students[index];
    }
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: pw.EdgeInsets.symmetric(
        horizontal: 14 * PdfPageFormat.mm,
        vertical: 24 * PdfPageFormat.mm,
      ),
      build: (context) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          for (var row = 0; row < 4; row++) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _slot(
                  slots[row * 2],
                  photos,
                  managementYear,
                  back,
                  whiteMark,
                  blueMark,
                ),
                pw.SizedBox(width: 4 * PdfPageFormat.mm),
                _slot(
                  slots[row * 2 + 1],
                  photos,
                  managementYear,
                  back,
                  whiteMark,
                  blueMark,
                ),
              ],
            ),
            if (row < 3) pw.SizedBox(height: 4 * PdfPageFormat.mm),
          ],
        ],
      ),
    );
  }

  int _mirroredSlot(int index) => index.isEven ? index + 1 : index - 1;

  pw.Widget _slot(
    CredentialStudent? student,
    Map<String, pw.MemoryImage> photos,
    int managementYear,
    bool back,
    pw.MemoryImage whiteMark,
    pw.MemoryImage blueMark,
  ) {
    if (student == null) {
      return pw.SizedBox(width: _cardWidth, height: _cardHeight);
    }
    return back
        ? _credentialBack(student, managementYear, whiteMark)
        : _credentialFront(
            student,
            photos[student.photoSource],
            managementYear,
            whiteMark,
            blueMark,
          );
  }

  pw.Widget _credentialFront(
    CredentialStudent student,
    pw.MemoryImage? photo,
    int managementYear,
    pw.MemoryImage whiteMark,
    pw.MemoryImage blueMark,
  ) {
    return _card(
      child: pw.Column(
        children: [
          _header(
            title: 'UNIDAD EDUCATIVA\nADVENTISTA BAKER',
            subtitle: 'CREDENCIAL ESTUDIANTIL',
            mark: whiteMark,
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(
                4 * PdfPageFormat.mm,
                2.8 * PdfPageFormat.mm,
                4 * PdfPageFormat.mm,
                2 * PdfPageFormat.mm,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    width: 22 * PdfPageFormat.mm,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _border, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(1.5),
                    child: pw.ClipRRect(
                      horizontalRadius: 3,
                      verticalRadius: 3,
                      child: photo == null
                          ? pw.Container(
                              color: _blueSoft,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                student.initials,
                                style: pw.TextStyle(
                                  color: _navy,
                                  fontSize: 17,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            )
                          : pw.Image(photo, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(width: 3 * PdfPageFormat.mm),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _brandLine(blueMark),
                        pw.Spacer(),
                        _field('NOMBRE', student.fullName, 8.2),
                        pw.SizedBox(height: 2),
                        _field('CURSO', student.course, 7.4),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Expanded(
                              child: _field('CÓDIGO', student.code, 7.4),
                            ),
                            pw.SizedBox(width: 3),
                            pw.BarcodeWidget(
                              barcode: pw.Barcode.qrCode(),
                              data: student.qrPayload,
                              width: 13 * PdfPageFormat.mm,
                              height: 13 * PdfPageFormat.mm,
                              drawText: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(
            height: 6 * PdfPageFormat.mm,
            color: _navy,
            alignment: pw.Alignment.center,
            child: pw.Text(
              'USO PERSONAL E INTRANSFERIBLE  ·  GESTIÓN $managementYear',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 6.2,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: .3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _credentialBack(
    CredentialStudent student,
    int managementYear,
    pw.MemoryImage whiteMark,
  ) {
    return _card(
      child: pw.Column(
        children: [
          pw.Container(
            height: 10 * PdfPageFormat.mm,
            color: _navy,
            padding: pw.EdgeInsets.symmetric(horizontal: 5 * PdfPageFormat.mm),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CONTROL DE ASISTENCIA',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                _miniMark(whiteMark),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.all(4 * PdfPageFormat.mm),
              child: pw.Row(
                children: [
                  pw.Container(
                    padding: pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: _green, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: student.qrPayload,
                      width: 29 * PdfPageFormat.mm,
                      height: 29 * PdfPageFormat.mm,
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(width: 4 * PdfPageFormat.mm),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _field('ESTUDIANTE', student.fullName, 8.5),
                        pw.SizedBox(height: 5),
                        _field('CURSO', student.course, 8),
                        pw.SizedBox(height: 5),
                        _field('CÓDIGO', student.code, 8),
                        pw.Spacer(),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          color: _blueSoft,
                          child: pw.Text(
                            'Presenta esta credencial al ingresar. El QR registra tu asistencia en segundos.',
                            style: pw.TextStyle(
                              color: _navy,
                              fontSize: 6.2,
                              lineSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(
            height: 6 * PdfPageFormat.mm,
            color: _navy,
            alignment: pw.Alignment.center,
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
                children: [
                  const pw.TextSpan(text: 'Asiste'),
                  pw.TextSpan(
                    text: 'QR',
                    style: pw.TextStyle(
                      color: _greenLight,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.TextSpan(text: ' Baker  ·  Gestión $managementYear'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _card({required pw.Widget child}) => pw.ClipRRect(
    horizontalRadius: 7,
    verticalRadius: 7,
    child: pw.Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _border, width: .5),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: child,
    ),
  );

  pw.Widget _header({
    required String title,
    required String subtitle,
    required pw.MemoryImage mark,
  }) => pw.Container(
    height: 12 * PdfPageFormat.mm,
    color: _navy,
    padding: pw.EdgeInsets.symmetric(horizontal: 4 * PdfPageFormat.mm),
    child: pw.Row(
      children: [
        _schoolMark(mark),
        pw.SizedBox(width: 3 * PdfPageFormat.mm),
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  lineSpacing: 0,
                ),
              ),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  color: _greenLight,
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  pw.Widget _schoolMark(pw.MemoryImage mark) => pw.SizedBox(
    width: 9 * PdfPageFormat.mm,
    height: 9 * PdfPageFormat.mm,
    child: pw.Image(mark, fit: pw.BoxFit.contain),
  );

  pw.Widget _miniMark(pw.MemoryImage mark) => pw.SizedBox(
    width: 7 * PdfPageFormat.mm,
    height: 7 * PdfPageFormat.mm,
    child: pw.Image(mark, fit: pw.BoxFit.contain),
  );

  pw.Widget _brandLine(pw.MemoryImage mark) => pw.Row(
    children: [
      pw.SizedBox(
        width: 5 * PdfPageFormat.mm,
        height: 5 * PdfPageFormat.mm,
        child: pw.Image(mark, fit: pw.BoxFit.contain),
      ),
      pw.SizedBox(width: 3),
      pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(
            color: _navy,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          children: [
            const pw.TextSpan(text: 'Asiste'),
            pw.TextSpan(
              text: 'QR',
              style: pw.TextStyle(color: _green),
            ),
            const pw.TextSpan(text: ' Baker'),
          ],
        ),
      ),
    ],
  );

  pw.Widget _field(String label, String value, double size) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          color: _muted,
          fontSize: 5.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: .3,
        ),
      ),
      pw.Text(
        value,
        maxLines: 2,
        style: pw.TextStyle(
          color: _ink,
          fontSize: size,
          fontWeight: pw.FontWeight.bold,
          lineSpacing: 0,
        ),
      ),
    ],
  );

  Uint8List _bytes(ByteData data) =>
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  Future<Uint8List?> _loadPhoto(String source) async {
    try {
      final comma = source.indexOf(',');
      if (source.startsWith('data:image/') && comma > 0) {
        return base64Decode(source.substring(comma + 1));
      }
      if (!source.startsWith('http://') && !source.startsWith('https://')) {
        final data = await rootBundle.load(source);
        return data.buffer.asUint8List();
      }

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(source));
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      } finally {
        client.close(force: true);
      }
    } on Object {
      return null;
    }
  }

  static const _navy = PdfColor.fromInt(0xFF0B2A50);
  static const _ink = PdfColor.fromInt(0xFF142033);
  static const _muted = PdfColor.fromInt(0xFF5B6470);
  static const _border = PdfColor.fromInt(0xFFD8DEE7);
  static const _green = PdfColor.fromInt(0xFF4F8F2F);
  static const _greenLight = PdfColor.fromInt(0xFF9AD75A);
  static const _blueSoft = PdfColor.fromInt(0xFFEAF1F8);
}
