import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/security/app_permissions.dart';
import '../../../auth/data/models/user_profile.dart';
import '../models/role.dart';

class EmployeeRepository {
  EmployeeRepository._();

  static final EmployeeRepository instance = EmployeeRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<UserProfile>> watchEmployees() {
    return _users.where('isDeleted', isEqualTo: false).snapshots().map(
      (snap) => snap.docs
          .map((d) => UserProfile.fromMap(d.data(), uid: d.id))
          .toList(),
    );
  }

  /// إنشاء موظف جديد (حساب Auth + مستند في users) بكلمة مرور مؤقتة.
  Future<String> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Role role,
    String departmentId = '',
    String department = '',
    String jobTitle = '',
    String createdBy = '',
  }) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    await _users.doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'department': department,
      'departmentId': departmentId,
      'jobTitle': jobTitle,
      'roleId': role.id,
      'roleName': role.name,
      'isActive': true,
      'isDeleted': false,
      'isSuperAdmin': false,
      'perm': role.permissions,
      'permsOverrides': <String, bool>{},
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return uid;
  }

  Future<void> updateEmployee(
    String uid, {
    String? name,
    String? phone,
    String? jobTitle,
    String? departmentId,
    String? department,
  }) async {
    final changes = <String, dynamic>{};
    if (name != null) changes['name'] = name;
    if (phone != null) changes['phone'] = phone;
    if (jobTitle != null) changes['jobTitle'] = jobTitle;
    if (departmentId != null) changes['departmentId'] = departmentId;
    if (department != null) changes['department'] = department;
    if (changes.isNotEmpty) {
      changes['updatedAt'] = FieldValue.serverTimestamp();
      await _users.doc(uid).update(changes);
    }
  }

  Future<void> setRole(String uid, Role role) async {
    final snap = await _users.doc(uid).get();
    final overrides = _boolMap(snap.data()?['permsOverrides']);
    final perms = AppPermissions.merge(role.permissions, overrides);
    await _users.doc(uid).update({
      'roleId': role.id,
      'roleName': role.name,
      'perm': perms,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// يكمل صلاحيات موظف بشكل مستقل عن دوره (إضافة أو إزالة).
  Future<void> setOverrides(String uid, Map<String, bool> overrides) async {
    final snap = await _users.doc(uid).get();
    final roleId = snap.data()?['roleId'] as String? ?? '';
    Map<String, bool> rolePerms = const {};
    if (roleId.isNotEmpty) {
      final roleSnap = await _db.collection('roles').doc(roleId).get();
      rolePerms = _boolMap(roleSnap.data()?['permissions']);
    }
    final perms = AppPermissions.merge(rolePerms, overrides);
    await _users.doc(uid).update({
      'permsOverrides': overrides,
      'perm': perms,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleActive(String uid, bool active) async {
    await _users.doc(uid).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// أرشفة الموظف (Soft Delete): لا يُحذف نهائيًا أبدًا.
  Future<void> archive(String uid) async {
    await _users.doc(uid).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// يحدّث rollup الصلاحيات لكل الموظفين المرتبطين بدور بعد تعديله.
  Future<void> recomputeForRole(String roleId, Map<String, bool> rolePerms) async {
    final snap = await _users.where('roleId', isEqualTo: roleId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final overrides = _boolMap(doc.data()['permsOverrides']);
      final perms = AppPermissions.merge(rolePerms, overrides);
      batch.update(doc.reference, {
        'perm': perms,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// عدد الموظفين النشطين في قسم معين (لعرضه في شاشة القسم).
  Future<int> countByDepartment(String departmentId) async {
    final snap = await _users
        .where('departmentId', isEqualTo: departmentId)
        .where('isDeleted', isEqualTo: false)
        .count()
        .get();
    return snap.count ?? 0;
  }

  static Map<String, bool> _boolMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v == true));
  }
}