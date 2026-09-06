import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/security/permission_registry.dart';
import '../models/department.dart';
import '../models/reference_config.dart';
import '../models/reference_item.dart';
import 'settings_repository.dart';

/// يزرع البيانات الافتراضية عند أول تشغيل (الأدوار والأقسام والقوائم والإعدادات)
/// بحيث يعمل النظام فورًأ ويمكن للأدمن تعديلها ديناميكيًا لاحقًا.
class BootstrapRepository {
  BootstrapRepository._();

  static final BootstrapRepository instance = BootstrapRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> ensureDefaults() async {
    await Future.wait([
      _ensureRoles(),
      _ensureDepartments(),
      _ensureLookups(),
      SettingsRepository.instance.ensureDefaults(),
    ]);
  }

  Future<void> _ensureRoles() async {
    final roles = _db.collection('roles');
    for (final entry in PermissionRegistry.seedRoles.entries) {
      final doc = await roles.doc(entry.key).get();
      if (!doc.exists) {
        await roles.doc(entry.key).set({
          'name': entry.value.name,
          'description': entry.value.description,
          'isSystem': true,
          'isActive': true,
          'autoAssign': entry.key == 'data_entry',
          'permissions': entry.value.permissions,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _ensureDepartments() async {
    final snap = await _db.collection('departments').limit(1).get();
    if (snap.docs.isNotEmpty) return;
    const seeds = <({String name, String icon, String color, String desc})>[
      (name: 'الشؤون الاجتماعية', icon: 'family', color: '#00897B', desc: 'الأسر والمساعدات الاجتماعية'),
      (name: 'الحسابات', icon: 'money', color: '#E53935', desc: 'التبرعات والمصروفات'),
      (name: 'المخزن', icon: 'warehouse', color: '#6D4C41', desc: 'إدارة الأصناف والمخزون'),
      (name: 'العلاقات العامة', icon: 'volunteer', color: '#8E24AA', desc: 'التواصل الخارجي والشراكات'),
      (name: 'التبرعات', icon: 'handshake', color: '#F9A825', desc: 'استقبال وإدارة التبرعات'),
      (name: 'الموارد البشرية', icon: 'favorite', color: '#3949AB', desc: 'شؤون الموظفين'),
      (name: 'الإدارة', icon: 'home', color: '#00695C', desc: 'إدارة الجمعية'),
    ];
    for (final seed in seeds) {
      await _db.collection('departments').add(Department(
        id: '',
        name: seed.name,
        description: seed.desc,
        icon: seed.icon,
        color: seed.color,
      ).toMap());
    }
  }

  Future<void> _ensureLookups() async {
    final tasks = <Future<void>>[];
    final seeders = <ReferenceKind, List<ReferenceItem>>{
      ReferenceKind.familyStatuses: [
        _item('أسرة نشطة', 'status', '#2E7D32', {}),
        _item('تحتاج مراجعة', 'status', '#F9A825', {}),
        _item('موقوفة', 'status', '#D84315', {}),
        _item('غير مستحقة', 'block', '#757575', {}),
        _item('مغلقة', 'block', '#455A64', {}),
      ],
      ReferenceKind.priorities: [
        _item('منخفضة', 'priority', '#66BB6A', {'sortOrder': 1}),
        _item('متوسطة', 'priority', '#FFA726', {'sortOrder': 2}),
        _item('عالية', 'priority', '#EF5350', {'sortOrder': 3}),
        _item('عاجلة', 'priority', '#C62828', {'sortOrder': 4}),
      ],
      ReferenceKind.aidTypes: [
        _item('مساعدة مالية', 'money', '#00897B', {'category': 'مالية', 'unit': 'جنيه', 'maxValue': 0, 'needsApproval': false}),
        _item('كرتونة غذائية', 'food', '#EF6C00', {'category': 'عينية', 'unit': 'كرتونة', 'needsApproval': false}),
        _item('ملابس', 'clothes', '#3949AB', {'category': 'عينية', 'unit': 'قطعة', 'needsApproval': false}),
        _item('علاج', 'medical', '#E53935', {'category': 'عينية', 'unit': '', 'needsApproval': false}),
        _item('جهاز كهربائي', 'home', '#6D4C41', {'category': 'عينية', 'unit': 'قطعة', 'needsApproval': false}),
        _item('تجهيز عروس', 'favorite', '#AD1457', {'category': 'عينية', 'unit': '', 'needsApproval': false}),
        _item('لحوم', 'food', '#C62828', {'category': 'عينية', 'unit': 'كيلو', 'needsApproval': false}),
        _item('بطاطين', 'clothes', '#5E35B1', {'category': 'عينية', 'unit': 'قطعة', 'needsApproval': false}),
        _item('توصيل مياه', 'water', '#0288D1', {'category': 'عينية', 'unit': '', 'needsApproval': false}),
        _item('معاش شهري', 'money', '#00796B', {'category': 'مالية', 'unit': 'جنيه', 'maxValue': 0, 'needsApproval': true}),
        _item('مصاريف تعليم', 'education', '#4527A0', {'category': 'مالية', 'unit': 'جنيه', 'maxValue': 0, 'needsApproval': false}),
      ],
      ReferenceKind.donationTypes: [
        _item('تبرع نقدي', 'money', '#F9A825', {'category': 'نقدي'}),
        _item('مواد غذائية', 'food', '#EF6C00', {'category': 'عيني'}),
        _item('ملابس', 'clothes', '#3949AB', {'category': 'عيني'}),
        _item('أجهزة', 'home', '#6D4C41', {'category': 'عيني'}),
        _item('أدوية', 'medical', '#E53935', {'category': 'عيني'}),
        _item('أثاث', 'home', '#8D6E63', {'category': 'عيني'}),
        _item('تبرع لمشروع معين', 'volunteer', '#00897B', {'category': 'عيني'}),
      ],
      ReferenceKind.expenseCategories: [
        _item('مساعدات', 'handshake', '#00897B', {'needsApproval': false}),
        _item('رواتب', 'money', '#3949AB', {}),
        _item('إيجار', 'home', '#6D4C41', {}),
        _item('كهرباء', 'category', '#F9A825', {}),
        _item('مياه', 'water', '#0288D1', {}),
        _item('مواصلات', 'straighten', '#8E24AA', {}),
        _item('شراء مواد غذائية', 'food', '#EF6C00', {}),
        _item('مصروفات إدارية', 'category', '#455A64', {}),
        _item('صيانة', 'home', '#7B1FA2', {}),
      ],
      ReferenceKind.units: [
        _item('قطعة', 'straighten', '#5E35B1', {'abbreviation': 'قطعة'}),
        _item('كرتونة', 'warehouse', '#EF6C00', {'abbreviation': 'كرتونة'}),
        _item('كيلو', 'straighten', '#00796B', {'abbreviation': 'كجم'}),
        _item('لتر', 'straighten', '#0288D1', {'abbreviation': 'لتر'}),
        _item('عبوة', 'category', '#8D6E63', {'abbreviation': 'عبوة'}),
      ],
      ReferenceKind.rejectionReasons: [
        _item('البيانات غير مكتملة', 'block', '#757575', {}),
        _item('الحالة غير مستحقة', 'block', '#D84315', {}),
        _item('المستندات غير متوفرة', 'block', '#5C6BC0', {}),
        _item('تم تقديم المساعدة مسبقًا', 'block', '#00897B', {}),
      ],
    };

    for (final entry in seeders.entries) {
      final config = ReferenceConfig.of(entry.key);
      final snap =
          await _db.collection(config.collection).limit(1).get();
      if (snap.docs.isNotEmpty) continue;
      tasks.addAll(
        entry.value
            .map((item) => _db.collection(config.collection).add(item.toMap())),
      );
    }
    await Future.wait(tasks);
  }

  ReferenceItem _item(String name, String icon, String color, Map<String, dynamic> extra) {
    return ReferenceItem(
      id: '',
      name: name,
      description: '',
      icon: icon,
      color: color,
      extra: extra,
    );
  }
}