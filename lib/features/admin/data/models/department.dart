import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  const Department({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'category',
    this.color = '#00695C',
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
  final bool isActive;
  final bool isDeleted;
  final DateTime? createdAt;
  final String createdBy;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map, {required String id}) {
    return Department(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as String? ?? '#00695C',
      isActive: map['isActive'] as bool? ?? true,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}