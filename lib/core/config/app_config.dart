import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const productionApiBaseUrl =
      'https://soft-miranda-luisfluoxetina-b6930636.koyeb.app/api/v1';
  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
    if (kReleaseMode) return productionApiBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://127.0.0.1:3000/api/v1';
  }
}
