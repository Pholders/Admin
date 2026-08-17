import 'package:equatable/equatable.dart';

/// Authentication state for the current admin session.
class AuthState extends Equatable {
  final String? token;
  final String? role;
  final String? userName;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.token,
    this.role,
    this.userName,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthState.initial() => const AuthState();

  bool get isAuthenticated => token != null && role != null;

  AuthState copyWith({
    String? token,
    String? role,
    String? userName,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearToken = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      role: clearToken ? null : (role ?? this.role),
      userName: clearToken ? null : (userName ?? this.userName),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [token, role, userName, isLoading, errorMessage, successMessage];
}
