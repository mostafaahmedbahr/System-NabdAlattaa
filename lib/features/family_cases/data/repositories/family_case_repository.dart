import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_case.dart';

class FamilyCaseRepository {
  FamilyCaseRepository._();

  static final FamilyCaseRepository instance = FamilyCaseRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cases =>
      _db.collection('family_cases');

  Future<String> addCase(FamilyCase familyCase) async {
    final doc = await _cases.add(familyCase.toMap());
    return doc.id;
  }

  Future<void> updateCase(FamilyCase familyCase) async {
    if (familyCase.id == null) return;
    await _cases.doc(familyCase.id!).set(familyCase.toMap());
  }

  Future<void> updateStatus(String caseId, CaseStatus newStatus) async {
    final entry = StatusHistoryEntry(status: newStatus.label, at: DateTime.now());
    await _cases.doc(caseId).update({
      'status': newStatus.label,
      'statusHistory': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  Future<void> routeToPrograms(String caseId, {String? notes}) async {
    await _cases.doc(caseId).update({
      'routedToPrograms': true,
      'routedAt': DateTime.now(),
      'programNotes': notes ?? '',
    });
  }

  Future<void> assignProgram(
    String caseId, {
    required String program,
    String? notes,
  }) async {
    await _cases.doc(caseId).update({
      'programAssigned': program,
      'programNotes': notes ?? '',
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCases() {
    return _cases.orderBy('registrationDate', descending: true).snapshots();
  }
}