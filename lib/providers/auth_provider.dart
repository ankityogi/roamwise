import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/config.dart';

// Represents current authentication states for flow debugging and UI rendering
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  // Factory constructor for starting/initial state
  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  // Helper method to clone state with modified parameters
  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState.initial()) {
    // Automatically inspect local cache for a saved token when provider starts
    checkAuthStatus();
  }

  String _parseDioError(DioException e, String fallback) {
    if (e.response?.data != null && e.response?.data is Map) {
      final msg = e.response!.data['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check if the server is running.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Please check your network and ensure the backend is running.';
    }
    return fallback;
  }

  /// Reads the locally cached JWT token and requests active user profile to verify validity
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Fetch profile using cached token in Authorization Headers
      final response = await _dio.get(
        '${AppConfig.baseUrl}/auth/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final user = UserModel.fromJson(response.data);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      // If server requests fail (e.g. token expired, database issue), clear local secure cache
      await _storage.delete(key: 'token');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired or connection failed.',
      );
    }
  }

  /// Log in user using email and password credentials
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data);

      // Cache token in secure memory storage
      await _storage.write(key: 'token', value: token);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e, 'Failed to log in. Please check connection.');
      state = AuthState(status: AuthStatus.error, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
    }
  }

  /// Register a new user account on the Node.js/Express server
  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _dio.post(
        '${AppConfig.baseUrl}/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data);

      // Cache token in secure memory storage
      await _storage.write(key: 'token', value: token);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e, 'Failed to register account. User might already exist.');
      state = AuthState(status: AuthStatus.error, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
    }
  }

  /// Update the current user's emergency contacts list on the backend
  Future<void> updateEmergencyContacts(List<EmergencyContactModel> contacts) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Session token is missing.');
      }

      final response = await _dio.put(
        '${AppConfig.baseUrl}/auth/emergency-contacts',
        data: {
          'contacts': contacts.map((c) => c.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final updatedUser = UserModel.fromJson(response.data);
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e, 'Failed to update emergency contacts.');
      state = state.copyWith(status: AuthStatus.authenticated, errorMessage: errorMsg);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.authenticated, errorMessage: e.toString());
    }
  }

  /// Authenticate user via Google Account
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled Google login dialog
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await _dio.post(
        '${AppConfig.baseUrl}/auth/google',
        data: {
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'googleId': googleUser.id,
        },
      );

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data);

      await _storage.write(key: 'token', value: token);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on DioException catch (e) {
      final errorMsg = _parseDioError(e, 'Failed to sign in with Google.');
      state = AuthState(status: AuthStatus.error, errorMessage: errorMsg);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Google Sign-In: ${e.toString()}',
      );
    }
  }

  /// Log out user, removing local cached tokens and Google session
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
    await _storage.delete(key: 'token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

// Declare a globally accessible Riverpod provider for client auth states
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
