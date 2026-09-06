import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/user_profile.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.profile,
    this.status = AuthStatus.unknown,
    this.errorMessage,
  });

  final User? user;
  final UserProfile? profile;
  final AuthStatus status;
  final String? errorMessage;

  bool get isAuthenticated => user != null && status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [user, profile, status, errorMessage];
}

enum AuthStatus {
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
  signingOut,
  error,
}