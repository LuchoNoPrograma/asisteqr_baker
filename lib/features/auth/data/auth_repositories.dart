import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:dio/dio.dart';

class MockAuthRepository implements AuthRepository {
  SessionUser? _session;

  @override
  Future<SessionUser?> restoreSession() async => _session;

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (username != 'admin' || password != 'removed-development-password') {
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
    var token = await _tokens.readAccessToken();
    if (token == null) return null;
    var claims = _claims(token);
    final expiresAt = (claims?['exp'] as num?)?.toInt();
    final expired =
        expiresAt == null ||
        DateTime.fromMillisecondsSinceEpoch(
          expiresAt * 1000,
          isUtc: true,
        ).isBefore(DateTime.now().toUtc());
    if (expired) {
      if (!await _client.renewSession()) return null;
      token = await _tokens.readAccessToken();
      claims = token == null ? null : _claims(token);
    }
    if (claims == null) {
      await _tokens.clear();
      return null;
    }
    final roles = claims['roles'] as List<dynamic>? ?? const [];
    return SessionUser(
      id: claims['sub']?.toString() ?? '',
      name: claims['usuario']?.toString() ?? 'Usuario Baker',
      role: roles.isEmpty ? 'DOCENTE' : roles.first.toString(),
    );
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
      await _tokens.writeTokens(
        accessToken: body['tokenAcceso'].toString(),
        refreshToken: body['tokenRenovacion'].toString(),
      );
      final user = body['usuario'] as Map<String, dynamic>;
      return SessionUser(
        id: user['id'].toString(),
        name: user['nombreCompleto'].toString(),
        role: user['rol'].toString(),
      );
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

  Map<String, dynamic>? _claims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      return jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          )
          as Map<String, dynamic>;
    } on Object {
      return null;
    }
  }
}
