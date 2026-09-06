import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../data/repositories/audit_repository.dart';

enum AuditStatus { initial, loading, loaded, empty, error }

class AuditState extends Equatable {
  const AuditState({
    this.status = AuditStatus.initial,
    this.entries = const [],
  });

  final AuditStatus status;
  final List<AuditEntry> entries;

  @override
  List<Object?> get props => [status, entries];
}

class AuditCubit extends Cubit<AuditState> {
  AuditCubit({AuditRepository? repository})
      : _repository = repository ?? sl<AuditRepository>(),
        super(const AuditState()) {
    _repository.watchRecent().listen((entries) {
      if (!isClosed) {
        emit(AuditState(
          status: entries.isEmpty ? AuditStatus.empty : AuditStatus.loaded,
          entries: entries,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(const AuditState(status: AuditStatus.error));
      }
    });
  }

  final AuditRepository _repository;
}