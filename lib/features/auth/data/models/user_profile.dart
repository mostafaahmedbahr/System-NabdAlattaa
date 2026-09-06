import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String uid;
  final String name;
  final String phone;
  final String department;
  final String email;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'department': department,
      'email': email,
      'createdAt': createdAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {required String uid}) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      department: map['department'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}