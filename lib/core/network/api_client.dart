import 'package:asisteqr_baker/core/config/app_config.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this._tokens, {Dio? httpClient, Dio? refreshClient})
    : dio = httpClient ?? Dio(_baseOptions()),
      _refreshDio = refreshClient ?? Dio(_baseOptions()) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokens.readAccessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final canRenew =
              error.response?.statusCode == 401 &&
              request.extra[_retryKey] != true &&
              !request.path.contains('/autenticacion/');
          if (!canRenew || !await renewSession()) {
            return handler.next(error);
          }

          final token = await _tokens.readAccessToken();
          request.extra[_retryKey] = true;
          request.headers['Authorization'] = 'Bearer $token';
          try {
            handler.resolve(await dio.fetch<dynamic>(request));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static const _retryKey = 'asisteqr_token_retried';

  final SecureTokenStore _tokens;
  final Dio dio;
  final Dio _refreshDio;
  Future<bool>? _renewing;

  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    headers: const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  Future<bool> renewSession() {
    final current = _renewing;
    if (current != null) return current;
    final renewal = _performRenewal();
    _renewing = renewal;
    return renewal.whenComplete(() {
      if (identical(_renewing, renewal)) _renewing = null;
    });
  }

  Future<bool> _performRenewal() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/autenticacion/renovar',
        data: {'tokenRenovacion': refreshToken},
      );
      final body = response.data;
      if (body == null) return false;
      await _tokens.writeTokens(
        accessToken: body['tokenAcceso'].toString(),
        refreshToken: body['tokenRenovacion'].toString(),
      );
      return true;
    } on DioException {
      await _tokens.clear();
      return false;
    }
  }
}
