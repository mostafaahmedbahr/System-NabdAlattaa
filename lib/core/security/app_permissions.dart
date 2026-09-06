import '../../features/auth/data/models/user_profile.dart';

/// مجموعة الصلاحيات الفعلية للمستخدم الحالي.
///
/// تُبنى من حقل `perm` الموجود في مستند المستخدم (rollup):
/// role.permissions مدمجة مع permsOverrides الفردية.
/// نفس هذا المصدر تستخدمه Firebase Security Rules عبر `request.auth.uid`.
class AppPermissions {
  const AppPermissions(this.values);

  static const empty = AppPermissions({});

  final Map<String, bool> values;

  bool get isEmpty => values.isEmpty;

  bool has(String module, String action) => values['$module.$action'] ?? false;

  bool hasAny(List<String> keys) => keys.any((k) => values[k] ?? false);

  /// هل يملك صلاحية رؤية أي وحدة داخل لوحة الإدارة.
  bool get hasAnyModuleView => values.entries.any((e) => e.value);

  static AppPermissions fromProfile(UserProfile profile) {
    return AppPermissions(
      profile.perms.map((k, v) => MapEntry(k, v == true)),
    );
  }

  /// يدمج صلاحيات الدور مع التجاوزات الفردية.
  /// `{key: false}` في التجاوزات تعني إزالة الصلاحية.
  static Map<String, bool> merge(
    Map<String, bool> rolePerms,
    Map<String, bool> overrides,
  ) {
    final result = Map<String, bool>.of(rolePerms);
    for (final entry in overrides.entries) {
      if (entry.value == false) {
        result.remove(entry.key);
      } else {
        result[entry.key] = true;
      }
    }
    return result;
  }

  @override
  String toString() => 'AppPermissions(${values.length})';
}