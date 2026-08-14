import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';

class MockCredentialRepository implements CredentialRepository {
  static const _entries = [
    ('148', 'Valeria Mendoza Rojas', '4.º Secundaria B'),
    ('109', 'Carlos Martínez Silva', '4.º Secundaria A'),
    ('201', 'Ana Lucía Torres', '5.º Secundaria C'),
    ('320', 'Javier López Quispe', '3.º Secundaria B'),
    ('187', 'Sofía Vargas Molina', '4.º Secundaria B'),
    ('244', 'Mateo Fernández Paz', '5.º Secundaria A'),
    ('286', 'Luciana Rojas Flores', '5.º Secundaria A'),
    ('63', 'Daniel Choque Mamani', '3.º Secundaria A'),
    ('125', 'Camila Gutiérrez León', '4.º Secundaria A'),
    ('308', 'Sebastián Arias Cruz', '5.º Secundaria C'),
    ('42', 'Mariana Pérez Soto', '3.º Secundaria A'),
    ('271', 'Gabriel Salazar Lima', '4.º Secundaria B'),
  ];

  @override
  Future<List<CredentialStudent>> getStudents() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return [
      for (final entry in _entries)
        CredentialStudent(
          id: 'est-${entry.$1}',
          code: entry.$1,
          fullName: entry.$2,
          course: entry.$3,
          managementYear: 2026,
          qrPayload: entry.$1 == '148'
              ? 'AQB1.test_credential_fixture'
              : 'AQB1.demo_${entry.$1}_2026',
          guardianName: 'Tutor registrado',
          guardianPhone: '70000000',
        ),
    ];
  }
}
