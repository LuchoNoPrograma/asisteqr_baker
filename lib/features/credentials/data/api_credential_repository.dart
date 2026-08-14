import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';

class ApiCredentialRepository implements CredentialRepository {
  ApiCredentialRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CredentialStudent>> getStudents() async {
    final response = await _client.dio.post<List<dynamic>>(
      '/credenciales/imprimibles',
    );
    return (response.data ?? []).map((item) {
      final json = item as Map<String, dynamic>;
      final student =
          (json['estudiante'] as Map?)?.cast<String, dynamic>() ?? json;
      final courseValue = student['curso'];
      final courseJson = courseValue is Map
          ? courseValue.cast<String, dynamic>()
          : null;
      final course = courseJson != null
          ? courseJson['nombre']?.toString()
          : courseValue?.toString();
      final rawCode = student['codigoEstudiante'] ?? student['codigo'];
      final managementYear = (courseJson?['gestion'] as num?)?.toInt();
      final code = rawCode?.toString().trim();
      if (code == null || code.isEmpty) {
        throw const FormatException(
          'La API no devolvió el código del estudiante.',
        );
      }
      if (managementYear == null) {
        throw const FormatException(
          'La API no devolvió la gestión de la credencial.',
        );
      }
      final firstNames = student['nombres']?.toString() ?? '';
      final lastNames = student['apellidos']?.toString() ?? '';
      final fullName =
          student['nombreCompleto']?.toString() ??
          '$firstNames $lastNames'.trim();
      final qrPayload = json['tokenQr']?.toString();
      if (qrPayload == null || qrPayload.isEmpty) {
        throw const FormatException(
          'La API no devolvió un token QR imprimible.',
        );
      }
      return CredentialStudent(
        id: student['id'].toString(),
        code: code,
        fullName: fullName,
        course: course ?? 'Sin curso',
        managementYear: managementYear,
        qrPayload: qrPayload,
        guardianName: student['nombreTutor']?.toString(),
        guardianPhone: student['telefonoTutor']?.toString(),
        photoSource: student['fotografiaUrl']?.toString(),
        active: student['estado']?.toString() != 'INACTIVO',
      );
    }).toList();
  }
}
