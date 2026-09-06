import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../data/repositories/audit_repository.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardStats extends Equatable {
  const DashboardStats({
    this.employees = 0,
    this.activeEmployees = 0,
    this.departments = 0,
    this.families = 0,
    this.donations = 0,
    this.expenses = 0,
    this.inventoryItems = 0,
    this.pendingApprovals = 0,
    this.recentActivities = const [],
  });

  final int employees;
  final int activeEmployees;
  final int departments;
  final int families;
  final int donations;
  final int expenses;
  final int inventoryItems;
  final int pendingApprovals;
  final List<AuditEntry> recentActivities;

  @override
  List<Object?> get props => [
        employees,
        activeEmployees,
        departments,
        families,
        donations,
        expenses,
        inventoryItems,
        pendingApprovals,
        recentActivities,
      ];
}

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.status = DashboardStatus.initial,
    this.stats = const DashboardStats(),
    this.error = '',
  });

  final DashboardStatus status;
  final DashboardStats stats;
  final String error;

  @override
  List<Object?> get props => [status, stats, error];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({
    AuditRepository? auditRepository,
  }) : _auditRepository = auditRepository ?? sl<AuditRepository>(),
       super(const AdminDashboardState()) {
    // Excel: إحصائيات دورية تحديث تلقائي كل 30 ثانية.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  final AuditRepository _auditRepository;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;

  Future<void> refresh() async {
    if (!isClosed && state.status != DashboardStatus.loading) {
      emit(const AdminDashboardState(status: DashboardStatus.loading));
    }
    try {
      final results = await Future.wait([
        _count('users', isDeletedFilter: true),
        _count('users', isDeletedFilter: true, isActiveFilter: true),
        _count('departments', isDeletedFilter: true),
        _count('family_cases', isDeletedFilter: false),
        _count('donations', isDeletedFilter: false),
        _count('expenses', isDeletedFilter: false),
        _count('stock_items', isDeletedFilter: false),
        _count('approval_requests', statusFilter: 'pending'),
      ]);

      List<AuditEntry> recent = const [];
      try {
        recent = await _auditRepository.watchRecent(limit: 8).first;
      } catch (_) {}

      if (!isClosed) {
        emit(AdminDashboardState(
          status: DashboardStatus.loaded,
          stats: DashboardStats(
            employees: results[0],
            activeEmployees: results[1],
            departments: results[2],
            families: results[3],
            donations: results[4],
            expenses: results[5],
            inventoryItems: results[6],
            pendingApprovals: results[7],
            recentActivities: recent,
          ),
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminDashboardState(status: DashboardStatus.error, error: e.toString()));
      }
    }
  }

  Future<int> _count(
    String collection, {
    bool isDeletedFilter = false,
    bool isActiveFilter = false,
    String? statusFilter,
  }) async {
    try {
      var query = _db.collection(collection) as Query<Map<String, dynamic>>;
      if (isDeletedFilter) query = query.where('isDeleted', isEqualTo: false);
      if (isActiveFilter) query = query.where('isActive', isEqualTo: true);
      if (statusFilter != null) query = query.where('status', isEqualTo: statusFilter);
      final snap = await query.count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}