import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/user_profile.dart';
import '../../data/models/role.dart';
import '../cubits/department_cubit.dart';
import '../cubits/employee_cubit.dart';
import '../widgets/admin_ui.dart';

class EmployeeFormScreen extends StatelessWidget {
  const EmployeeFormScreen({super.key, this.employee});

  final UserProfile? employee;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => EmployeeCubit()),
        BlocProvider(create: (_) => DepartmentCubit()),
      ],
      child: _EmployeeFormBody(employee: employee),
    );
  }
}

class _EmployeeFormBody extends StatefulWidget {
  const _EmployeeFormBody({this.employee});

  final UserProfile? employee;

  @override
  State<_EmployeeFormBody> createState() => _EmployeeFormBodyState();
}

class _EmployeeFormBodyState extends State<_EmployeeFormBody> {
  late final _nameController =
      TextEditingController(text: widget.employee?.name ?? '');
  late final _phoneController =
      TextEditingController(text: widget.employee?.phone ?? '');
  late final _emailController =
      TextEditingController(text: widget.employee?.email ?? '');
  late final _passwordController = TextEditingController();
  late final _jobController =
      TextEditingController(text: widget.employee?.jobTitle ?? '');
  String? _departmentId;
  String? _departmentName;
  String? _roleId;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.employee != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    _departmentId ??= employee?.departmentId.isNotEmpty == true
        ? employee!.departmentId
        : null;
    _departmentName ??= employee?.department ?? '';
    final roles = context.select<EmployeeCubit, List<Role>>((c) => c.state.roles);
    _roleId ??= employee?.roleId ?? (roles.isEmpty ? null : roles.first.id);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل موظف' : 'إضافة موظف')),
      body: BlocListener<EmployeeCubit, EmployeeState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) {
          showMessage(context, message: state.message, error: state.error);
          if (state.message != null) Navigator.of(context).pop();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEdit)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'البريد الإلكتروني: ${widget.employee!.email}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isEdit) const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: appFieldDecoration(
                    context,
                    label: 'الاسم',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: appFieldDecoration(
                    context,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: appFieldDecoration(
                      context,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'بريد إلكتروني غير صالح'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: appFieldDecoration(
                      context,
                      label: 'كلمة مرور مؤقتة',
                      icon: Icons.lock_outline,
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'كلمة المرور 6 أحرف على الأقل'
                        : null,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _jobController,
                  decoration: appFieldDecoration(
                    context,
                    label: 'الوظيفة / المسمى الوظيفي',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<DepartmentCubit, DepartmentState>(
                  builder: (context, deptState) {
                    final depts = deptState.departments;
                    final value = _departmentId ??
                        deptState.departments
                            .where((d) => d.name == _departmentName)
                            .map((d) => d.id)
                            .firstOrNull;
                    return DropdownButtonFormField<String>(
                      initialValue: value,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'القسم',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('اختر القسم'),
                      items: [
                        for (final d in depts)
                          DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ],
                      onChanged: (v) => setState(() {
                        _departmentId = v;
                        final dept =
                            depts.where((d) => d.id == v).firstOrNull;
                        _departmentName = dept?.name ?? '';
                      }),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (roles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('لا توجد أدوار متاحة بعد.'),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _roleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final r in roles)
                        DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ],
                    onChanged: (v) => setState(() => _roleId = v),
                  ),
                const SizedBox(height: 20),
                BlocBuilder<EmployeeCubit, EmployeeState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: _isEdit ? 'حفظ التعديلات' : 'إنشاء الحساب',
                      loading: state.saving,
                      onPressed: () => _save(context),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = ctx.read<EmployeeCubit>();
    final roles = cubit.state.roles;
    final role = roles.where((r) => r.id == _roleId).firstOrNull;
    if (role == null) {
      showMessage(ctx, error: 'اختر دورًا للموظف');
      return;
    }
    final deptId = _departmentId ?? '';
    final deptName = _departmentName ?? '';

    if (!_isEdit) {
      await cubit.addEmployee(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: role,
        departmentId: deptId,
        department: deptName,
        jobTitle: _jobController.text,
      );
    } else {
      final employee = widget.employee!;
      await cubit.updateEmployee(
        employee.uid,
        name: _nameController.text,
        phone: _phoneController.text,
        jobTitle: _jobController.text,
        departmentId: deptId,
        department: deptName,
      );
      if (role.id != employee.roleId) {
        await cubit.changeRole(employee.uid, role, _nameController.text);
      }
    }
  }
}