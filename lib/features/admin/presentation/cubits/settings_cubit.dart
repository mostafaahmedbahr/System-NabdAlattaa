import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audit_service.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/system_settings.dart';
import '../../data/repositories/settings_repository.dart';

enum SettingsStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const SystemSettings(),
    this.saving = false,
    this.error = '',
    this.message,
  });

  final SettingsStatus status;
  final SystemSettings settings;
  final bool saving;
  final String error;
  final String? message;

  SettingsState copyWith({
    SettingsStatus? status,
    SystemSettings? settings,
    bool? saving,
    String? error,
    String? message,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      saving: saving ?? this.saving,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, settings, saving, error, message];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    SettingsRepository? repository,
    AuditService? auditService,
  })  : _repository = repository ?? sl<SettingsRepository>(),
        _audit = auditService ?? sl<AuditService>(),
        super(const SettingsState()) {
    _repository.watchSettings().listen((settings) {
      if (!isClosed) {
        emit(state.copyWith(status: SettingsStatus.loaded, settings: settings));
      }
    }, onError: (_) {
      if (!isClosed) {
        emit(state.copyWith(status: SettingsStatus.error, error: 'تعذر تحميل الإعدادات'));
      }
    });
  }

  final SettingsRepository _repository;
  final AuditService _audit;

  Future<void> updateSociety(Map<String, dynamic> fields) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateSettings(fields);
      await _audit.log(
        module: 'settings',
        action: 'edit',
        message: 'عدّل بيانات الجمعية',
      );
      emit(state.copyWith(saving: false, message: 'تم حفظ إعدادات الجمعية'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> updateSystem(Map<String, dynamic> fields) async {
    emit(state.copyWith(saving: true));
    try {
      await _repository.updateSettings(fields);
      await _audit.log(
        module: 'settings',
        action: 'edit',
        message: 'عدّل إعدادات النظام',
      );
      emit(state.copyWith(saving: false, message: 'تم حفظ إعدادات النظام'));
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}