import 'package:cloud_firestore/cloud_firestore.dart';

/// أقسام افتراضية تظهر في شاشة إنشاء الحساب.
/// ملاحظة: المصدر الرسمي للأقسام أصبح مجموعة `departments` في Firestore
/// ويديرها الأدمن؛ هذه القائمة تُستخدم كخيارات مبدئية عند أول تشغيل فقط.
const kDepartments = [
  'استقبال الأسر',
  'قسم البرامج',
  'البحث الميداني',
  'الإدارة',
  'أخرى',
];

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.department,
    required this.email,
    required this.createdAt,
    this.departmentId = '',
    this.jobTitle = '',
    this.roleId = '',
    this.roleName = '',
    this.isActive = true,
    this.isDeleted = false,
    this.isSuperAdmin = false,
    this.lastLoginAt,
    this.perms = const {},
    this.permsOverrides = const {},
    this.createdBy = '',
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String phone;
  final String department;
  final String email;
  final DateTime createdAt;
  final String departmentId;
  final String jobTitle;
  final String roleId;
  final String roleName;
  final bool isActive;
  final bool isDeleted;
  final bool isSuperAdmin;
  final DateTime? lastLoginAt;

  /// الصلاحيات الفعلية (rollup): role + permsOverrides.
  final Map<String, bool> perms;

  /// تجاوزات فردية لكل موظف مستقلة عن دوره.
  final Map<String, bool> permsOverrides;
  final String createdBy;
  final DateTime? updatedAt;

  bool hasPermission(String module, String action) =>
      perms['$module.$action'] ?? false;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'department': department,
      'departmentId': departmentId,
      'jobTitle': jobTitle,
      'roleId': roleId,
      'roleName': roleName,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'isSuperAdmin': isSuperAdmin,
      'lastLoginAt': lastLoginAt,
      'perm': perms,
      'permsOverrides': permsOverrides,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    final permRaw = map['perm'];
    final overridesRaw = map['permsOverrides'];
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      department: map['department'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      departmentId: map['departmentId'] as String? ?? '',
      jobTitle: map['jobTitle'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isSuperAdmin: map['isSuperAdmin'] as bool? ?? false,
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
      perms: _boolMap(permRaw),
      permsOverrides: _boolMap(overridesRaw),
      createdBy: map['createdBy'] as String? ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, bool> _boolMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v == true));
  }
}