import 'package:get_it/get_it.dart';

import '../../features/admin/data/repositories/admin_repositories.dart';
import '../../features/admin/data/repositories/audit_repository.dart';
import '../../features/admin/data/repositories/bootstrap_repository.dart';
import '../../features/admin/data/repositories/employee_repository.dart';
import '../../features/admin/data/repositories/settings_repository.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/user_profile_repository.dart';
import '../services/audit_service.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // خدمات عامة.
  sl.registerLazySingleton<AuditService>(() => AuditService.instance);

  // مستودعات.
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository.instance);
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepository.instance,
  );
  sl.registerLazySingleton<BootstrapRepository>(
    () => BootstrapRepository.instance,
  );
  sl.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepository.instance,
  );
  sl.registerLazySingleton<RoleRepository>(() => RoleRepository.instance);
  sl.registerLazySingleton<DepartmentRepository>(
    () => DepartmentRepository.instance,
  );
  sl.registerLazySingleton<ReferenceRepository>(
    () => ReferenceRepository.instance,
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository.instance,
  );
  sl.registerLazySingleton<AuditRepository>(() => AuditRepository.instance);
  sl.registerLazySingleton<ApprovalRepository>(
    () => ApprovalRepository.instance,
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository.instance,
  );
}