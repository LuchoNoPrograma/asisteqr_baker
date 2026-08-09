class SessionUser {
  const SessionUser({required this.id, required this.name, required this.role});
  final String id;
  final String name;
  final String role;

  bool get isAdministrator => role == 'ADMINISTRADOR';
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
