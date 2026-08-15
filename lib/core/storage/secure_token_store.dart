import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'asisteqr_session_token';
  final FlutterSecureStorage _storage;
  String? _token;

  Future<String?> readToken() async =>
      _token ??= await _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _token = null;
    await _storage.deleteAll();
  }
}
