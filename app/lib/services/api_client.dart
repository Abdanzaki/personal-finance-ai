import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  const ApiException({
    this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;

  factory ApiException.fromDioException(DioException dioException) {
    int? code = dioException.response?.statusCode;
    String message = 'An unexpected network error occurred';
    dynamic responseData = dioException.response?.data;

    if (responseData != null) {
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('detail')) {
          final detail = responseData['detail'];
          if (detail is String) {
            message = detail;
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              message = first['msg'].toString();
            } else {
              message = detail.toString();
            }
          } else if (detail is Map && detail.containsKey('message')) {
            message = detail['message'].toString();
          } else {
            message = detail.toString();
          }
        } else if (responseData.containsKey('message')) {
          message = responseData['message'].toString();
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        message = responseData;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Network connection timed out. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          message = 'Cannot connect to server. Please verify backend is running.';
          break;
        default:
          message = dioException.message ?? 'Unknown network failure';
      }
    }

    return ApiException(statusCode: code, message: message, data: responseData);
  }

  bool get isAiNotConfigured {
    if (statusCode == 503) {
      if (data is Map && data['detail'] is Map && data['detail']['code'] == 'ai_not_configured') {
        return true;
      }
      if (message.toLowerCase().contains('not configured') ||
          message.toLowerCase().contains('gemini')) {
        return true;
      }
    }
    return false;
  }
}

class ApiClient {
  static const String defaultBaseUrl = 'http://localhost:8000/api/v1';

  final String baseUrl;
  final FlutterSecureStorage _storage;
  late final Dio dio;

  static const String keyAccessToken = 'auth_access_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyUserData = 'auth_user_data';

  ApiClient({
    String? baseUrl,
    FlutterSecureStorage? storage,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment('API_BASE_URL', defaultValue: defaultBaseUrl),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ) {
    dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip auth token for public auth endpoints
          final path = options.path;
          final isPublicAuth = path.contains('/auth/login') ||
              path.contains('/auth/signup') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/password-reset');

          if (!isPublicAuth && !options.headers.containsKey('Authorization')) {
            final token = await _storage.read(key: keyAccessToken);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          final is401 = err.response?.statusCode == 401;
          final isRefreshRequest = err.requestOptions.path.contains('/auth/refresh');
          final isLoginRequest = err.requestOptions.path.contains('/auth/login');

          if (is401 && !isRefreshRequest && !isLoginRequest) {
            // Attempt automatic token refresh
            final refreshToken = await _storage.read(key: keyRefreshToken);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Use a bare Dio instance to avoid interceptor recursion
                final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
                final response = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
                  final data = response.data as Map<String, dynamic>;
                  final newAccessToken = data['access_token'] as String;
                  final newRefreshToken = data['refresh_token'] as String?;

                  await _storage.write(key: keyAccessToken, value: newAccessToken);
                  if (newRefreshToken != null) {
                    await _storage.write(key: keyRefreshToken, value: newRefreshToken);
                  }

                  // Retry the original request with the new access token
                  final retryOptions = err.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                  final retryResponse = await dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                // Refresh failed; clear tokens to force user re-login
                await clearTokens();
              }
            } else {
              await clearTokens();
            }
          }

          return handler.next(err);
        },
      ),
    );
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: keyAccessToken);
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keyUserData);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
