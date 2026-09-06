import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> saveProfile(UserProfile profile) {
    return _users.doc(profile.uid).set(profile.toMap());
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return UserProfile.fromMap(data, uid: uid);
    });
  }

  Future<void> updateProfileFields(
    String uid,
    Map<String, dynamic> fields,
  ) async {
    await _users.doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// يسجّل آخر دخول للمستخدم فور نجاح تسجيل الدخول.
  Future<void> recordLogin(String uid) async {
    try {
      await _users.doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // المستند قد لا يكون أُنشئ بعد لحظة التسجيل — نتجاهل.
    }
  }

  /// هل يوجد أي مستخدم في النظام (لتحديد دور أول حساب).
  Future<bool> isFirstUser() async {
    final snapshot = await _users.limit(1).get();
    return snapshot.docs.isEmpty;
  }
}