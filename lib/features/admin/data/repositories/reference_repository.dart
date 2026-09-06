import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reference_config.dart';
import '../models/reference_item.dart';

class ReferenceRepository {
  ReferenceRepository._();

  static final ReferenceRepository instance = ReferenceRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _coll(ReferenceKind kind) {
    final collection = ReferenceConfig.of(kind).collection;
    final ref = _db.collection(collection);
    return ref; // نوع غير متوقع = CollectionReference<Map<String, dynamic>>
  }

  Stream<List<ReferenceItem>> watchItems(ReferenceKind kind) {
    return _coll(kind)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReferenceItem.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<String> addItem(ReferenceKind kind, ReferenceItem item) async {
    final ref = await _coll(kind).add(item.toMap());
    return ref.id;
  }

  Future<void> updateItem(
    ReferenceKind kind,
    String id,
    Map<String, dynamic> fields,
  ) async {
    await _coll(kind).doc(id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleActive(ReferenceKind kind, String id, bool active) async {
    await _coll(kind).doc(id).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archive(ReferenceKind kind, String id) async {
    await _coll(kind).doc(id).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}