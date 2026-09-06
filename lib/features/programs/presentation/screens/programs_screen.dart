import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/form_widgets.dart';
import '../../../family_cases/data/models/family_case.dart';
import '../../../family_cases/presentation/cubits/family_case_cubit.dart';
import '../../../family_cases/presentation/cubits/family_case_state.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  static const _programs = [
    'مساندة مالية شهرية',
    'مساعدات غذائية',
    'برنامج علاج ودعم صحي',
    'برنامج التعليم والمصاريف الدراسية',
    'برنامج المشروعات الصغيرة',
    'تجهيزات وحالات عاجلة',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قسم البرامج')),
      body: BlocBuilder<FamilyCaseCubit, FamilyCaseState>(
        builder: (context, state) {
          final routed = state.cases.where((c) => c.routedToPrograms).toList();

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: _HeaderCard(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ProgramSelector(onAssign: (String? program) {
                  if (program == null) return;
                  final unassigned = routed
                      .where((c) => c.programAssigned == null)
                      .toList();
                  _showAssignFlow(context, program, unassigned);
                }),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: state.errorMessage != null
                    ? Center(child: Text(state.errorMessage!))
                    : _RoutedCasesList(cases: routed),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAssignFlow(
    BuildContext context,
    String program,
    List<FamilyCase> unassigned,
  ) async {
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد حالات غير مسندة لإسنادها لهذا البرنامج')),
      );
      return;
    }

    if (unassigned.length > 1) {
      final selected = await showDialog<FamilyCase>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text('اختر الحالة لإسنادها إلى برنامج "$program"'),
          children: [
            for (final c in unassigned)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, c),
                child: Text('${c.familyHeadName} - ${c.governorate}'),
              ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (selected != null) {
        await _assign(context, selected, program);
      }
      return;
    }

    await _assign(context, unassigned.first, program);
  }

  Future<void> _assign(
    BuildContext context,
    FamilyCase caseItem,
    String program,
  ) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إسناد إلى: $program'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الحالة: ${caseItem.familyHeadName}'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات البرنامج',
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
            child: const Text('إسناد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notes = notesController.text.trim();
    notesController.dispose();

    if (!context.mounted) return;
    final ok = await context.read<FamilyCaseCubit>().assignProgram(
          caseItem.id!,
          program: program,
          notes: notes,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'تم إسناد الحالة إلى برنامج "$program"' : 'خطأ في الإسناد'),
          backgroundColor: ok ? null : Colors.red.shade700,
        ),
      );
    }
  }
}

class _ProgramSelector extends StatefulWidget {
  const _ProgramSelector({required this.onAssign});

  final ValueChanged<String?> onAssign;

  @override
  State<_ProgramSelector> createState() => _ProgramSelectorState();
}

class _ProgramSelectorState extends State<_ProgramSelector> {
  String? _program;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField(
      label: 'البرنامج / نوع المساعدة',
      items: ProgramsScreen._programs,
      value: _program,
      hint: 'اختر البرنامج ثم الحالة',
      isRequired: false,
      onChanged: (v) {
        setState(() => _program = v);
        widget.onAssign(v);
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.handshake_outlined),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'برامج المؤسسة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'دراسة احتياج الحالات المحولة وتحديد البرنامج أو نوع المساعدة المناسب لها',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutedCasesList extends StatelessWidget {
  const _RoutedCasesList({required this.cases});

  final List<FamilyCase> cases;

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('لا توجد حالات محولة حاليًا'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: cases.length,
      itemBuilder: (context, i) {
        final c = cases[i];
        return ListTile(
          leading: const Icon(Icons.family_restroom),
          title: Text(c.familyHeadName),
          subtitle: Text(
            '${c.governorate} • ${c.helpType}'
            '${c.programAssigned != null ? '\nالبرنامج: ${c.programAssigned}' : ''}',
          ),
          isThreeLine: c.programAssigned != null,
          tileColor: Colors.grey.shade100.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: c.programAssigned != null
                ? BorderSide(color: Theme.of(context).colorScheme.primary)
                : BorderSide.none,
          ),
        );
      },
    );
  }
}