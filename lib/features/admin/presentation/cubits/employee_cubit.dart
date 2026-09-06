import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audit_service.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../data/models/role.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/role_repository.dart';

enum EmployeeStatus { initial, loading, loaded, empty, error }

class EmployeeState extends Equatable {
  const EmployeeState({
    this.status = EmployeeStatus.initial,
    this.employees = const [],
    this.roles = const [],
    this.saving = false,
    this.error = '',
    this.message,
  });

  final EmployeeStatus status;
  final List<UserProfile> employees;
  final List<Role> roles;
  final bool saving;
  final String error;
  final String? message;

  EmployeeState copyWith({
    EmployeeStatus? status,
    List<UserProfile>? employees,
    List<Role>? roles,
    bool? saving,
    String? error,
    String? message,
  }) {
    return EmployeeState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      roles: roles ?? this.roles,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props =>
      [status, employees, roles, saving, error, message];
}

class EmployeeCubit extends Cubit<EmployeeState> {
  EmployeeCubit({
    EmployeeRepository? repository,
    RoleRepository? roleRepository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<EmployeeRepository>(),
        _roleRepository = roleRepository ?? sl<RoleRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const EmployeeState()) {
    _subscribe();
  }

  final EmployeeRepository _repository;
  final RoleRepository _roleRepository;
  final AuditService _audit;

  void _subscribe() {
    _repository.watchEmployees().listen((emps) {
      _emit(
        status: emps.isEmpty ? EmployeeStatus.empty : EmployeeStatus.loaded,
        employees: emps,
      );
    }, onError: (e) {
      _emit(status: EmployeeStatus.error, error: e.toString());
    });
    _roleRepository.watchRoles().listen((roles) {
      _emit(roles: roles);
    }, onError: (_) {});
  }

  void _emit({
    EmployeeStatus? status,
    List<UserProfile>? employees,
    List<Role>? roles,
    bool? saving,
    String? error,
    String? message,
  }) {
    if (!isClosed) {
      emit(state.copyWith(
        status: status,
        employees: employees,
        roles: roles,
        saving: saving,
        error: error,
        message: message,
      ));
    }
  }

  int countInDepartment(String departmentId) {
    return state.employees
        .where((e) =>
            e.departmentId == departmentId &&
            e.isActive &&
            !e.isDeleted)
        .length;
  }

  Future<void> addEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Role role,
    String departmentId = '',
    String department = '',
    String jobTitle = '',
    String actorName = '',
  }) async {
    _emit(saving: true);
    try {
      final uid = await _repository.createEmployee(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
        departmentId: departmentId,
        department: department,
        jobTitle: jobTitle,
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      await _audit.log(
        module: 'employees',
        action: 'add',
        recordId: uid,
        message: 'أضاف موظفًا جديدًا: $name',
      );
      _emit(saving: false, message: 'تم إضافة الموظف $name بنجاح');
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }

  Future<void> updateEmployee(
    String uid, {
    required String name,
    required String phone,
    required String jobTitle,
    required String departmentId,
    required String department,
  }) async {
    _emit(saving: true);
    try {
      await _repository.updateEmployee(
        uid,
        name: name,
        phone: phone,
        jobTitle: jobTitle,
        departmentId: departmentId,
        department: department,
      );
      await _audit.log(
        module: 'employees',
        action: 'edit',
        recordId: uid,
        message: 'عدّل بيانات الموظف $name',
      );
      _emit(saving: false, message: 'تم حفظ التعديلات');
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }

  Future<void> changeRole(String uid, Role role, String employeeName) async {
    _emit(saving: true);
    try {
      await _repository.setRole(uid, role);
      await _audit.log(
        module: 'employees',
        action: 'edit',
        recordId: uid,
        message: 'غيّر دور الموظف $employeeName إلى ${role.name}',
      );
      _emit(saving: false, message: 'تم تغيير الدور إلى ${role.name}');
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }

  Future<void> changePermissions(
    String uid,
    Map<String, bool> overrides,
    String employeeName,
  ) async {
    _emit(saving: true);
    try {
      await _repository.setOverrides(uid, overrides);
      await _audit.log(
        module: 'employees',
        action: 'managePermissions',
        recordId: uid,
        message: 'غيّر صلاحيات الموظف $employeeName',
      );
      _emit(saving: false, message: 'تم تحديث صلاحيات $employeeName');
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }

  Future<void> toggleActive(String uid, bool active, String employeeName) async {
    _emit(saving: true);
    try {
      await _repository.toggleActive(uid, active);
      await _audit.log(
        module: 'employees',
        action: active ? 'activate' : 'deactivate',
        recordId: uid,
        message: '${active ? 'فعّل' : 'عطّل'} حساب الموظف $employeeName',
      );
      _emit(
        saving: false,
        message: active ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب',
      );
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }

  Future<void> archive(String uid, String employeeName) async {
    _emit(saving: true);
    try {
      await _repository.archive(uid);
      await _audit.log(
        module: 'employees',
        action: 'archive',
        recordId: uid,
        message: 'أرشف الموظف $employeeName',
      );
      _emit(saving: false, message: 'تم أرشفة الموظف $employeeName');
    } catch (e) {
      _emit(saving: false, error: e.toString());
    }
  }
}