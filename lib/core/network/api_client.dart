import 'package:asisteqr_baker/core/config/app_config.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this._tokens, {Dio? httpClient})
    : dio = httpClient ?? Dio(_baseOptions()) {
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
            await _tokens.clear();
          }
          handler.next(error);
        },
      ),
    );
  }

  final SecureTokenStore _tokens;
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
