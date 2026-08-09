import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';

class MockCredentialRepository implements CredentialRepository {
  static const _entries = [
    ('0148', 'Valeria Mendoza Rojas', '4.º Secundaria B'),
    ('0109', 'Carlos Martínez Silva', '4.º Secundaria A'),
    ('0201', 'Ana Lucía Torres', '5.º Secundaria C'),
    ('0320', 'Javier López Quispe', '3.º Secundaria B'),
    ('0187', 'Sofía Vargas Molina', '4.º Secundaria B'),
    ('0244', 'Mateo Fernández Paz', '5.º Secundaria A'),
    ('0286', 'Luciana Rojas Flores', '5.º Secundaria A'),
    ('0063', 'Daniel Choque Mamani', '3.º Secundaria A'),
    ('0125', 'Camila Gutiérrez León', '4.º Secundaria A'),
    ('0308', 'Sebastián Arias Cruz', '5.º Secundaria C'),
    ('0042', 'Mariana Pérez Soto', '3.º Secundaria A'),
    ('0271', 'Gabriel Salazar Lima', '4.º Secundaria B'),
  ];

  @override
  Future<List<CredentialStudent>> getStudents() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return [
      for (final entry in _entries)
        CredentialStudent(
          id: 'est-${entry.$1}',
          code: 'EST-2026-${entry.$1}',
          fullName: entry.$2,
          course: entry.$3,
          qrPayload: entry.$1 == '0148'
              ? 'AQB1.removed_fixture'
              : 'AQB1.demo_${entry.$1}_2026',
        ),
    ];
  }
}
