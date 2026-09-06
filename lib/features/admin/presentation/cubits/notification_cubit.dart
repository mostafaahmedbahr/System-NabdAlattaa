import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audit_service.dart';
import '../../../../core/di/injection.dart';
import '../../data/repositories/notification_repository.dart';

enum NotificationStatus { initial, loading, loaded, empty, error }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.saving = false,
    this.error = '',
    this.message,
  });

  final NotificationStatus status;
  final List<AppNotification> notifications;
  final bool saving;
  final String error;
  final String? message;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    bool? saving,
    String? error,
    String? message,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, notifications, saving, error, message];
}

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    NotificationRepository? repository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<NotificationRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const NotificationState()) {
    _repository.watchNotifications().listen((notifications) {
      if (!isClosed) {
        emit(state.copyWith(
          status: notifications.isEmpty
              ? NotificationStatus.empty
              : NotificationStatus.loaded,
          notifications: notifications,
        ));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: NotificationStatus.error, error: 'تعذر تحميل الإشعارات'));
      }
    });
  }

  final NotificationRepository _repository;
  final AuditService _audit;

  Future<void> send({
    required String title,
    required String body,
    String type = 'general',
    String target = 'all',
    String targetId = '',
    String actorName = '',
  }) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.send(
        title: title,
        body: body,
        type: type,
        target: target,
        targetId: targetId,
        sentByName: actorName,
      );
      await _audit.log(
        module: 'notifications',
        action: 'send',
        message: 'أرسل إشعارًا: $title',
      );
      emit(state.copyWith(saving: false, message: 'تم إرسال الإشعار'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}