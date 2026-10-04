import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isAuthed = await _authService.isAuthenticated();
      UserModel? user;
      if (isAuthed) {
        user = await _authService.fetchCurrentUser();
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: isAuthed,
        user: user,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authService.login(email: email, password: password);
      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (result.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? 'Signup failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _authService.requestPasswordReset(email: email);
      state = state.copyWith(isLoading: false);
      return success;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to send reset instructions',
      );
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? currency,
    double? monthlyIncomeTarget,
    double? monthlySavingsTarget,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _authService.updateProfile(
        fullName: fullName,
        phone: phone,
        currency: currency,
        monthlyIncomeTarget: monthlyIncomeTarget,
        monthlySavingsTarget: monthlySavingsTarget,
      );
      state = state.copyWith(isLoading: false, user: updated);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState(
      isLoading: false,
      isAuthenticated: false,
      user: null,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthService(apiClient: client);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});
