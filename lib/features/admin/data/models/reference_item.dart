import 'package:cloud_firestore/cloud_firestore.dart';

/// عنصر عام لأي قائمة مرجعية (أنواع مساعدات، فئات مصروفات، وحدات، حالات، أولويات...).
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'category',
    this.color = '#00695C',
    this.extra = const {},
    this.isActive = true,
    this.isDeleted = false,
    this.createdAt,
    this.createdBy = '',
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final Map<String, dynamic> extra;
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final String createdBy;

  dynamic extraValue(String key) => extra[key];

  String extraString(String key, [String fallback = '']) {
    final v = extra[key];
    if (v == null) return fallback;
    return v.toString();
  }

  num extraNumber(String key, [num fallback = 0]) {
    final v = extra[key];
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? fallback;
    return fallback;
  }

  bool extraBool(String key, [bool fallback = false]) {
    final v = extra[key];
    return v == true || (v == 'true') || (v == false ? false : fallback);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'extra': extra,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  factory ReferenceItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return ReferenceItem(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? 'category',
      color: (map['color'] as String?) ?? '#00695C',
      extra: _asMap(map['extra']),
      isActive: map['isActive'] as bool? ?? true,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
}