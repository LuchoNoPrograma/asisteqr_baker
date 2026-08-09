import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'asisteqr_access_token';
  static const _refreshKey = 'asisteqr_refresh_token';
  final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  Future<String?> readAccessToken() async =>
      _accessToken ??= await _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() async =>
      _refreshToken ??= await _storage.read(key: _refreshKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.deleteAll();
  }
}
