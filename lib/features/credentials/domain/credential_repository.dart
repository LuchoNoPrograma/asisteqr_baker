import 'package:asisteqr_baker/features/credentials/domain/credential_models.dart';

abstract interface class CredentialRepository {
  Future<List<CredentialStudent>> getStudents();
}
