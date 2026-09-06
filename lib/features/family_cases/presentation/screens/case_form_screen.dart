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
    _description = TextEditingController(text: existing?.initialDescription ?? '');
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
              isNew ? 'تم حفظ الحالة، والحالة الحالية: تحت المراجعة' : 'تم تحديث الحالة بنجاح',
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل الحالة' : 'حالة جديدة'),
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
                decoration: const InputDecoration(
                  labelText: 'اسم رب الأسرة / الحالة *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone1,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف الأول *',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف الثاني',
                        prefixIcon: Icon(Icons.phone_android),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'العنوان بالتفصيل *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'الحالة الاجتماعية',
                items: kSocialStatuses,
                value: _socialStatus,
                onChanged: (v) => setState(() => _socialStatus = v),
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'نوع المساعدة المطلوبة',
                items: kHelpTypes,
                value: _helpType,
                onChanged: (v) => setState(() => _helpType = v),
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'تصنيف الحالة',
                items: kClassificationTypes,
                value: _classification,
                onChanged: (v) => setState(() => _classification = v),
              ),
            ]),
            const SizedBox(height: 20),
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
                decoration: const InputDecoration(
                  labelText: 'قيمة المعاش أو التأمينات (إن وجدت)',
                  prefixIcon: Icon(Icons.savings_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionHeader('تاريخ تسجيل الحالة', Icons.event_outlined),
            const SizedBox(height: 12),
            _card([
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ تسجيل الحالة',
                    prefixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                  child:
                      Text(DateFormat('yyyy/MM/dd').format(_registrationDate)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionHeader('الأسئلة الأولية عن الحالة', Icons.quiz_outlined),
            const SizedBox(height: 4),
            Text(
              'اختر "نعم" في الأسئلة ثم أدخل التفاصيل المرتبطة بها.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final q in kQuestions) ...[
              _questionCard(q),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            _sectionHeader('وصف الحالة', Icons.description_outlined),
            const SizedBox(height: 12),
            _card([
              TextFormField(
                controller: _description,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'الوصف المبدئي للحالة',
                  hintText: 'أي معلومات أو ملاحظات إضافية عن الحالة...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ]),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _isEditing ? 'حفظ التعديلات' : 'حفظ الحالة (تحت المراجعة)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
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
              decoration: InputDecoration(
                labelText: f.label,
                hintText: f.hint,
                border: const OutlineInputBorder(),
                prefixIcon: f.isNumeric
                    ? const Icon(Icons.attach_money)
                    : null,
              ),
            ),
          ),
      ],
    ]);
  }
}