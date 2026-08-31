import 'dart:async';
import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/network/session_invalidation_notifier.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:asisteqr_baker/features/auth/presentation/session_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'envía la sesión opaca y la elimina cuando el servidor responde 401',
    () async {
      final tokens = _MemoryTokenStore('sesion-opaca');
      final invalidation = SessionInvalidationNotifier();
      final adapter = _UnauthorizedAdapter();
      final httpClient = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(
        tokens,
        sessionInvalidation: invalidation,
        httpClient: httpClient,
      );
      final session = SessionViewModel(_RestoredAuthRepository(), invalidation);
      addTearDown(session.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(session.status, SessionStatus.signedIn);

      await expectLater(
        client.dio.get<List<dynamic>>('/docentes'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.authorization, 'Bearer sesion-opaca');
      expect(await tokens.readToken(), isNull);
      expect(session.status, SessionStatus.signedOut);
      expect(session.user, isNull);
      expect(session.errorMessage, contains('expiró'));
    },
  );

  test('un 401 tardío no elimina el token de una sesión nueva', () async {
    final tokens = _MemoryTokenStore('sesion-anterior');
    final invalidation = SessionInvalidationNotifier();
    final adapter = _DelayedUnauthorizedAdapter();
    final httpClient = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      tokens,
      sessionInvalidation: invalidation,
      httpClient: httpClient,
    );

    final request = client.dio.get<List<dynamic>>('/docentes');
    await adapter.requestReceived.future;
    await tokens.writeToken('sesion-nueva');
    adapter.respond();

    await expectLater(request, throwsA(isA<DioException>()));
    expect(await tokens.readToken(), 'sesion-nueva');
    expect(invalidation.invalidated, isFalse);
  });
}

class _RestoredAuthRepository implements AuthRepository {
  @override
  Future<SessionUser?> restoreSession() async => const SessionUser(
    id: 1,
    name: 'Administrador Baker',
    role: 'ADMINISTRADOR',
  );

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _MemoryTokenStore extends SecureTokenStore {
  _MemoryTokenStore(this.token);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization = options.headers['Authorization']?.toString();
    return ResponseBody.fromString(
      jsonEncode({'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedUnauthorizedAdapter implements HttpClientAdapter {
  final requestReceived = Completer<void>();
  final _response = Completer<ResponseBody>();

  void respond() {
    _response.complete(
      ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestReceived.complete();
    return _response.future;
  }

  @override
  void close({bool force = false}) {}
}
