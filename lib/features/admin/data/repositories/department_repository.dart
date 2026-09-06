import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/department.dart';

class DepartmentRepository {
  DepartmentRepository._();

  static final DepartmentRepository instance = DepartmentRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _departments =>
      _db.collection('departments');

  Stream<List<Department>> watchDepartments() {
    return _departments
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Department.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<String> addDepartment(Department department) async {
    final ref = _departments.add(department.toMap());
    return (await ref).id;
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> fields) async {
    await _departments.doc(id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleActive(String id, bool active) async {
    await _departments.doc(id).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// أرشفة القسم (Soft Delete) — لا يُحذف نهائيًا إن ارتبط بموظفين.
  Future<void> archive(String id) async {
    await _departments.doc(id).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}