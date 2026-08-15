import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:dio/dio.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.acceptedUsername = testUsername,
    this.acceptedPassword = testPassword,
  });

  static const testUsername = 'test-admin';
  static const testPassword = 'test-password';

  final String acceptedUsername;
  final String acceptedPassword;
  SessionUser? _session;

  @override
  Future<SessionUser?> restoreSession() async => _session;

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (username != acceptedUsername || password != acceptedPassword) {
      throw const AuthException('Usuario o contraseña incorrectos.');
    }
    return _session = const SessionUser(
      id: 'admin-1',
      name: 'Administrador Baker',
      role: 'ADMINISTRADOR',
    );
  }

  @override
  Future<void> signOut() async => _session = null;
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._tokens);
  final ApiClient _client;
  final SecureTokenStore _tokens;

  @override
  Future<SessionUser?> restoreSession() async {
    final token = await _tokens.readToken();
    if (token == null) return null;
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/autenticacion/sesion',
      );
      return _user(response.data!['usuario'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/autenticacion/iniciar-sesion',
        data: {'usuario': username, 'contrasena': password},
      );
      final body = response.data!;
      await _tokens.writeToken(body['token'].toString());
      final user = body['usuario'] as Map<String, dynamic>;
      return _user(user);
    } on DioException catch (error) {
      final data = error.response?.data;
      final body = data is Map ? data : null;
      final serverMessage = body?['mensaje'] ?? body?['message'];
      final message = switch (serverMessage) {
        List<dynamic> values when values.isNotEmpty => values.first.toString(),
        String value when value.trim().isNotEmpty => value,
        _ when error.response == null =>
          'No se pudo conectar con el servidor. Verifica que la API esté encendida.',
        _ => 'No fue posible iniciar sesión.',
      };
      throw AuthException(message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.dio.post<void>('/autenticacion/cerrar-sesion');
    } on DioException {
      // La sesión local debe cerrarse incluso si el token ya venció.
    } finally {
      await _tokens.clear();
    }
  }

  SessionUser _user(Map<String, dynamic> user) => SessionUser(
    id: user['id'].toString(),
    name: user['nombreCompleto'].toString(),
    role: user['rol'].toString(),
  );
}
