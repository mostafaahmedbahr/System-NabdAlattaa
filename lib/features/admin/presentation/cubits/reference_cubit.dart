import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/audit_service.dart';
import '../../data/models/reference_config.dart';
import '../../data/models/reference_item.dart';
import '../../data/repositories/reference_repository.dart';

enum ReferenceStatus { initial, loading, loaded, empty, error }

class ReferenceState extends Equatable {
  const ReferenceState({
    this.status = ReferenceStatus.initial,
    this.items = const [],
    this.saving = false,
    this.error = '',
    this.message,
  });

  final ReferenceStatus status;
  final List<ReferenceItem> items;
  final bool saving;
  final String error;
  final String? message;

  ReferenceState copyWith({
    ReferenceStatus? status,
    List<ReferenceItem>? items,
    bool? saving,
    String? error,
    String? message,
  }) {
    return ReferenceState(
      status: status ?? this.status,
      items: items ?? this.items,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, items, saving, error, message];
}

/// Cubit عام لأي قائمة مرجعية يحددها `ReferenceKind`.
class ReferenceCubit extends Cubit<ReferenceState> {
  ReferenceCubit(
    this.kind, {
    ReferenceRepository? repository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<ReferenceRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const ReferenceState()) {
    _subscribe();
  }

  final ReferenceKind kind;
  final ReferenceRepository _repository;
  final AuditService _audit;

  ReferenceConfig get config => ReferenceConfig.of(kind);

  void _subscribe() {
    _repository.watchItems(kind).listen((items) {
      if (!isClosed) {
        emit(state.copyWith(
          status: items.isEmpty ? ReferenceStatus.empty : ReferenceStatus.loaded,
          items: items,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: ReferenceStatus.error, error: 'تعذر تحميل ${config.title}'));
      }
    });
  }

  Future<void> addItem({
    required String name,
    String description = '',
    String icon = 'category',
    String color = '#00695C',
    Map<String, dynamic> extra = const {},
  }) async {
    emit(state.copyWith(saving: true));
    try {
      final id = await _repository.addItem(
        kind,
        ReferenceItem(
          id: '',
          name: name.trim(),
          description: description.trim(),
          icon: icon,
          color: color,
          extra: extra,
        ),
      );
      await _audit.log(
        module: config.collection,
        action: 'add',
        recordId: id,
        message: 'أضاف ${config.singularLabel}: $name',
      );
      emit(state.copyWith(saving: false, message: 'تمت الإضافة'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> updateItem(
    ReferenceItem item, {
    String? name,
    String? description,
    String? icon,
    String? color,
    Map<String, dynamic>? extra,
  }) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateItem(kind, item.id, {
        'name': name ?? item.name,
        'description': description ?? item.description,
        'icon': icon ?? item.icon,
        'color': color ?? item.color,
        'extra': ?extra,
      });
      await _audit.log(
        module: config.collection,
        action: 'edit',
        recordId: item.id,
        message: 'عدّل ${config.singularLabel}: ${item.name}',
      );
      emit(state.copyWith(saving: false, message: 'تم حفظ التعديلات'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> toggleActive(ReferenceItem item, bool active) async {
    await _repository.toggleActive(kind, item.id, active);
    await _audit.log(
      module: config.collection,
      action: active ? 'activate' : 'deactivate',
      recordId: item.id,
      message: '${active ? 'فعّل' : 'عطّل'} ${config.singularLabel}: ${item.name}',
    );
    emit(state.copyWith(message: active ? 'تم التفعيل' : 'تم التعطيل'));
  }

  Future<void> archive(ReferenceItem item) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.archive(kind, item.id);
      await _audit.log(
        module: config.collection,
        action: 'archive',
        recordId: item.id,
        message: 'أرشف ${config.singularLabel}: ${item.name}',
      );
      emit(state.copyWith(saving: false, message: 'تمت الأرشفة'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}