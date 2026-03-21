import 'package:easyconnect/Models/user_model.dart';

/// État immutable de l'authentification (Riverpod).
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool showPassword;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.showPassword = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? showPassword,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      showPassword: showPassword ?? this.showPassword,
    );
  }
}
