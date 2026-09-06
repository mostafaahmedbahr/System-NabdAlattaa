import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettings {
  const SystemSettings({
    this.id = 'app',
    this.societyName = 'نبض العطاء',
    this.logoUrl = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.governorate = '',
    this.center = '',
    this.website = '',
    this.socialLinks = const {},
    this.language = 'ar',
    this.currency = 'ج.م',
    this.dateFormat = 'yyyy/MM/dd',
    this.requireAidApproval = false,
    this.requireExpenseApproval = false,
    this.allowDelete = false,
    this.allowEditAfterApproval = false,
    this.enableAuditLog = true,
    this.updatedAt,
  });

  final String id;
  final String societyName;
  final String logoUrl;
  final String phone;
  final String email;
  final String address;
  final String governorate;
  final String center;
  final String website;
  final Map<String, String> socialLinks;
  final String language;
  final String currency;
  final String dateFormat;
  final bool requireAidApproval;
  final bool requireExpenseApproval;
  final bool allowDelete;
  final bool allowEditAfterApproval;
  final bool enableAuditLog;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'societyName': societyName,
      'logoUrl': logoUrl,
      'phone': phone,
      'email': email,
      'address': address,
      'governorate': governorate,
      'center': center,
      'website': website,
      'socialLinks': socialLinks,
      'language': language,
      'currency': currency,
      'dateFormat': dateFormat,
      'requireAidApproval': requireAidApproval,
      'requireExpenseApproval': requireExpenseApproval,
      'allowDelete': allowDelete,
      'allowEditAfterApproval': allowEditAfterApproval,
      'enableAuditLog': enableAuditLog,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory SystemSettings.fromMap(Map<String, dynamic> map, {String id = 'app'}) {
    final links = map['socialLinks'];
    return SystemSettings(
      id: id,
      societyName: map['societyName'] as String? ?? 'نبض العطاء',
      logoUrl: map['logoUrl'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      governorate: map['governorate'] as String? ?? '',
      center: map['center'] as String? ?? '',
      website: map['website'] as String? ?? '',
      socialLinks: _stringMap(links),
      language: map['language'] as String? ?? 'ar',
      currency: map['currency'] as String? ?? 'ج.م',
      dateFormat: map['dateFormat'] as String? ?? 'yyyy/MM/dd',
      requireAidApproval: map['requireAidApproval'] as bool? ?? false,
      requireExpenseApproval: map['requireExpenseApproval'] as bool? ?? false,
      allowDelete: map['allowDelete'] as bool? ?? false,
      allowEditAfterApproval: map['allowEditAfterApproval'] as bool? ?? false,
      enableAuditLog: map['enableAuditLog'] as bool? ?? true,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}