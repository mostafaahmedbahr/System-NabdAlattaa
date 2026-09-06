/// تعريف أنواع القوائم المرجعية الحية التي يديرها الأدمن.
/// كل نوع = مجموعة + قائمة حقول إضافية تُعرض في نموذج الإضافة/التعديل.
enum ReferenceKind {
  aidTypes,
  donationTypes,
  expenseCategories,
  inventoryCategories,
  stockReasons,
  units,
  familyStatuses,
  priorities,
  rejectionReasons,
}

enum ReferenceFieldType { text, dropdown, number, switchField }

class ReferenceField {
  const ReferenceField(
    this.key,
    this.label, {
    this.type = ReferenceFieldType.text,
    this.options = const [],
    this.hint = '',
  });

  final String key;
  final String label;
  final ReferenceFieldType type;
  final List<String> options;
  final String hint;
}

class ReferenceConfig {
  const ReferenceConfig({
    required this.kind,
    required this.collection,
    required this.title,
    required this.singularLabel,
    required this.icon,
    required this.color,
    this.description = '',
    this.fields = const [],
    this.pickIcon = false,
    this.pickColor = false,
  });

  final ReferenceKind kind;
  final String collection;
  final String title;
  final String singularLabel;
  final String icon;
  final String color;
  final String description;
  final List<ReferenceField> fields;
  final bool pickIcon;
  final bool pickColor;

  static const configs = <ReferenceConfig>[
    ReferenceConfig(
      kind: ReferenceKind.aidTypes,
      collection: 'aid_types',
      title: 'أنواع المساعدات',
      singularLabel: 'نوع مساعدة',
      icon: 'handshake',
      color: '#00897B',
      description: 'المساعدات التي تقدمها الجمعية للأسر والمستفيدين.',
      fields: [
        ReferenceField('category', 'التصنيف',
            type: ReferenceFieldType.dropdown,
            options: ['مالية', 'عينية']),
        ReferenceField('unit', 'الوحدة', hint: 'مثال: كرتونة، جنيه...'),
        ReferenceField('maxValue', 'الحد الأقصى للقيمة',
            type: ReferenceFieldType.number, hint: 'اتركه فارغًا إن لم يوجد'),
        ReferenceField('needsApproval', 'يحتاج اعتماد مدير؟',
            type: ReferenceFieldType.switchField),
      ],
      pickIcon: true,
      pickColor: true,
    ),
    ReferenceConfig(
      kind: ReferenceKind.donationTypes,
      collection: 'donation_types',
      title: 'أنواع التبرعات',
      singularLabel: 'نوع تبرع',
      icon: 'volunteer',
      color: '#F9A825',
      description: 'أنواع التبرعات التي تستقبلها الجمعية.',
      fields: [
        ReferenceField('category', 'التصنيف',
            type: ReferenceFieldType.dropdown,
            options: ['نقدي', 'عيني']),
      ],
      pickIcon: true,
      pickColor: true,
    ),
    ReferenceConfig(
      kind: ReferenceKind.expenseCategories,
      collection: 'expense_categories',
      title: 'تصنيفات المصروفات',
      singularLabel: 'تصنيف مصروف',
      icon: 'money',
      color: '#E53935',
      description: 'أبواب المصروفات في الجمعية.',
      fields: [
        ReferenceField('needsApproval', 'يحتاج اعتماد مدير؟',
            type: ReferenceFieldType.switchField),
      ],
    ),
    ReferenceConfig(
      kind: ReferenceKind.inventoryCategories,
      collection: 'inventory_categories',
      title: 'تصنيفات المخزن',
      singularLabel: 'تصنيف مخزن',
      icon: 'warehouse',
      color: '#6D4C41',
      description: 'تصنيفات أصناف المخزون.',
    ),
    ReferenceConfig(
      kind: ReferenceKind.stockReasons,
      collection: 'stock_reasons',
      title: 'أسباب حركات المخزون',
      singularLabel: 'سبب',
      icon: 'swap',
      color: '#8D6E63',
      description: 'أسباب الصرف والمرتجع المستخدمة في حركات المخزن.',
      fields: [
        ReferenceField('kind', 'النوع',
            type: ReferenceFieldType.dropdown,
            options: ['صرف', 'مرتجع']),
      ],
    ),
    ReferenceConfig(
      kind: ReferenceKind.units,
      collection: 'units',
      title: 'وحدات القياس',
      singularLabel: 'وحدة قياس',
      icon: 'straighten',
      color: '#5E35B1',
      description: 'الوحدات المستخدمة في المخزن والمساعدات.',
      fields: [
        ReferenceField('abbreviation', 'الاختصار', hint: 'مثال: كجم، لتر'),
      ],
    ),
    ReferenceConfig(
      kind: ReferenceKind.familyStatuses,
      collection: 'family_statuses',
      title: 'حالات الأسر',
      singularLabel: 'حالة',
      icon: 'status',
      color: '#3949AB',
      description: 'الحالات المستخدمة لأسر النظام.',
      fields: [
        ReferenceField('sortOrder', 'الترتيب', type: ReferenceFieldType.number),
      ],
      pickColor: true,
    ),
    ReferenceConfig(
      kind: ReferenceKind.priorities,
      collection: 'priorities',
      title: 'درجات الأولوية',
      singularLabel: 'درجة أولوية',
      icon: 'priority',
      color: '#D84315',
      description: 'أولويات الحالات في النظام.',
      fields: [
        ReferenceField('sortOrder', 'الترتيب', type: ReferenceFieldType.number),
      ],
      pickColor: true,
    ),
    ReferenceConfig(
      kind: ReferenceKind.rejectionReasons,
      collection: 'rejection_reasons',
      title: 'أسباب الرفض',
      singularLabel: 'سبب رفض',
      icon: 'block',
      color: '#424242',
      description: 'أسباب جاهزة تُستخدم عند رفض الطلبات.',
    ),
  ];

  static ReferenceConfig of(ReferenceKind kind) =>
      configs.firstWhere((c) => c.kind == kind);
}

/// أسماء أيقونات جاهزة تعرضها شاشات الإدارة في اختيار الأيقونة.
const kAdminIconNames = <String>[
  'handshake',
  'volunteer',
  'family',
  'money',
  'warehouse',
  'swap',
  'straighten',
  'status',
  'priority',
  'block',
  'category',
  'medical',
  'clothes',
  'food',
  'water',
  'education',
  'home',
  'favorite',
];