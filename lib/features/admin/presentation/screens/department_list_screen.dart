import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/department.dart';
import '../cubits/department_cubit.dart';
import '../widgets/admin_ui.dart';
import 'department_form_screen.dart';

class DepartmentListScreen extends StatelessWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DepartmentCubit(),
      child: BlocListener<DepartmentCubit, DepartmentState>(
      listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
      listener: (context, state) =>
          showMessage(context, message: state.message, error: state.error),
      child: Scaffold(
        appBar: AppBar(title: const Text('الأقسام')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة قسم'),
        ),
        body: BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, state) {
            switch (state.status) {
              case DepartmentStatus.initial:
              case DepartmentStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case DepartmentStatus.error:
                return ErrorView(message: state.error);
              case DepartmentStatus.empty:
                return const EmptyView(
                  icon: Icons.account_balance_outlined,
                  message: 'لا توجد أقسام بعد — أضف أول قسم',
                  actionLabel: 'إضافة قسم',
                );
              case DepartmentStatus.loaded:
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: state.departments.length,
                  itemBuilder: (context, index) {
                    final dept = state.departments[index];
                    return _DepartmentTile(
                      department: dept,
                      employeeCount: state.employeeCounts[dept.id] ?? 0,
                      onEdit: () => _openForm(context, dept),
                      onToggle: () =>
                          context.read<DepartmentCubit>().toggleActive(dept, !dept.isActive),
                      onArchive: () async {
                        final cubit = context.read<DepartmentCubit>();
                        if (await confirmDialog(
                          context,
                          title: 'أرشفة القسم',
                          message:
                              'تأكد من نقل موظفيه أولًا، ثم أرشفتها. لن يُحذف القسم نهائيًا.',
                          confirmLabel: 'أرشفة',
                        )) {
                          cubit.archive(dept);
                        }
                      },
                    );
                  },
                );
            }
          },
        ),
      ),
      ),
    );
  }

  void _openForm(BuildContext context, Department? dept) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepartmentFormScreen(department: dept),
      ),
    );
  }
}

class _DepartmentTile extends StatelessWidget {
  const _DepartmentTile({
    required this.department,
    required this.employeeCount,
    required this.onEdit,
    required this.onToggle,
    required this.onArchive,
  });

  final Department department;
  final int employeeCount;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = adminColor(department.color);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(adminIcon(department.icon), color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                department.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!department.isActive)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.pause_circle_outline,
                    size: 18, color: Colors.grey),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (department.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  department.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              children: [
                Icon(Icons.group_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$employeeCount موظف',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'toggle':
                onToggle();
                break;
              case 'archive':
                onArchive();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('تعديل'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(department.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                title: Text(department.isActive ? 'تعطيل' : 'تفعيل'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'archive',
              child: ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('أرشفة'),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}