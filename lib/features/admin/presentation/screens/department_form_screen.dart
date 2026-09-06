import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/department.dart';
import '../cubits/department_cubit.dart';
import '../widgets/admin_ui.dart';

class DepartmentFormScreen extends StatefulWidget {
  const DepartmentFormScreen({super.key, this.department});

  final Department? department;

  @override
  State<DepartmentFormScreen> createState() => _DepartmentFormScreenState();
}

class _DepartmentFormScreenState extends State<DepartmentFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.department?.name ?? '');
  late final TextEditingController _descController =
      TextEditingController(text: widget.department?.description ?? '');
  late String _icon = widget.department?.icon ?? 'category';
  late String _color = widget.department?.color ?? '#00695C';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.department != null;
    return BlocProvider(
      create: (_) => DepartmentCubit(),
      child: Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'تعديل قسم' : 'إضافة قسم')),
      body: BlocListener<DepartmentCubit, DepartmentState>(
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم القسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'اسم القسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _icon,
                  decoration: const InputDecoration(
                    labelText: 'الأيقونة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final name in kIconNames)
                      DropdownMenuItem(
                        value: name,
                        child: Row(
                          children: [
                            Icon(adminIcon(name), size: 18),
                            const SizedBox(width: 8),
                            Text(name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _icon = v ?? _icon),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'اللون',
                    border: OutlineInputBorder(),
                  ),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final c in kColorChoices)
                        InkWell(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: adminColor(c),
                              shape: BoxShape.circle,
                              border: c == _color
                                  ? Border.all(color: Colors.black, width: 2.5)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                BlocBuilder<DepartmentCubit, DepartmentState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: 'حفظ',
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
      ),
    );
  }

  Future<void> _save(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = ctx.read<DepartmentCubit>();
    final dept = widget.department;
    if (dept == null) {
      await cubit.addDepartment(
        name: _nameController.text,
        description: _descController.text,
        icon: _icon,
        color: _color,
      );
    } else {
      await cubit.updateDepartment(
        dept,
        name: _nameController.text,
        description: _descController.text,
        icon: _icon,
        color: _color,
      );
    }
  }
}