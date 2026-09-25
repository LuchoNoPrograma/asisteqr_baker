import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sis_amerinst/core/storage/windows_session_migration.dart';

class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  // Keep the existing storage key so a branding update preserves the session.
  static const _tokenKey = 'asisteqr_session_token';
  final FlutterSecureStorage _storage;
  String? _token;
  Future<void>? _migration;

  Future<void> _prepareStorage() async {
    if (!Platform.isWindows) return;
    final roaming = Platform.environment['APPDATA'];
    if (roaming == null || roaming.isEmpty) return;
    try {
      await (_migration ??= WindowsSessionMigration(roaming).run());
    } on FileSystemException {
      _migration = null;
      rethrow;
    }
  }

  Future<String?> readToken() async {
    await _prepareStorage();
    return _token ??= await _storage.read(key: _tokenKey);
  }

  Future<void> writeToken(String token) async {
    await _prepareStorage();
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    await _prepareStorage();
    _token = null;
    await _storage.deleteAll();
  }
}
