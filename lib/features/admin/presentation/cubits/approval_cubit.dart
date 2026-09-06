import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/audit_service.dart';
import '../../data/repositories/approval_repository.dart';

enum ApprovalStatus { initial, loading, loaded, empty, error }

class ApprovalState extends Equatable {
  const ApprovalState({
    this.status = ApprovalStatus.initial,
    this.requests = const [],
    this.saving = false,
    this.error = '',
    this.message,
  });

  final ApprovalStatus status;
  final List<PendingApproval> requests;
  final bool saving;
  final String error;
  final String? message;

  ApprovalState copyWith({
    ApprovalStatus? status,
    List<PendingApproval>? requests,
    bool? saving,
    String? error,
    String? message,
  }) {
    return ApprovalState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, requests, saving, error, message];
}

class ApprovalCubit extends Cubit<ApprovalState> {
  ApprovalCubit({
    ApprovalRepository? repository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<ApprovalRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const ApprovalState()) {
    _repository.watchPending().listen((requests) {
      if (!isClosed) {
        emit(state.copyWith(
          status: requests.isEmpty ? ApprovalStatus.empty : ApprovalStatus.loaded,
          requests: requests,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: ApprovalStatus.error, error: 'تعذر تحميل الطلبات'));
      }
    });
  }

  final ApprovalRepository _repository;
  final AuditService _audit;

  Future<void> decide(
    PendingApproval request, {
    required bool approve,
    String reason = '',
    String actorName = '',
  }) async {
    emit(state.copyWith(saving: true));
    try {
      final decidedById = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _repository.decide(
        requestId: request.id,
        approve: approve,
        decidedById: decidedById,
        decidedByName: actorName,
        reason: reason,
      );
      await _audit.log(
        module: request.module,
        action: approve ? 'approve' : 'reject',
        recordId: request.recordId,
        message: '${approve ? 'اعتمد' : 'رفض'} طلب ${request.module} للرقم ${request.recordId}',
      );
      emit(state.copyWith(saving: false, message: approve ? 'تم الاعتماد' : 'تم الرفض'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}