import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/system_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static final SettingsRepository instance = SettingsRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('system_settings').doc('app');

  Stream<SystemSettings> watchSettings() {
    return _doc.snapshots().map(
      (snap) => SystemSettings.fromMap(snap.data() ?? const {}),
    );
  }

  Future<SystemSettings> getSettings() async {
    final snap = await _doc.get();
    final data = snap.data();
    if (data == null) {
      final init = const SystemSettings();
      await _doc.set(init.toMap());
      return init;
    }
    return SystemSettings.fromMap(data);
  }

  Future<void> updateSettings(Map<String, dynamic> fields) async {
    await _doc.update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureDefaults() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(const SystemSettings().toMap());
    }
  }
}