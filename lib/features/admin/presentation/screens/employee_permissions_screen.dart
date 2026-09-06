import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/user_profile.dart';
import '../cubits/employee_cubit.dart';
import '../widgets/admin_ui.dart';
import '../widgets/permissions_editor.dart';

class EmployeePermissionsScreen extends StatefulWidget {
  const EmployeePermissionsScreen({super.key, required this.employee});

  final UserProfile employee;

  @override
  State<EmployeePermissionsScreen> createState() =>
      _EmployeePermissionsScreenState();
}

class _EmployeePermissionsScreenState extends State<EmployeePermissionsScreen> {
  late Map<String, bool> _overrides = Map.of(widget.employee.permsOverrides);

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => EmployeeCubit(),
      child: Scaffold(
      appBar: AppBar(title: Text('صلاحيات ${employee.name}')),
      body: BlocListener<EmployeeCubit, EmployeeState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) {
          showMessage(context, message: state.message, error: state.error);
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _badge('الدور: ${employee.roleName}', scheme.primary),
                  _badge('${_overrides.length} تجاوز', Colors.grey.shade700),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'اضبط التجاوزات الفردية: "منح" تزيد صلاحية، "منع" تزيلها، "مورّث" تعود لدور الموظف.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  OverridePermissionsEditor(
                    initial: _overrides,
                    onChanged: (v) => _overrides = v,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BlocBuilder<EmployeeCubit, EmployeeState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: 'حفظ الصلاحيات',
                      loading: state.saving,
                      onPressed: () {
                        context.read<EmployeeCubit>().changePermissions(
                              employee.uid,
                              _overrides,
                              employee.name,
                            );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}