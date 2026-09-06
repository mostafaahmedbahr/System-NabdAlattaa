import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../cubits/family_case_cubit.dart';
import '../cubits/family_case_state.dart';
import '../../data/models/family_case.dart';
import '../../data/models/questions_config.dart';
import 'case_form_screen.dart';

class CaseDetailsScreen extends StatelessWidget {
  const CaseDetailsScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyCaseCubit, FamilyCaseState>(
      builder: (context, state) {
        FamilyCase? caseItem;
        for (final c in state.cases) {
          if (c.id == caseId) {
            caseItem = c;
            break;
          }
        }
        if (caseItem == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('الحالة غير موجودة')),
          );
        }
        return _CaseDetailsView(caseItem: caseItem);
      },
    );
  }
}

class _CaseDetailsView extends StatelessWidget {
  const _CaseDetailsView({required this.caseItem});

  final FamilyCase caseItem;

  Future<void> _changeStatus(BuildContext context, CaseStatus newStatus) async {
    if (newStatus == caseItem.status) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير حالة الطلب'),
        content: Text(
          'هل أنت متأكد من تغيير حالة الطلب إلى "${newStatus.label}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    final ok = await context
        .read<FamilyCaseCubit>()
        .changeStatus(caseItem.id!, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'تم تحديث الحالة إلى: ${newStatus.label}' : 'خطأ في تحديث الحالة'),
          backgroundColor: ok ? null : Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _routeToPrograms(BuildContext context) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('توجيه إلى قسم البرامج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم تحويل هذه الحالة إلى قسم البرامج لدراسة احتياجها وتحديد البرنامج أو نوع المساعدة المناسب لها.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('توجيه'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    final ok = await context
        .read<FamilyCaseCubit>()
        .routeToPrograms(caseItem.id!, notes: notesController.text.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'تم توجيه الحالة إلى قسم البرامج' : 'خطأ في التوجيه'),
          backgroundColor: ok ? null : Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(caseItem.familyHeadName),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaseFormScreen(existingCase: caseItem),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(context),
          const SizedBox(height: 16),
          _infoCard(),
          const SizedBox(height: 16),
          if (caseItem.routedToPrograms) ...[
            _routedCard(context),
            const SizedBox(height: 16),
          ],
          _questionsCard(),
          const SizedBox(height: 16),
          _statusHistoryCard(),
          const SizedBox(height: 24),
          if (!caseItem.routedToPrograms)
            FilledButton.icon(
              onPressed: () => _routeToPrograms(context),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('توجيه إلى قسم البرامج'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final statusColor = switch (caseItem.status) {
      CaseStatus.underReview => Colors.blue,
      CaseStatus.rejected => Colors.red,
      CaseStatus.needsFieldResearch => Colors.orange,
      CaseStatus.fieldResearchDone => Colors.green,
    };

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  caseItem.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('تغيير حالة الطلب إلى:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CaseStatus.values
                .where((s) => s != caseItem.status)
                .map(
                  (s) => ActionChip(
                    label: Text(s.label),
                    onPressed: () => _changeStatus(context, s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final dateFmt = DateFormat('yyyy/MM/dd');
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('بيانات الأسرة'),
          const SizedBox(height: 12),
          _infoRow('المحافظة', caseItem.governorate),
          _infoRow('العنوان', caseItem.address),
          _infoRow('رقم الهاتف الأول', caseItem.phone1),
          if (caseItem.phone2.isNotEmpty)
            _infoRow('رقم الهاتف الثاني', caseItem.phone2),
          _infoRow('الحالة الاجتماعية', caseItem.socialStatus),
          _infoRow('نوع المساعدة المطلوبة', caseItem.helpType),
          _infoRow('تصنيف الحالة', caseItem.caseClassification),
          _infoRow('هناك عمل حاليًا', caseItem.hasWork ? 'نعم' : 'لا'),
          if (caseItem.pensionValue != null)
            _infoRow('قيمة المعاش / التأمينات', '${caseItem.pensionValue} ج.م'),
          _infoRow('تاريخ التسجيل', dateFmt.format(caseItem.registrationDate)),
        ],
      ),
    );
  }

  Widget _routedCard(BuildContext context) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                'محولة إلى قسم البرامج',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (caseItem.routedAt != null)
            _infoRow(
              'تاريخ التوجيه',
              DateFormat('yyyy/MM/dd HH:mm').format(caseItem.routedAt!),
            ),
          if (caseItem.programAssigned != null)
            _infoRow('البرنامج المحدد', caseItem.programAssigned!),
        ],
      ),
    );
  }

  Widget _questionsCard() {
    final answeredQuestions = kQuestions.where((q) {
      final question = caseItem.questions[q.key];
      return question?.answered == true ||
          (question?.details.isNotEmpty ?? false);
    }).toList();

    if (answeredQuestions.isEmpty) {
      return _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardTitle('الأسئلة الأولية'),
            const SizedBox(height: 12),
            const Text('لم يتم إدخال إجابات عن الأسئلة.'),
          ],
        ),
      );
    }

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('الأسئلة الأولية'),
          const SizedBox(height: 12),
          for (final q in answeredQuestions) ...[
            Text(q.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final f in q.fields)
              if (caseItem.questions[q.key]?.details[f.key] != null)
                _infoRow(
                  f.label,
                  '${caseItem.questions[q.key]!.details[f.key]}',
                  indent: true,
                ),
            const Divider(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _statusHistoryCard() {
    if (caseItem.statusHistory.isEmpty) {
      return _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardTitle('سجل تغييرات الحالة'),
            const SizedBox(height: 12),
            const Text('لا يوجد سجل حاليًا.'),
          ],
        ),
      );
    }
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('سجل تغييرات الحالة'),
          const SizedBox(height: 12),
          for (final entry in caseItem.statusHistory.reversed) ...[
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(entry.at),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _cardTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _infoRow(String label, String value, {bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6, left: indent ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}