import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/permission_registry.dart';
import '../../data/models/role.dart';
import '../cubits/role_cubit.dart';
import '../widgets/admin_ui.dart';
import '../widgets/permissions_editor.dart';

class RoleFormScreen extends StatefulWidget {
  const RoleFormScreen({super.key, this.role});

  final Role? role;

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  late final _nameController =
      TextEditingController(text: widget.role?.name ?? '');
  late final _descController =
      TextEditingController(text: widget.role?.description ?? '');
  late final _idController =
      TextEditingController(text: widget.role?.id ?? '');
  late Map<String, bool> _permissions =
      Map.of(widget.role?.permissions ?? const {});
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.role != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => RoleCubit(),
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'تعديل الدور' : 'إضافة دور')),
      body: BlocListener<RoleCubit, RoleState>(
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
                if (!_isEdit)
                  TextFormField(
                    controller: _idController,
                    enabled: !_isEdit,
                    decoration: const InputDecoration(
                      labelText: 'المعرّف (بالإنجليزية، مثال: manager)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'المعرّف مطلوب'
                        : null,
                  ),
                if (!_isEdit) const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدور',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'اسم الدور مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مصفوفة الصلاحيات (${_permissions.values.where((v) => v).length})',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'التغييرات تُطبَّق تلقائيًا على كل موظفي هذا الدور.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RolePermissionsEditor(
                  initial: widget.role?.permissions ??
                      PermissionRegistry.seedRoles.values.first.permissions,
                  onChanged: (v) => _permissions = v,
                ),
                const SizedBox(height: 20),
                BlocBuilder<RoleCubit, RoleState>(
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
    final cubit = ctx.read<RoleCubit>();
    final role = widget.role;
    if (role == null) {
      await cubit.addRole(
        id: _idController.text,
        name: _nameController.text,
        description: _descController.text,
        permissions: _permissions,
      );
    } else {
      await cubit.updateRole(
        role,
        name: _nameController.text,
        description: _descController.text,
      );
      await cubit.updatePermissions(role, _permissions);
    }
  }
}