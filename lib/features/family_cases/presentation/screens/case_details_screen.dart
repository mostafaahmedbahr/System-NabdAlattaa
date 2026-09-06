import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../cubits/family_case_cubit.dart';
import '../cubits/family_case_state.dart';
import '../../data/models/family_case.dart';
import '../../data/models/questions_config.dart';
import 'case_form_screen.dart';
import 'case_status_style.dart';

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
            appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.primary),
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
          content: Text(
              ok ? 'تم تحديث الحالة إلى: ${newStatus.label}' : 'خطأ في تحديث الحالة'),
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
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
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
          content:
              Text(ok ? 'تم توجيه الحالة إلى قسم البرامج' : 'خطأ في التوجيه'),
          backgroundColor: ok ? null : Colors.red.shade700,
        ),
      );
    }
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
            const Text(
              'تفاصيل الحالة',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
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
          _HeroCard(caseItem: caseItem),
          const SizedBox(height: 16),
          _statusCard(context),
          const SizedBox(height: 16),
          _infoCard(context),
          const SizedBox(height: 16),
          if (caseItem.routedToPrograms) ...[
            _routedCard(context),
            const SizedBox(height: 16),
          ],
          _questionsCard(context),
          const SizedBox(height: 16),
          _statusHistoryCard(context),
          const SizedBox(height: 24),
          if (!caseItem.routedToPrograms)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
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
    final statusColor = caseStatusColor(caseItem.status);
    final statusIcon = caseStatusIcon(caseItem.status);

    return _card(
      context,
      title: 'حالة الطلب',
      icon: Icons.flag_outlined,
      child: Column(
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
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      caseItem.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'تغيير حالة الطلب إلى:',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CaseStatus.values
                .where((s) => s != caseItem.status)
                .map(
                  (s) => ActionChip(
                    avatar: Icon(
                      caseStatusIcon(s),
                      size: 16,
                      color: caseStatusColor(s),
                    ),
                    label: Text(s.label),
                    labelStyle:
                        TextStyle(fontWeight: FontWeight.w600, color: caseStatusColor(s)),
                    side: BorderSide(color: caseStatusColor(s).withValues(alpha: 0.4)),
                    backgroundColor: caseStatusColor(s).withValues(alpha: 0.08),
                    onPressed: () => _changeStatus(context, s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final dateFmt = DateFormat('yyyy/MM/dd');
    return _card(
      context,
      title: 'بيانات الأسرة',
      icon: Icons.family_restroom_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[
      Row(
        children: [
          Icon(Icons.handshake_outlined, color: scheme.primary),
          const SizedBox(width: 8),
          const Text(
            'محولة إلى قسم البرامج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ];
    if (caseItem.routedAt != null) {
      rows.add(_infoRow(
        'تاريخ التوجيه',
        DateFormat('yyyy/MM/dd HH:mm').format(caseItem.routedAt!),
      ));
    }
    if (caseItem.programAssigned != null) {
      rows.add(_infoRow('البرنامج المحدد', caseItem.programAssigned!));
    }
    if (caseItem.programNotes?.isNotEmpty ?? false) {
      rows.add(_infoRow('ملاحظات البرنامج', caseItem.programNotes!));
    }
    return _card(
      context,
      title: 'التوجيه للبرامج',
      icon: Icons.handshake_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _questionsCard(BuildContext context) {
    final answeredQuestions = kQuestions.where((q) {
      final question = caseItem.questions[q.key];
      return question?.answered == true ||
          (question?.details.isNotEmpty ?? false);
    }).toList();

    return _card(
      context,
      title: 'الأسئلة الأولية',
      icon: Icons.quiz_outlined,
      child: answeredQuestions.isEmpty
          ? const Text(
              'لم يتم إدخال إجابات عن الأسئلة.',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final q in answeredQuestions) ...[
                  Text(
                    q.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final f in q.fields)
                    if (caseItem.questions[q.key]?.details[f.key] != null)
                      _infoRow(
                        f.label,
                        '${caseItem.questions[q.key]!.details[f.key]}',
                        indent: true,
                      ),
                  const Divider(height: 22),
                ],
              ],
            ),
    );
  }

  Widget _statusHistoryCard(BuildContext context) {
    return _card(
      context,
      title: 'سجل تغييرات الحالة',
      icon: Icons.history_rounded,
      child: caseItem.statusHistory.isEmpty
          ? const Text(
              'لا يوجد سجل حاليًا.',
              style: TextStyle(color: Colors.grey),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in caseItem.statusHistory.reversed) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          if (entry != caseItem.statusHistory.first)
                            Container(
                              width: 2,
                              height: 22,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.status,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('yyyy/MM/dd HH:mm')
                                    .format(entry.at),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool indent = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: indent ? 10 : 0),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.caseItem});

  final FamilyCase caseItem;

  @override
  Widget build(BuildContext context) {
    final statusColor = caseStatusColor(caseItem.status);
    final initial =
        caseItem.familyHeadName.isNotEmpty ? caseItem.familyHeadName[0] : 'ح';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [statusColor, statusColor.withValues(alpha: 0.72)],
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseItem.familyHeadName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${caseItem.governorate} - ${caseItem.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 15, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      caseItem.phone2.isNotEmpty
                          ? '${caseItem.phone1} • ${caseItem.phone2}'
                          : caseItem.phone1,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}