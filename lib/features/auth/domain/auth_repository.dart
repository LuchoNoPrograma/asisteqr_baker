class SessionUser {
  const SessionUser({required this.id, required this.name, required this.role});
  final int id;
  final String name;
  final String role;

  bool get isAdministrator => role == 'ADMINISTRADOR';
  bool get isRegent => role == 'REGENTE';
  bool get canScan => isAdministrator || isRegent;
  bool get canViewAttendance =>
      isAdministrator || isRegent || role == 'DOCENTE';
  bool get canViewAcademicManagement => isAdministrator || role == 'DOCENTE';
}

abstract interface class AuthRepository {
  Future<SessionUser?> restoreSession();
  Future<SessionUser> signIn({
    required String username,
    required String password,
  });
  Future<void> signOut();
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
