import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/widgets/form_widgets.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/models/family_case.dart';
import '../../data/models/questions_config.dart';
import '../cubits/family_case_cubit.dart';

class CaseFormScreen extends StatefulWidget {
  const CaseFormScreen({super.key, this.existingCase});

  final FamilyCase? existingCase;

  @override
  State<CaseFormScreen> createState() => _CaseFormScreenState();
}

class _CaseFormScreenState extends State<CaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _headName;
  late final TextEditingController _phone1;
  late final TextEditingController _phone2;
  late final TextEditingController _address;
  late final TextEditingController _pension;
  late final TextEditingController _description;

  String? _governorate;
  String? _socialStatus;
  String? _helpType;
  String? _classification;
  bool _hasWork = false;
  DateTime _registrationDate = DateTime.now();

  final Map<String, bool> _questionAnswers = {};
  late final Map<String, Map<String, TextEditingController>> _questionDetail;

  bool _saving = false;

  bool get _isEditing => widget.existingCase != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCase;
    _headName = TextEditingController(text: existing?.familyHeadName ?? '');
    _phone1 = TextEditingController(text: existing?.phone1 ?? '');
    _phone2 = TextEditingController(text: existing?.phone2 ?? '');
    _address = TextEditingController(text: existing?.address ?? '');
    _pension = TextEditingController(
      text: existing?.pensionValue != null
          ? '${existing!.pensionValue}'
          : '',
    );
    _description =
        TextEditingController(text: existing?.initialDescription ?? '');
    _governorate = existing?.governorate;
    _socialStatus = existing?.socialStatus;
    _helpType = existing?.helpType;
    _classification = existing?.caseClassification;
    _hasWork = existing?.hasWork ?? false;
    _registrationDate = existing?.registrationDate ?? DateTime.now();

    _questionDetail = {
      for (final q in kQuestions)
        q.key: {
          for (final f in q.fields) f.key: TextEditingController(),
        },
    };

    for (final q in kQuestions) {
      final stored = existing?.questions[q.key];
      final answered = stored?.answered ?? false;
      _questionAnswers[q.key] = answered;
      if (stored != null) {
        for (final entry in stored.details.entries) {
          final controller = _questionDetail[q.key]?[entry.key];
          if (controller != null) {
            controller.text = entry.value.toString();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _headName.dispose();
    _phone1.dispose();
    _phone2.dispose();
    _address.dispose();
    _pension.dispose();
    _description.dispose();
    for (final map in _questionDetail.values) {
      for (final c in map.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  double? _parseDouble(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return double.tryParse(s.trim());
  }

  Map<String, FamilyQuestion> _buildQuestions() {
    final result = <String, FamilyQuestion>{};
    for (final q in kQuestions) {
      final answered = _questionAnswers[q.key] ?? false;
      final details = <String, dynamic>{};
      for (final f in q.fields) {
        final controller = _questionDetail[q.key]?[f.key];
        final text = controller?.text.trim() ?? '';
        if (text.isNotEmpty) {
          details[f.key] = f.isNumeric ? double.tryParse(text) ?? text : text;
        }
      }
      result[q.key] = FamilyQuestion(
        answered: answered || details.isNotEmpty,
      )..details = details;
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى استكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.existingCase;
      final isNew = existing == null;

      final statusHistory = existing?.statusHistory ?? [];
      final familyCase = FamilyCase(
        id: existing?.id,
        familyHeadName: _headName.text.trim(),
        phone1: _phone1.text.trim(),
        phone2: _phone2.text.trim(),
        address: _address.text.trim(),
        governorate: _governorate!,
        socialStatus: _socialStatus!,
        helpType: _helpType!,
        hasWork: _hasWork,
        pensionValue: _parseDouble(_pension.text),
        initialDescription: _description.text.trim(),
        registrationDate: _registrationDate,
        caseClassification: _classification!,
        status: existing?.status ?? CaseStatus.underReview,
        statusHistory: statusHistory,
        questions: _buildQuestions(),
        routedToPrograms: existing?.routedToPrograms ?? false,
        routedAt: existing?.routedAt,
        programAssigned: existing?.programAssigned,
        programNotes: existing?.programNotes,
        createdBy: existing?.createdBy ??
            context.read<AuthCubit>().state.user?.uid,
      );

      bool ok;
      if (isNew) {
        familyCase.statusHistory.add(StatusHistoryEntry(
          status: CaseStatus.underReview.label,
          at: now,
        ));
        ok = await context.read<FamilyCaseCubit>().createCase(familyCase);
      } else {
        ok = await context.read<FamilyCaseCubit>().updateCase(familyCase);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew
                  ? 'تم حفظ الحالة، والحالة الحالية: تحت المراجعة'
                  : 'تم تحديث الحالة بنجاح',
            ),
            backgroundColor: ok ? null : Colors.red.shade700,
          ),
        );
      }

      if (ok && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClipOval(
              child: Image(
                image: AssetImage('assets/images/logo.jpg'),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isEditing ? 'تعديل الحالة' : 'حالة جديدة',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('البيانات الأساسية للأسرة', Icons.family_restroom),
            const SizedBox(height: 12),
            _card([
              TextFormField(
                controller: _headName,
                decoration: appFieldDecoration(
                  context,
                  label: 'اسم رب الأسرة / الحالة *',
                  icon: Icons.person_outline,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone1,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                      decoration: appFieldDecoration(
                        context,
                        label: 'رقم الهاتف الأول *',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phone2,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                      decoration: appFieldDecoration(
                        context,
                        label: 'رقم الهاتف الثاني',
                        icon: Icons.phone_android_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: appFieldDecoration(
                  context,
                  label: 'العنوان بالتفصيل *',
                  icon: Icons.location_on_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'المحافظة',
                items: kGovernorates,
                value: _governorate,
                onChanged: (v) => setState(() => _governorate = v),
                decoration: appFieldDecoration(
                  context,
                  label: 'المحافظة',
                  icon: Icons.map_outlined,
                ),
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'الحالة الاجتماعية',
                items: kSocialStatuses,
                value: _socialStatus,
                onChanged: (v) => setState(() => _socialStatus = v),
                decoration: appFieldDecoration(
                  context,
                  label: 'الحالة الاجتماعية',
                  icon: Icons.people_outline,
                ),
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'نوع المساعدة المطلوبة',
                items: kHelpTypes,
                value: _helpType,
                onChanged: (v) => setState(() => _helpType = v),
                decoration: appFieldDecoration(
                  context,
                  label: 'نوع المساعدة المطلوبة',
                  icon: Icons.volunteer_activism_outlined,
                ),
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'تصنيف الحالة',
                items: kClassificationTypes,
                value: _classification,
                onChanged: (v) => setState(() => _classification = v),
                decoration: appFieldDecoration(
                  context,
                  label: 'تصنيف الحالة',
                  icon: Icons.category_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionHeader('الوضع الوظيفي والمالي', Icons.work_outline),
            const SizedBox(height: 12),
            _card([
              YesNoField(
                title: 'هل يوجد عمل حاليًا؟',
                value: _hasWork,
                onChanged: (v) => setState(() => _hasWork = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pension,
                textDirection: TextDirection.ltr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: appFieldDecoration(
                  context,
                  label: 'قيمة المعاش أو التأمينات (إن وجدت)',
                  icon: Icons.savings_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionHeader('تاريخ تسجيل الحالة', Icons.event_outlined),
            const SizedBox(height: 12),
            _card([
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: appFieldDecoration(
                    context,
                    label: 'تاريخ تسجيل الحالة',
                    icon: Icons.calendar_month,
                  ),
                  child:
                      Text(DateFormat('yyyy/MM/dd').format(_registrationDate)),
                ),
              ),
            ]),
            const SizedBox(height: 22),
            _sectionHeader('الأسئلة الأولية عن الحالة', Icons.quiz_outlined),
            const SizedBox(height: 6),
            Text(
              'اختر "نعم" في الأسئلة ثم أدخل التفاصيل المرتبطة بها.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final q in kQuestions) ...[
              _questionCard(q),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 22),
            _sectionHeader('وصف الحالة', Icons.description_outlined),
            const SizedBox(height: 12),
            _card([
              TextFormField(
                controller: _description,
                maxLines: 5,
                decoration: appFieldDecoration(
                  context,
                  label: 'الوصف المبدئي للحالة',
                  icon: Icons.description_outlined,
                ).copyWith(
                  hintText: 'أي معلومات أو ملاحظات إضافية عن الحالة...',
                  alignLabelWithHint: true,
                ),
              ),
            ]),
            const SizedBox(height: 28),
            AppPrimaryButton(
              loading: _saving,
              onPressed: _save,
              label: _isEditing ? 'حفظ التعديلات' : 'حفظ الحالة (تحت المراجعة)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _questionCard(QuestionField q) {
    final answered = _questionAnswers[q.key] ?? false;
    final isHousing = q.key == 'housing';

    return _card([
      YesNoField(
        title: q.title,
        value: answered,
        onChanged: (v) => setState(() => _questionAnswers[q.key] = v),
      ),
      if (isHousing) const SizedBox(height: 8),
      if (isHousing)
        Text(
          'إيجار / ملك',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      if (answered) ...[
        const SizedBox(height: 12),
        for (final f in q.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: _questionDetail[q.key]![f.key],
              textDirection: f.isNumeric ? TextDirection.ltr : null,
              keyboardType: f.isNumeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: appFieldDecoration(
                context,
                label: f.label,
                icon: f.isNumeric ? Icons.attach_money : Icons.edit_note,
              ).copyWith(
                hintText: f.hint.isEmpty ? null : f.hint,
              ),
            ),
          ),
      ],
    ]);
  }
}