/// سجل الصلاحيات (Permission Registry).
///
/// هذا هو المصدر الوحيد في الكود الذي يعرّف الوحدات والإجراءات المتاحة
/// لبناء الواجهات (مصفوفة الصلاحيات شاشة الموظف/الدور). التفعيل الأمني
/// الفعلي يحدث في Firestore Security Rules عبر مفتاح `module.action`.
/// إضافة وحدة/إجراء جديدة = إضافة هنا فقط دون إعادة بناء النظام.
class PermissionAction {
  const PermissionAction(this.key, this.label);

  final String key;
  final String label;
}

class PermissionModule {
  const PermissionModule(this.key, this.label, this.actions);

  final String key;
  final String label;
  final List<PermissionAction> actions;

  String perm(String action) => '$key.$action';
}

class PermissionRegistry {
  PermissionRegistry._();

  static const allModules = <PermissionModule>[
    PermissionModule('families', 'الأسر', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('archive', 'أرشفة'),
      PermissionAction('approve', 'اعتماد'),
      PermissionAction('reject', 'رفض'),
    ]),
    PermissionModule('aids', 'المساعدات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('approve', 'اعتماد'),
      PermissionAction('reject', 'رفض'),
    ]),
    PermissionModule('donations', 'التبرعات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('approve', 'اعتماد'),
    ]),
    PermissionModule('expenses', 'المصروفات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('approve', 'اعتماد'),
    ]),
    PermissionModule('inventory', 'المخزن', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('stockIn', 'إدخال مخزون'),
      PermissionAction('stockOut', 'صرف مخزون'),
    ]),
    PermissionModule('departments', 'الأقسام', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('archive', 'أرشفة'),
    ]),
    PermissionModule('projects', 'المشاريع', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
    ]),
    PermissionModule('reports', 'التقارير', [
      PermissionAction('view', 'عرض'),
      PermissionAction('export', 'تصدير'),
    ]),
    PermissionModule('approvals', 'الموافقات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('approve', 'اعتماد'),
      PermissionAction('reject', 'رفض'),
    ]),
    PermissionModule('employees', 'الموظفون', [
      PermissionAction('view', 'عرض'),
      PermissionAction('add', 'إضافة'),
      PermissionAction('edit', 'تعديل'),
      PermissionAction('delete', 'حذف'),
      PermissionAction('managePermissions', 'إدارة الصلاحيات'),
    ]),
    PermissionModule('notifications', 'الإشعارات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('send', 'إرسال'),
    ]),
    PermissionModule('settings', 'الإعدادات', [
      PermissionAction('view', 'عرض'),
      PermissionAction('edit', 'تعديل'),
    ]),
    PermissionModule('audit', 'سجل العمليات', [
      PermissionAction('view', 'عرض'),
    ]),
    PermissionModule('dashboard', 'لوحة التحكم', [
      PermissionAction('view', 'عرض'),
    ]),
  ];

  /// الأدوار الافتراضية التي تُزرع عند أول تشغيل (Seed).
  /// المفاتيح مطابقة لمعرّفات مستندات roles/{id}.
  static final seedRoles = <String, ({String name, String description, Map<String, bool> permissions})>{
    'admin': (
      name: 'مدير النظام',
      description: 'صلاحيات كاملة على جميع الوحدات والإعدادات',
      permissions: _fullPermissions(),
    ),
    'manager': (
      name: 'مدير',
      description: 'يدير الأسر والمساعدات والمصروفات مع اعتماد الطلبات',
      permissions: {
        'dashboard.view': true,
        'families.view': true, 'families.add': true, 'families.edit': true,
        'families.approve': true, 'families.reject': true, 'families.archive': true,
        'aids.view': true, 'aids.add': true, 'aids.edit': true,
        'aids.approve': true, 'aids.reject': true,
        'donations.view': true, 'donations.add': true, 'donations.edit': true,
        'donations.approve': true,
        'expenses.view': true, 'expenses.add': true, 'expenses.edit': true,
        'expenses.approve': true,
        'inventory.view': true, 'inventory.add': true, 'inventory.edit': true,
        'inventory.stockIn': true, 'inventory.stockOut': true,
        'projects.view': true, 'projects.add': true, 'projects.edit': true,
        'approvals.view': true, 'approvals.approve': true, 'approvals.reject': true,
        'reports.view': true, 'reports.export': true,
        'departments.view': true,
      },
    ),
    'social_worker': (
      name: 'أخصائي اجتماعي',
      description: 'تسجيل ومتابعة الأسر والمساعدات',
      permissions: {
        'dashboard.view': true,
        'families.view': true, 'families.add': true, 'families.edit': true,
        'families.archive': true,
        'aids.view': true, 'aids.add': true, 'aids.edit': true,
        'reports.view': true,
      },
    ),
    'accountant': (
      name: 'محاسب',
      description: 'إدارة التبرعات والمصروفات والتقارير المالية',
      permissions: {
        'dashboard.view': true,
        'donations.view': true, 'donations.add': true, 'donations.edit': true,
        'expenses.view': true, 'expenses.add': true, 'expenses.edit': true,
        'reports.view': true, 'reports.export': true,
      },
    ),
    'warehouse': (
      name: 'أمين مخزن',
      description: 'إدارة المخزون وحركات الصرف والإدخال',
      permissions: {
        'dashboard.view': true,
        'inventory.view': true, 'inventory.add': true, 'inventory.edit': true,
        'inventory.stockIn': true, 'inventory.stockOut': true,
        'reports.view': true,
      },
    ),
    'data_entry': (
      name: 'مدخل بيانات',
      description: 'تسجيل الأسر والمساعدات فقط',
      permissions: {
        'families.view': true, 'families.add': true, 'families.edit': true,
        'aids.view': true, 'aids.add': true,
      },
    ),
  };

  static Map<String, bool> _fullPermissions() {
    final result = <String, bool>{'dashboard.view': true};
    for (final module in allModules) {
      for (final action in module.actions) {
        result['${module.key}.${action.key}'] = true;
      }
    }
    result['employees.managePermissions'] = true;
    result['audit.view'] = true;
    result['settings.edit'] = true;
    result['notifications.send'] = true;
    return result;
  }
}