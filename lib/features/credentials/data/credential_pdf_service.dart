import 'dart:convert';
import 'dart:io';

import 'package:asisteqr_baker/features/credentials/domain/credential_document_generator.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CredentialPdfService implements CredentialDocumentGenerator {
  static const _frontsPerPage = 8;
  static const _completeCredentialsPerPage = 4;
  static const _cardWidth = 85.6 * PdfPageFormat.mm;
  static const _cardHeight = 54 * PdfPageFormat.mm;

  @override
  Future<Uint8List> build({
    required List<CredentialStudent> students,
    required CredentialPrintMode mode,
  }) async {
    final managementYears =
        students.map((student) => student.managementYear).toSet().toList()
          ..sort();
    final managementLabel = managementYears.isEmpty
        ? ''
        : ' ${managementYears.join(', ')}';
    final document = pw.Document(
      title: 'Credenciales estudiantiles$managementLabel',
      author: 'AsisteQR Baker',
      subject: 'Credenciales QR listas para imprimir',
    );
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'),
    );
    final blueMark = pw.MemoryImage(
      _bytes(await rootBundle.load('assets/branding/baker-mark-blue.png')),
    );
    final frontTemplate = pw.MemoryImage(
      _bytes(
        await rootBundle.load('assets/branding/credential-front-template.png'),
      ),
    );
    final backTemplate = pw.MemoryImage(
      _bytes(
        await rootBundle.load('assets/branding/credential-back-template.png'),
      ),
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

    final studentsPerPage = mode == CredentialPrintMode.frontAndBack
        ? _completeCredentialsPerPage
        : _frontsPerPage;
    for (var start = 0; start < students.length; start += studentsPerPage) {
      final end = (start + studentsPerPage).clamp(0, students.length).toInt();
      final batch = students.sublist(start, end);
      document.addPage(switch (mode) {
        CredentialPrintMode.frontAndBack => _completeCredentialSheet(
          batch,
          photos,
          theme,
          blueMark: blueMark,
          frontTemplate: frontTemplate,
          backTemplate: backTemplate,
        ),
        CredentialPrintMode.frontOnly => _frontSheet(
          batch,
          photos,
          theme,
          blueMark: blueMark,
          frontTemplate: frontTemplate,
        ),
      });
    }
    return document.save();
  }

  pw.Page _completeCredentialSheet(
    List<CredentialStudent> students,
    Map<String, pw.MemoryImage> photos,
    pw.ThemeData theme, {
    required pw.MemoryImage blueMark,
    required pw.MemoryImage frontTemplate,
    required pw.MemoryImage backTemplate,
  }) {
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
          for (var index = 0; index < students.length; index++) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _credentialFront(
                  students[index],
                  photos[students[index].photoSource],
                  blueMark,
                  frontTemplate,
                ),
                pw.SizedBox(width: 4 * PdfPageFormat.mm),
                _credentialBack(students[index], blueMark, backTemplate),
              ],
            ),
            if (index < students.length - 1)
              pw.SizedBox(height: 4 * PdfPageFormat.mm),
          ],
        ],
      ),
    );
  }

  pw.Page _frontSheet(
    List<CredentialStudent> students,
    Map<String, pw.MemoryImage> photos,
    pw.ThemeData theme, {
    required pw.MemoryImage blueMark,
    required pw.MemoryImage frontTemplate,
  }) {
    final slots = List<CredentialStudent?>.filled(_frontsPerPage, null);
    for (var index = 0; index < students.length; index++) {
      slots[index] = students[index];
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
                _frontSlot(slots[row * 2], photos, blueMark, frontTemplate),
                pw.SizedBox(width: 4 * PdfPageFormat.mm),
                _frontSlot(slots[row * 2 + 1], photos, blueMark, frontTemplate),
              ],
            ),
            if (row < 3) pw.SizedBox(height: 4 * PdfPageFormat.mm),
          ],
        ],
      ),
    );
  }

  pw.Widget _frontSlot(
    CredentialStudent? student,
    Map<String, pw.MemoryImage> photos,
    pw.MemoryImage blueMark,
    pw.MemoryImage frontTemplate,
  ) => student == null
      ? pw.SizedBox(width: _cardWidth, height: _cardHeight)
      : _credentialFront(
          student,
          photos[student.photoSource],
          blueMark,
          frontTemplate,
        );

  pw.Widget _credentialFront(
    CredentialStudent student,
    pw.MemoryImage? photo,
    pw.MemoryImage blueMark,
    pw.MemoryImage frontTemplate,
  ) {
    return _card(
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Image(frontTemplate, fit: pw.BoxFit.fill),
          ),
          pw.Column(
            children: [
              _header(subtitle: 'CREDENCIAL ESTUDIANTIL', mark: blueMark),
              pw.Expanded(
                child: pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(
                    8.5 * PdfPageFormat.mm,
                    3 * PdfPageFormat.mm,
                    3.5 * PdfPageFormat.mm,
                    2.5 * PdfPageFormat.mm,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 29 * PdfPageFormat.mm,
                        height: 29 * PdfPageFormat.mm,
                        decoration: pw.BoxDecoration(
                          color: _cyan,
                          shape: pw.BoxShape.circle,
                        ),
                        padding: pw.EdgeInsets.all(1.5 * PdfPageFormat.mm),
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            color: _royalBlue,
                            shape: pw.BoxShape.circle,
                          ),
                          padding: pw.EdgeInsets.all(.9 * PdfPageFormat.mm),
                          child: pw.ClipOval(
                            child: photo == null
                                ? pw.Container(
                                    color: _blueSoft,
                                    alignment: pw.Alignment.center,
                                    child: pw.Text(
                                      student.initials,
                                      style: pw.TextStyle(
                                        color: _navy,
                                        fontSize: 18,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : pw.Image(photo, fit: pw.BoxFit.cover),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 3 * PdfPageFormat.mm),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'IDENTIDAD ESTUDIANTIL',
                                  style: pw.TextStyle(
                                    color: _cyanDark,
                                    fontSize: 5.4,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: .35,
                                  ),
                                ),
                                pw.Spacer(),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 5.5,
                                    vertical: 2.5,
                                  ),
                                  color: _navy,
                                  child: pw.Text(
                                    'CÓD. ${student.code}',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 6.2,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            _field('ESTUDIANTE', student.fullName, 8.8),
                            pw.SizedBox(height: 3),
                            _field('CURSO', student.course, 7.3),
                            pw.Spacer(),
                            pw.Container(
                              width: double.infinity,
                              padding: const pw.EdgeInsets.only(top: 4),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  top: pw.BorderSide(color: _cyan, width: 1.1),
                                ),
                              ),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    flex: 3,
                                    child: _field(
                                      'TUTOR/A',
                                      _valueOrFallback(student.guardianName),
                                      6.6,
                                    ),
                                  ),
                                  pw.SizedBox(width: 4),
                                  pw.Expanded(
                                    flex: 2,
                                    child: _field(
                                      'CONTACTO',
                                      _valueOrFallback(student.guardianPhone),
                                      6.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              'USO PERSONAL E INTRANSFERIBLE',
                              style: pw.TextStyle(
                                color: _navy,
                                fontSize: 5.2,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: .25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _credentialBack(
    CredentialStudent student,
    pw.MemoryImage blueMark,
    pw.MemoryImage backTemplate,
  ) {
    final status = student.active ? 'ACTIVA' : 'INACTIVA';
    return _card(
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Image(backTemplate, fit: pw.BoxFit.fill),
          ),
          pw.Column(
            children: [
              _header(
                subtitle: 'CONTROL DE ASISTENCIA',
                mark: blueMark,
                subtitleAlignmentY: -.55,
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: pw.EdgeInsets.fromLTRB(
                    4 * PdfPageFormat.mm,
                    3 * PdfPageFormat.mm,
                    3.5 * PdfPageFormat.mm,
                    2.5 * PdfPageFormat.mm,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 31 * PdfPageFormat.mm,
                        height: 35 * PdfPageFormat.mm,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: _navy, width: 1.2),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Column(
                          children: [
                            pw.SizedBox(height: 2),
                            pw.Container(
                              width: 9 * PdfPageFormat.mm,
                              height: 2.3 * PdfPageFormat.mm,
                              decoration: pw.BoxDecoration(
                                color: _navy,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Padding(
                                padding: pw.EdgeInsets.all(
                                  1.4 * PdfPageFormat.mm,
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: student.qrPayload,
                                  drawText: false,
                                ),
                              ),
                            ),
                            pw.Container(
                              height: 5 * PdfPageFormat.mm,
                              color: _navy,
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'ESCANEAR',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 5.8,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 3.5 * PdfPageFormat.mm),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 5,
                                  height: 5,
                                  decoration: pw.BoxDecoration(
                                    color: student.active ? _green : _muted,
                                    shape: pw.BoxShape.circle,
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Text(
                                  'CREDENCIAL $status',
                                  style: pw.TextStyle(
                                    color: _navy,
                                    fontSize: 6.2,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'VALIDACIÓN DE INGRESO',
                              style: pw.TextStyle(
                                color: _ink,
                                fontSize: 8.4,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            _instruction(
                              '01',
                              'Presenta la credencial al ingresar.',
                            ),
                            pw.SizedBox(height: 3),
                            _instruction(
                              '02',
                              'Escanea el QR solo con AsisteQR Baker.',
                            ),
                            pw.Spacer(),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: _field(
                                    'VIGENCIA',
                                    'Gestión ${student.managementYear}',
                                    6.8,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  color: _cyanPale,
                                  child: pw.Text(
                                    'QR PERSONAL',
                                    style: pw.TextStyle(
                                      color: _navy,
                                      fontSize: 5.2,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'En caso de extravío, entrégala en Administración.',
                              style: const pw.TextStyle(
                                color: _muted,
                                fontSize: 5.6,
                                lineSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    required String subtitle,
    required pw.MemoryImage mark,
    double subtitleAlignmentY = 0,
  }) => pw.Container(
    height: 9 * PdfPageFormat.mm,
    padding: pw.EdgeInsets.only(left: 3.5 * PdfPageFormat.mm),
    child: pw.Row(
      children: [
        _schoolMark(mark),
        pw.SizedBox(width: 1.8 * PdfPageFormat.mm),
        pw.SizedBox(
          width: 22 * PdfPageFormat.mm,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'UNIDAD EDUCATIVA',
                style: pw.TextStyle(
                  color: _cyanDark,
                  fontSize: 4.8,
                  fontWeight: pw.FontWeight.bold,
                  lineSpacing: 0,
                ),
              ),
              pw.Text(
                'ADVENTISTA BAKER',
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 5.4,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 2 * PdfPageFormat.mm),
        pw.Expanded(
          child: pw.SizedBox(
            height: 9 * PdfPageFormat.mm,
            child: pw.Align(
              alignment: pw.Alignment(1, subtitleAlignmentY),
              child: pw.Container(
                width: double.infinity,
                height: 4.8 * PdfPageFormat.mm,
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 3 * PdfPageFormat.mm,
                ),
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 6.2,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 3.5 * PdfPageFormat.mm),
      ],
    ),
  );

  pw.Widget _schoolMark(pw.MemoryImage mark) => pw.SizedBox(
    width: 7 * PdfPageFormat.mm,
    height: 7 * PdfPageFormat.mm,
    child: pw.Image(mark, fit: pw.BoxFit.contain),
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

  pw.Widget _instruction(String number, String text) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 12,
        height: 12,
        color: _blueSoft,
        alignment: pw.Alignment.center,
        child: pw.Text(
          number,
          style: pw.TextStyle(
            color: _navy,
            fontSize: 5.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.SizedBox(width: 4),
      pw.Expanded(
        child: pw.Text(
          text,
          style: const pw.TextStyle(color: _ink, fontSize: 5.8, lineSpacing: 1),
        ),
      ),
    ],
  );

  String _valueOrFallback(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty
        ? 'No registrado'
        : normalized;
  }

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
  static const _royalBlue = PdfColor.fromInt(0xFF1727C9);
  static const _cyan = PdfColor.fromInt(0xFF08A7D8);
  static const _cyanDark = PdfColor.fromInt(0xFF087AA7);
  static const _cyanPale = PdfColor.fromInt(0xFFE5F6FC);
  static const _ink = PdfColor.fromInt(0xFF142033);
  static const _muted = PdfColor.fromInt(0xFF5B6470);
  static const _border = PdfColor.fromInt(0xFFD8DEE7);
  static const _green = PdfColor.fromInt(0xFF4F8F2F);
  static const _blueSoft = PdfColor.fromInt(0xFFEAF1F8);
}
