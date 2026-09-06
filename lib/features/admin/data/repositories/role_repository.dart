import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/role.dart';

class RoleRepository {
  RoleRepository._();

  static final RoleRepository instance = RoleRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _roles =>
      _db.collection('roles');

  Stream<List<Role>> watchRoles() {
    return _roles
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => Role.fromMap(d.data(), id: d.id))
          .toList();
    });
  }

  Future<Role?> getRole(String roleId) async {
    if (roleId.isEmpty) return null;
    final snap = await _roles.doc(roleId).get();
    if (!snap.exists) return null;
    return Role.fromMap(snap.data()!, id: roleId);
  }

  Future<String> addRole({
    required String id,
    required String name,
    String description = '',
    Map<String, bool> permissions = const {},
  }) async {
    await _roles.doc(id).set(Role(
      id: id,
      name: name,
      description: description,
      isSystem: false,
      isActive: true,
      permissions: permissions,
      createdAt: DateTime.now(),
    ).toMap());
    return id;
  }

  Future<void> updateRole(String id, Map<String, dynamic> fields) async {
    await _roles.doc(id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRolePermissions(String id, Map<String, bool> perms) async {
    await _roles.doc(id).update({
      'permissions': perms,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveRole(String id) async {
    await _roles.doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}