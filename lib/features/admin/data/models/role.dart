import 'package:cloud_firestore/cloud_firestore.dart';

class Role {
  const Role({
    required this.id,
    required this.name,
    this.description = '',
    this.isSystem = false,
    this.isActive = true,
    this.autoAssign = false,
    this.permissions = const {},
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final bool autoAssign;

  /// مصفوفة الصلاحيات: `{ "families.delete": true, ... }`.
  final Map<String, bool> permissions;
  final DateTime? createdAt;

  bool has(String permissionKey) => permissions[permissionKey] ?? false;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'isActive': isActive,
      'autoAssign': autoAssign,
      'permissions': permissions,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory Role.fromMap(Map<String, dynamic> map, {required String id}) {
    final perms = map['permissions'];
    return Role(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isSystem: map['isSystem'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
      autoAssign: map['autoAssign'] as bool? ?? false,
      permissions: _boolMap(perms),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, bool> _boolMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v == true));
  }
}