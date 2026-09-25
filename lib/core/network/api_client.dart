import 'package:sis_amerinst/core/config/app_config.dart';
import 'package:sis_amerinst/core/network/session_invalidation_notifier.dart';
import 'package:sis_amerinst/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(
    this._tokens, {
    SessionInvalidationNotifier? sessionInvalidation,
    Dio? httpClient,
  }) : _sessionInvalidation =
           sessionInvalidation ?? SessionInvalidationNotifier(),
       dio = httpClient ?? Dio(_baseOptions()) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.readToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/autenticacion/')) {
            final authorization = error.requestOptions.headers['Authorization']
                ?.toString();
            final requestToken = authorization?.startsWith('Bearer ') == true
                ? authorization!.substring('Bearer '.length)
                : null;
            final currentToken = await _tokens.readToken();
            if (requestToken != null && requestToken == currentToken) {
              await _tokens.clear();
              _sessionInvalidation.invalidate();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final SecureTokenStore _tokens;
  final SessionInvalidationNotifier _sessionInvalidation;
  final Dio dio;

  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );
}
