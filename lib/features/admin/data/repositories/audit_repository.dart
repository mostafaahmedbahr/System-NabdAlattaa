import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.module,
    required this.action,
    this.recordId = '',
    this.message = '',
    this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String module;
  final String action;
  final String recordId;
  final String message;
  final DateTime? timestamp;

  factory AuditEntry.fromMap(Map<String, dynamic> map, {required String id}) {
    return AuditEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      module: map['module'] as String? ?? '',
      action: map['action'] as String? ?? '',
      recordId: map['recordId'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}

class AuditRepository {
  AuditRepository._();

  static final AuditRepository instance = AuditRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AuditEntry>> watchRecent({int limit = 100}) {
    return _db
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AuditEntry.fromMap(d.data(), id: d.id))
            .toList());
  }
}