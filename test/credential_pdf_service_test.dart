import 'package:asisteqr_baker/features/credentials/data/credential_pdf_service.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera una hoja PDF de credenciales a doble cara', () async {
    const students = [
      CredentialStudent(
        id: 'est-0148',
        code: 'EST-2026-0148',
        fullName: 'Valeria Mendoza Rojas',
        course: '4.º Secundaria B',
        qrPayload: 'AQB1.test_pdf_fixture',
      ),
    ];

    final bytes = await CredentialPdfService().build(
      students: students,
      mode: CredentialPrintMode.doubleSided,
    );

    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
