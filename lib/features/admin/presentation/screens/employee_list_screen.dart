import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/models/user_profile.dart';
import '../../data/models/role.dart';
import '../cubits/department_cubit.dart';
import '../cubits/employee_cubit.dart';
import '../widgets/admin_ui.dart';
import 'employee_form_screen.dart';
import 'employee_permissions_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'all'; // all | active | inactive
  String _departmentFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => EmployeeCubit()),
        BlocProvider(create: (_) => DepartmentCubit()),
      ],
      child: BlocListener<EmployeeCubit, EmployeeState>(
      listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
      listener: (context, state) =>
          showMessage(context, message: state.message, error: state.error),
      child: Scaffold(
        appBar: AppBar(title: const Text('الموظفون')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('إضافة موظف'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: appFieldDecoration(
                  context,
                  label: 'بحث بالاسم أو الهاتف...',
                  icon: Icons.search,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('الكل')),
                      ButtonSegment(value: 'active', label: Text('نشط')),
                      ButtonSegment(value: 'inactive', label: Text('معطل')),
                    ],
                    selected: {_statusFilter},
                    onSelectionChanged: (s) =>
                        setState(() => _statusFilter = s.first),
                  ),
                  const Spacer(),
                  BlocBuilder<DepartmentCubit, DepartmentState>(
                    builder: (context, deptState) {
                      final depts = deptState.departments;
                      if (depts.isEmpty) return const SizedBox.shrink();
                      return DropdownButton<String>(
                        value: _departmentFilter,
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('كل الأقسام'),
                          ),
                          for (final d in depts)
                            DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _departmentFilter = v ?? 'all'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<EmployeeCubit, EmployeeState>(
                builder: (context, state) {
                  switch (state.status) {
                    case EmployeeStatus.initial:
                    case EmployeeStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case EmployeeStatus.error:
                      return ErrorView(message: state.error);
                    case EmployeeStatus.empty:
                      return const EmptyView(
                        icon: Icons.group_outlined,
                        message: 'لا يوجد موظفون بعد — أضف أول موظف',
                        actionLabel: 'إضافة موظف',
                      );
                    case EmployeeStatus.loaded:
                      final filtered = _filter(state.employees);
                      if (filtered.isEmpty) {
                        return const EmptyView(
                          icon: Icons.search_off,
                          message: 'لا نتائج مطابقة للبحث',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildTile(context, filtered[index]),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<UserProfile> _filter(List<UserProfile> employees) {
    return employees.where((e) {
      final matchesQuery = _query.isEmpty ||
          e.name.contains(_query) ||
          e.phone.contains(_query) ||
          e.email.contains(_query);
      final matchesStatus = switch (_statusFilter) {
        'active' => e.isActive,
        'inactive' => !e.isActive,
        _ => true,
      };
      final matchesDept = _departmentFilter == 'all' ||
          e.departmentId == _departmentFilter;
      return matchesQuery && matchesStatus && matchesDept;
    }).toList();
  }

  Widget _buildTile(BuildContext context, UserProfile employee) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.read<EmployeeCubit>().state;
    final roles = state.roles;
    final initial = employee.name.isNotEmpty ? employee.name[0] : 'م';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: () => _openForm(context, employee),
        leading: CircleAvatar(
          backgroundColor:
              (employee.isActive ? Colors.teal : Colors.grey).withValues(alpha: 0.15),
          child: Text(
            initial,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: employee.isActive ? Colors.teal : Colors.grey,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: employee.isActive
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                employee.isActive ? 'نشط' : 'معطل',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: employee.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                if (employee.roleName.isNotEmpty)
                  _MiniChip(text: employee.roleName, color: scheme.primary),
                if (employee.department.isNotEmpty)
                  _MiniChip(text: employee.department, color: Colors.indigo),
                if (employee.jobTitle.isNotEmpty)
                  _MiniChip(text: employee.jobTitle, color: Colors.brown),
              ],
            ),
            if (employee.lastLoginAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      'آخر دخول: ${DateFormat('yyyy/MM/dd HH:mm').format(employee.lastLoginAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            final cubit = context.read<EmployeeCubit>();
            switch (value) {
              case 'edit':
                _openForm(context, employee);
                break;
              case 'perms':
                _openPerms(context, employee);
                break;
              case 'toggle':
                cubit.toggleActive(employee.uid, !employee.isActive, employee.name);
                break;
              case 'archive':
                () async {
                  if (!context.mounted) return;
                  if (await confirmDialog(
                    context,
                    title: 'أرشفة الموظف',
                    message: 'سيتم إخفاء حساب ${employee.name} من النظام. يمكنك إعادة تنشيطه لاحقًا بإعادة تفعيل الحساب.',
                    confirmLabel: 'أرشفة',
                  )) {
                    cubit.archive(employee.uid, employee.name);
                  }
                }();
                break;
              case 'role':
                showModalBottomSheet<Role>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final role in roles)
                          ListTile(
                            leading: Icon(
                              Icons.verified_user_outlined,
                              color: role.id == employee.roleId
                                  ? scheme.primary
                                  : null,
                            ),
                            title: Text(role.name),
                            subtitle: Text(role.description),
                            trailing: role.id == employee.roleId
                                ? Icon(Icons.check, color: scheme.primary)
                                : null,
                            onTap: () => Navigator.pop(ctx, role),
                          ),
                      ],
                    ),
                  ),
                ).then((role) {
                  if (role != null && mounted) {
                    cubit.changeRole(employee.uid, role, employee.name);
                  }
                });
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
            const PopupMenuItem(
              value: 'perms',
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings_outlined),
                title: Text('الصلاحيات'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'role',
              child: ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('تغيير الدور'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(employee.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                title: Text(employee.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب'),
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

  void _openForm(BuildContext context, UserProfile? employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(employee: employee),
      ),
    );
  }

  void _openPerms(BuildContext context, UserProfile employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeePermissionsScreen(employee: employee),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}