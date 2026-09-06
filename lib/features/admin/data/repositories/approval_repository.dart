import 'package:cloud_firestore/cloud_firestore.dart';

class PendingApproval {
  const PendingApproval({
    required this.id,
    required this.module,
    required this.recordId,
    required this.recordType,
    required this.requestedById,
    required this.requestedByName,
    this.change = const {},
    this.status = 'pending',
    this.requestedAt,
  });

  final String id;
  final String module;
  final String recordId;
  final String recordType;
  final String requestedById;
  final String requestedByName;
  final Map<String, dynamic> change;
  final String status;
  final DateTime? requestedAt;

  factory PendingApproval.fromMap(Map<String, dynamic> map, {required String id}) {
    return PendingApproval(
      id: id,
      module: map['module'] as String? ?? '',
      recordId: map['recordId'] as String? ?? '',
      recordType: map['recordType'] as String? ?? '',
      requestedById: map['requestedById'] as String? ?? '',
      requestedByName: map['requestedByName'] as String? ?? '',
      change: _asMap(map['change']),
      status: map['status'] as String? ?? 'pending',
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> _asMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
}

/// إدارة طلبات الموافقة (Approval Workflow).
class ApprovalRepository {
  ApprovalRepository._();

  static final ApprovalRepository instance = ApprovalRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PendingApproval>> watchPending() {
    return _db
        .collection('approval_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PendingApproval.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<void> createRequest({
    required String module,
    required String recordId,
    required String recordType,
    required String requestedById,
    required String requestedByName,
    Map<String, dynamic> change = const {},
  }) async {
    await _db.collection('approval_requests').add({
      'module': module,
      'recordId': recordId,
      'recordType': recordType,
      'requestedById': requestedById,
      'requestedByName': requestedByName,
      'change': change,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// اعتماد / رفض طلب معين وتسجيل من قرر ومتى.
  Future<void> decide({
    required String requestId,
    required bool approve,
    required String decidedById,
    required String decidedByName,
    String reason = '',
  }) async {
    await _db.collection('approval_requests').doc(requestId).update({
      'status': approve ? 'approved' : 'rejected',
      'decidedById': decidedById,
      'decidedByName': decidedByName,
      'decidedAt': FieldValue.serverTimestamp(),
      'reason': reason,
    });
  }
}