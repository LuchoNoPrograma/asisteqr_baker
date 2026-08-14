import 'package:asisteqr_baker/features/credentials/data/credential_pdf_service.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera anverso y reverso de la credencial en una hoja PDF', () async {
    const students = [
      CredentialStudent(
        id: 'est-0148',
        code: '1',
        fullName: 'Valeria Mendoza Rojas',
        course: '4.º Secundaria B',
        managementYear: 2026,
        qrPayload: 'AQB1.test_pdf_fixture',
        guardianName: 'Ana Rojas',
        guardianPhone: '71234567',
      ),
      CredentialStudent(
        id: 'est-0027',
        code: '27',
        fullName: 'Carlos Quispe Flores',
        course: '5.º Secundaria A',
        managementYear: 2026,
        qrPayload: 'AQB1.test_pdf_fixture_0027',
        guardianName: 'Marta Flores',
        guardianPhone: '76543210',
      ),
    ];

    final bytes = await CredentialPdfService().build(
      students: students,
      mode: CredentialPrintMode.frontAndBack,
    );

    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
