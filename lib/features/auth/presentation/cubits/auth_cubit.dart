import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    AuthRepository? repository,
    UserProfileRepository? profileRepository,
  })  : _repository = repository ?? AuthRepository.instance,
        _profileRepository = profileRepository ?? UserProfileRepository.instance,
        super(const AuthState()) {
    _subscribe();
  }

  final AuthRepository _repository;
  final UserProfileRepository _profileRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  User? _lastUser;
  UserProfile? _lastProfile;

  void _subscribe() {
    _authSubscription = _repository.watchUser().listen((user) {
      _profileSubscription?.cancel();
      if (user == null) {
        _lastUser = null;
        _lastProfile = null;
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      _lastUser = user;
      emit(AuthState(user: user, status: AuthStatus.authenticated));
      _profileSubscription = _profileRepository.watchProfile(user.uid).listen(
        (profile) {
          _lastProfile = profile;
          emit(AuthState(
            user: user,
            profile: profile,
            status: AuthStatus.authenticated,
          ));
        },
        onError: (_) {
          emit(AuthState(user: user, status: AuthStatus.authenticated));
        },
      );
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthState(status: AuthStatus.authenticating));
    try {
      await _repository.signIn(email.trim(), password);
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _repository.getErrorMessage(e),
      ));
    }
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String department,
    required String email,
    required String password,
  }) async {
    emit(AuthState(status: AuthStatus.authenticating));
    try {
      await _repository.signUp(email, password, name);
      final user = _repository.currentUser;
      if (user != null) {
        await _profileRepository.saveProfile(UserProfile(
          uid: user.uid,
          name: name,
          phone: phone,
          department: department,
          email: email.trim(),
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.error,
        errorMessage: _repository.getErrorMessage(e),
      ));
    }
  }

  Future<void> signOut() async {
    emit(AuthState(
      user: _lastUser,
      profile: _lastProfile,
      status: AuthStatus.signingOut,
    ));
    try {
      await _repository.signOut();
    } catch (e) {
      emit(AuthState(
        user: _lastUser,
        profile: _lastProfile,
        status: AuthStatus.authenticated,
        errorMessage: _repository.getErrorMessage(e),
      ));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    return super.close();
  }
}