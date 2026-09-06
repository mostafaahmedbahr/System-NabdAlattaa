import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.target = 'all',
    this.targetId = '',
    this.sentById = '',
    this.sentByName = '',
    this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String target;
  final String targetId;
  final String sentById;
  final String sentByName;
  final DateTime? sentAt;

  factory AppNotification.fromMap(Map<String, dynamic> map, {required String id}) {
    return AppNotification(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      target: map['target'] as String? ?? 'all',
      targetId: map['targetId'] as String? ?? '',
      sentById: map['sentById'] as String? ?? '',
      sentByName: map['sentByName'] as String? ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// يُكتب في مجموعة `notifications`؛ الإرسال الفعلي (Push) يتم عبر
/// Cloud Function تلتقط الكتابة الجديدة وترسل عبر FCM حسب target.
class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AppNotification>> watchNotifications() {
    return _db
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<String> send({
    required String title,
    required String body,
    String type = 'general',
    String target = 'all',
    String targetId = '',
    String sentById = '',
    String sentByName = '',
  }) async {
    final ref = await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'type': type,
      'target': target,
      'targetId': targetId,
      'sentById': sentById,
      'sentByName': sentByName,
      'sentAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}