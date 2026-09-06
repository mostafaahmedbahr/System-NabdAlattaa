import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/audit_service.dart';
import '../../data/models/department.dart';
import '../../data/repositories/department_repository.dart';
import '../../data/repositories/employee_repository.dart';

enum DepartmentStatus { initial, loading, loaded, empty, error }

class DepartmentState extends Equatable {
  const DepartmentState({
    this.status = DepartmentStatus.initial,
    this.departments = const [],
    this.employeeCounts = const {},
    this.saving = false,
    this.error = '',
    this.message,
  });

  final DepartmentStatus status;
  final List<Department> departments;
  final Map<String, int> employeeCounts;
  final bool saving;
  final String error;
  final String? message;

  DepartmentState copyWith({
    DepartmentStatus? status,
    List<Department>? departments,
    Map<String, int>? employeeCounts,
    bool? saving,
    String? error,
    String? message,
  }) {
    return DepartmentState(
      status: status ?? this.status,
      departments: departments ?? this.departments,
      employeeCounts: employeeCounts ?? this.employeeCounts,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, departments, employeeCounts, saving, error, message];
}

class DepartmentCubit extends Cubit<DepartmentState> {
  DepartmentCubit({
    DepartmentRepository? repository,
    EmployeeRepository? employeeRepository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<DepartmentRepository>(),
        _employeeRepository = employeeRepository ?? sl<EmployeeRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const DepartmentState()) {
    _repository.watchDepartments().listen((departments) {
      if (!isClosed) {
        emit(state.copyWith(
          status: departments.isEmpty ? DepartmentStatus.empty : DepartmentStatus.loaded,
          departments: departments,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: DepartmentStatus.error, error: 'تعذر تحميل الأقسام'));
      }
    });

    // حسابات الموظفين دون استعلامات مركبة (يتطلب فهارس).
    _employeeRepository.watchEmployees().listen((employees) {
      if (isClosed) return;
      final counts = <String, int>{};
      for (final e in employees) {
        if (e.departmentId.isEmpty) continue;
        counts[e.departmentId] = (counts[e.departmentId] ?? 0) + 1;
      }
      emit(state.copyWith(employeeCounts: counts));
    }, onError: (_) {});
  }

  final DepartmentRepository _repository;
  final EmployeeRepository _employeeRepository;
  final AuditService _audit;

  Future<void> addDepartment({
    required String name,
    String description = '',
    String icon = 'category',
    String color = '#00695C',
  }) async {
    emit(state.copyWith(saving: true));
    try {
      final id = await _repository.addDepartment(Department(
        id: '',
        name: name.trim(),
        description: description.trim(),
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        createdBy: _currentActor,
      ));
      await _audit.log(
        module: 'departments',
        action: 'add',
        recordId: id,
        message: 'أضاف قسمًا جديدًا: $name',
      );
      emit(state.copyWith(saving: false, message: 'تم إضافة القسم'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> updateDepartment(
    Department department, {
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateDepartment(department.id, {
        'name': name ?? department.name,
        'description': description ?? department.description,
        'icon': icon ?? department.icon,
        'color': color ?? department.color,
      });
      await _audit.log(
        module: 'departments',
        action: 'edit',
        recordId: department.id,
        message: 'عدّل بيانات القسم ${department.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم حفظ التعديلات'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> toggleActive(Department department, bool active) async {
    await _repository.toggleActive(department.id, active);
    await _audit.log(
      module: 'departments',
      action: active ? 'activate' : 'deactivate',
      recordId: department.id,
      message: '${active ? 'فعّل' : 'عطّل'} القسم ${department.name}',
    );
    emit(state.copyWith(message: active ? 'تم تفعيل القسم' : 'تم تعطيل القسم'));
  }

  /// أرشفة القسم: لا يُحذف نهائيًا مهما حدث.
  Future<void> archive(Department department) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.archive(department.id);
      await _audit.log(
        module: 'departments',
        action: 'archive',
        recordId: department.id,
        message: 'أرشف القسم ${department.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم أرشفة القسم'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

String get _currentActor => FirebaseAuth.instance.currentUser?.uid ?? '';
}