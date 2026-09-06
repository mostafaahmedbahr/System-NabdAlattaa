import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/security/app_permissions.dart';
import '../../data/models/user_profile.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.profile,
    this.permissions,
    this.status = AuthStatus.unknown,
    this.errorMessage,
  });

  final User? user;
  final UserProfile? profile;
  final AppPermissions? permissions;
  final AuthStatus status;
  final String? errorMessage;

  bool get isAuthenticated => user != null && status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [user, profile, permissions, status, errorMessage];
}

enum AuthStatus {
  unknown,
  authenticating,
  authenticated,
  unauthenticated,
  signingOut,
  error,
}