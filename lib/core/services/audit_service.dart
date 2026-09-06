import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/models/user_profile.dart';

/// يسجّل العمليات الحساسة في مجموعة `audit_logs` (كتابة فقط).
///
/// يُستدعى دائمًا بعد نجاح العملية، وحيث أمكن ضمن نفس Batch.
class AuditService {
  AuditService._();

  static final AuditService instance = AuditService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('audit_logs');

  /// يسجّل عملية مع رسالة جاهزة بالعربي، مثال:
  /// "أحمد قام بتعديل بيانات الأسرة رقم 102".
  Future<void> log({
    UserProfile? actor,
    String? actorUid,
    String? actorName,
    required String module,
    required String action,
    String? recordId,
    String? message,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final uid = actorUid ?? _auth.currentUser?.uid ?? 'unknown';
      final name = actorName ?? actor?.name ?? _auth.currentUser?.displayName ?? '';
      await _logs.add({
        'userId': uid,
        'userName': name,
        'module': module,
        'action': action,
        'recordId': recordId ?? '',
        'message': message,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // لا يجوز أن يكسر تسجيل الأثر سير العمل الأساسي.
    }
  }
}