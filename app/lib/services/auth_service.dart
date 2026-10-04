import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_client.dart';

export '../models/user.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;

  const AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthResult.success({
    required UserModel user,
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthResult(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService({
    ApiClient? apiClient,
    FlutterSecureStorage? storage,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiClient.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: ApiClient.keyRefreshToken);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    final raw = await _storage.read(key: ApiClient.keyUserData);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> fetchCurrentUser() async {
    try {
      final response = await _apiClient.get('/users/me');
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        await _storage.write(key: ApiClient.keyUserData, value: jsonEncode(user.toJson()));
        return user;
      }
    } catch (_) {
      // Return cached user if network fails
      return getCurrentUser();
    }
    return null;
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email and password are required');
    }

    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': cleanEmail,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await _saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        return AuthResult.success(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return AuthResult.failure('Login failed with status: ${response.statusCode}');
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Unexpected login error: $e');
    }
  }

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();

    if (cleanEmail.isEmpty || password.isEmpty || cleanName.isEmpty) {
      return AuthResult.failure('Full name, email, and password are required');
    }

    try {
      final response = await _apiClient.post(
        '/auth/signup',
        data: {
          'email': cleanEmail,
          'password': password,
          'full_name': cleanName,
          'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await _saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        return AuthResult.success(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return AuthResult.failure('Signup failed with status: ${response.statusCode}');
    } on ApiException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Unexpected signup error: $e');
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    try {
      final response = await _apiClient.post(
        '/auth/password-reset',
        data: {'email': email.trim()},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await _apiClient.clearTokens();
    }
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
    double? monthlyIncomeTarget,
    double? monthlySavingsTarget,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName.trim();
      if (phone != null) data['phone'] = phone.trim();
      if (currency != null) data['currency'] = currency.trim();
      if (monthlyIncomeTarget != null) data['monthly_income_target'] = monthlyIncomeTarget;
      if (monthlySavingsTarget != null) data['monthly_savings_target'] = monthlySavingsTarget;

      final response = await _apiClient.patch(
        '/users/me',
        data: data,
      );
      final updated = UserModel.fromJson(response.data as Map<String, dynamic>);
      await _storage.write(key: ApiClient.keyUserData, value: jsonEncode(updated.toJson()));
      return updated;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    await _storage.write(key: ApiClient.keyAccessToken, value: accessToken);
    await _storage.write(key: ApiClient.keyRefreshToken, value: refreshToken);
    await _storage.write(key: ApiClient.keyUserData, value: jsonEncode(user.toJson()));
  }
}
