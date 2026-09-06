class QuestionField {
  const QuestionField({
    required this.key,
    required this.title,
    required this.fields,
  });

  final String key;
  final String title;

  /// Optional details fields revealed when the answer is "yes".
  /// Each entry: [label, isNumeric, hint]
  final List<QuestionDetailField> fields;
}

class QuestionDetailField {
  const QuestionDetailField({
    required this.label,
    required this.key,
    this.isNumeric = false,
    this.hint = '',
  });

  final String label;
  final String key;
  final bool isNumeric;
  final String hint;
}

const kGovernorates = [
  'القاهرة',
  'الجيزة',
  'الإسكندرية',
  'الدقهلية',
  'الشرقية',
  'القليوبية',
  'الغربية',
  'المنوفية',
  'كفر الشيخ',
  'البحيرة',
  'دمياط',
  'بورسعيد',
  'الإسماعيلية',
  'السويس',
  'شمال سيناء',
  'جنوب سيناء',
  'الفيوم',
  'بني سويف',
  'المنيا',
  'أسيوط',
  'سوهاج',
  'قنا',
  'الأقصر',
  'أسوان',
  'البحر الأحمر',
  'الوادي الجديد',
  'مطروح',
];

const kSocialStatuses = [
  'أرمل/ة',
  'مطلّق/ة',
  'مطلق/ة - يعول أبناء',
  'يتيم',
  'فقد عائل الأسرة',
  'إعاقة',
  'عائلة عادية',
  'أخرى',
];

const kHelpTypes = [
  'مساعدة مالية',
  'مساعدات غذائية',
  'مساعدات شهرية',
  'علاج ومصاريف طبية',
  'مصاريف تعليمية',
  'مشروع صغير / دخل منتج',
  'تجهيز / أثاث',
  'أخرى',
];

const kClassificationTypes = [
  'حالة عاجلة',
  'حالة عادية',
  'حالة مزمنة',
  'حالة موسمية',
];

const kEducationalStages = [
  'رياض أطفال',
  'ابتدائي',
  'إعدادي',
  'ثانوي',
  'جامعي',
  'تعليم فني / مهني',
];

const kQuestions = [
  QuestionField(
    key: 'workingMembers',
    title: 'هل يوجد أفراد عاملون داخل الأسرة؟',
    fields: [
      QuestionDetailField(
        label: 'عدد العاملين',
        key: 'count',
        isNumeric: true,
        hint: 'مثال: 2',
      ),
      QuestionDetailField(
        label: 'قيمة الدخل (إن أمكن)',
        key: 'income',
        isNumeric: true,
        hint: 'مثال: 4000',
      ),
    ],
  ),
  QuestionField(
    key: 'previousHelp',
    title: 'هل سبق للأسرة الحصول على مساعدة من المؤسسة؟',
    fields: [
      QuestionDetailField(
        label: 'نوع المساعدة السابقة',
        key: 'helpType',
        hint: 'مثال: مساعدة مالية',
      ),
      QuestionDetailField(
        label: 'قيمتها / تفاصيلها',
        key: 'value',
        hint: 'مثال: 1500 ج.م',
      ),
    ],
  ),
  QuestionField(
    key: 'sickMember',
    title: 'هل يوجد فرد مريض داخل الأسرة؟',
    fields: [
      QuestionDetailField(
        label: 'وصف المرض',
        key: 'illness',
        hint: 'مثال: مرض مزمن',
      ),
      QuestionDetailField(
        label: 'تكلفة العلاج (إن وجدت)',
        key: 'treatmentCost',
        isNumeric: true,
        hint: 'مثال: 3000',
      ),
    ],
  ),
  QuestionField(
    key: 'childrenEducation',
    title: 'هل يوجد أبناء في مراحل التعليم؟',
    fields: [
      QuestionDetailField(
        label: 'عدد الأبناء',
        key: 'count',
        isNumeric: true,
        hint: 'مثال: 3',
      ),
      QuestionDetailField(
        label: 'المرحلة التعليمية',
        key: 'stage',
        hint: 'مثال: إعدادي',
      ),
      QuestionDetailField(
        label: 'مصاريف / احتياجات خاصة',
        key: 'expenses',
        hint: 'مثال: مصاريف دراسية',
      ),
    ],
  ),
  QuestionField(
    key: 'housing',
    title: 'نوع السكن',
    fields: [
      QuestionDetailField(
        label: 'قيمة الإيجار الشهري (إن كان إيجار)',
        key: 'rentValue',
        isNumeric: true,
        hint: 'مثال: 1200',
      ),
    ],
  ),
  QuestionField(
    key: 'existingProject',
    title: 'هل يوجد مشروع قائم لدى الأسرة؟',
    fields: [
      QuestionDetailField(
        label: 'نوع المشروع',
        key: 'type',
        hint: 'مثال: تربية مواشي',
      ),
      QuestionDetailField(
        label: 'وصف مختصر',
        key: 'description',
        hint: 'وصف مختصر للمشروع',
      ),
      QuestionDetailField(
        label: 'الدخل التقريبي',
        key: 'income',
        isNumeric: true,
        hint: 'مثال: 2000',
      ),
    ],
  ),
  QuestionField(
    key: 'otherSupport',
    title: 'هل يوجد مصدر آخر يساعد الأسرة؟',
    fields: [
      QuestionDetailField(
        label: 'مصدر المساعدة',
        key: 'source',
        hint: 'مثال: جمعية خيرية',
      ),
      QuestionDetailField(
        label: 'القيمة (إن وجدت)',
        key: 'value',
        isNumeric: true,
        hint: 'مثال: 500',
      ),
    ],
  ),
  QuestionField(
    key: 'relativesHelp',
    title: 'هل يوجد أقارب يساعدون الأسرة؟',
    fields: [
      QuestionDetailField(
        label: 'نوع المساعدة',
        key: 'type',
        hint: 'مثال: دعم شهري',
      ),
      QuestionDetailField(
        label: 'القيمة (إن أمكن)',
        key: 'value',
        isNumeric: true,
        hint: 'مثال: 300',
      ),
    ],
  ),
  QuestionField(
    key: 'willingProject',
    title: 'هل لدى الأسرة الرغبة في إقامة مشروع أو ممارسة نشاط يدر دخلًا؟',
    fields: [
      QuestionDetailField(
        label: 'نوع المشروع أو النشاط المقترح',
        key: 'type',
        hint: 'مثال: مشروع خياطة',
      ),
    ],
  ),
];