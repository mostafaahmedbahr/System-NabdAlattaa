import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/app_permissions.dart';
import '../../../../core/security/permission_registry.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../../admin/data/repositories/bootstrap_repository.dart';
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
        _emitAuthenticated,
        onError: (_) {
          emit(AuthState(user: user, status: AuthStatus.authenticated));
        },
      );
    });
  }

  void _emitAuthenticated(UserProfile? profile) {
    final user = _lastUser;
    if (user == null) return;
    _lastProfile = profile;
    emit(AuthState(
      user: user,
      profile: profile,
      permissions: profile != null
          ? AppPermissions.fromProfile(profile)
          : AppPermissions.empty,
      status: AuthStatus.authenticated,
    ));
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthState(status: AuthStatus.authenticating));
    try {
      await _repository.signIn(email.trim(), password);
      final user = _repository.currentUser;
      if (user != null) {
        await _profileRepository.recordLogin(user.uid);
      }
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
        // أول مستخدم في النظام يحصل على دور المدير، والباقي مدخل بيانات.
        final isFirst = await _profileRepository.isFirstUser();
        final roleId = isFirst ? 'admin' : 'data_entry';
        final roleName =
            PermissionRegistry.seedRoles[roleId]!.name;
        final perms = PermissionRegistry.seedRoles[roleId]!.permissions;
        await _profileRepository.saveProfile(UserProfile(
          uid: user.uid,
          name: name,
          phone: phone,
          department: department,
          email: email.trim(),
          createdAt: DateTime.now(),
          roleId: roleId,
          roleName: roleName,
          perms: Map.of(perms),
          createdBy: user.uid,
        ));
        // بعد إنشاء أول حساب-أدمن نزرع البيانات المرجعية مرة أخرى،
        // لأن قواعد Firestore قد تمنع الكتابة قبل وجود مستخدم مصادق.
        if (isFirst) {
          try {
            await BootstrapRepository.instance.ensureDefaults();
          } catch (_) {}
        }
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