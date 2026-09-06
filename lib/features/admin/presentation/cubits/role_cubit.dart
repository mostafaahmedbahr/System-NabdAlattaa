import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/audit_service.dart';
import '../../data/models/role.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/role_repository.dart';

enum RoleStatus { initial, loading, loaded, empty, error }

class RoleState extends Equatable {
  const RoleState({
    this.status = RoleStatus.initial,
    this.roles = const [],
    this.saving = false,
    this.error = '',
    this.message,
  });

  final RoleStatus status;
  final List<Role> roles;
  final bool saving;
  final String error;
  final String? message;

  RoleState copyWith({
    RoleStatus? status,
    List<Role>? roles,
    bool? saving,
    String? error,
    String? message,
  }) {
    return RoleState(
      status: status ?? this.status,
      roles: roles ?? this.roles,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, roles, saving, error, message];
}

class RoleCubit extends Cubit<RoleState> {
  RoleCubit({
    RoleRepository? repository,
    EmployeeRepository? employeeRepository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<RoleRepository>(),
        _employeeRepository = employeeRepository ?? sl<EmployeeRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const RoleState()) {
    _repository.watchRoles().listen((roles) {
      if (!isClosed) {
        emit(state.copyWith(
          status: roles.isEmpty ? RoleStatus.empty : RoleStatus.loaded,
          roles: roles,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: RoleStatus.error, error: 'تعذر تحميل الأدوار'));
      }
    });
  }

  final RoleRepository _repository;
  final EmployeeRepository _employeeRepository;
  final AuditService _audit;

  Future<void> addRole({
    required String id,
    required String name,
    String description = '',
    Map<String, bool> permissions = const {},
  }) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.addRole(
        id: id.trim(),
        name: name.trim(),
        description: description.trim(),
        permissions: permissions,
      );
      await _audit.log(
        module: 'employees',
        action: 'managePermissions',
        message: 'أضاف دورًا جديدًا: $name',
      );
      emit(state.copyWith(saving: false, message: 'تم إضافة الدور'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> updateRole(Role role, {String? name, String? description}) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateRole(role.id, {
        'name': name ?? role.name,
        'description': description ?? role.description,
      });
      await _audit.log(
        module: 'employees',
        action: 'managePermissions',
        recordId: role.id,
        message: 'عدّل بيانات الدور ${role.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم حفظ التعديلات'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  /// حفظ مصفوفة الصلاحيات الجديدة للدور ثم تحديث rollup لكل الأعضاء.
  Future<void> updatePermissions(Role role, Map<String, bool> permissions) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateRolePermissions(role.id, permissions);
      await _employeeRepository.recomputeForRole(role.id, permissions);
      await _audit.log(
        module: 'employees',
        action: 'managePermissions',
        recordId: role.id,
        message: 'عدّل صلاحيات الدور ${role.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم تحديث صلاحيات الدور'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> archive(Role role) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.archiveRole(role.id);
      await _audit.log(
        module: 'employees',
        action: 'managePermissions',
        recordId: role.id,
        message: 'أرشف الدور ${role.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم أرشفة الدور'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}