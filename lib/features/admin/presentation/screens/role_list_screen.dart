import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/role.dart';
import '../cubits/role_cubit.dart';
import '../widgets/admin_ui.dart';
import 'role_form_screen.dart';

class RoleListScreen extends StatelessWidget {
  const RoleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoleCubit(),
      child: BlocListener<RoleCubit, RoleState>(
      listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
      listener: (context, state) =>
          showMessage(context, message: state.message, error: state.error),
      child: Scaffold(
        appBar: AppBar(title: const Text('الأدوار والصلاحيات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة دور'),
        ),
        body: BlocBuilder<RoleCubit, RoleState>(
          builder: (context, state) {
            switch (state.status) {
              case RoleStatus.initial:
              case RoleStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case RoleStatus.error:
                return ErrorView(message: state.error);
              case RoleStatus.empty:
                return const EmptyView(
                  icon: Icons.admin_panel_settings_outlined,
                  message: 'لا توجد أدوار — أضف أول دور',
                  actionLabel: 'إضافة دور',
                );
              case RoleStatus.loaded:
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: state.roles.length,
                  itemBuilder: (context, index) {
                    final role = state.roles[index];
                    return _RoleTile(
                      role: role,
                      onTap: () => _openForm(context, role),
                      onArchive: () async {
                        final cubit = context.read<RoleCubit>();
                        if (await confirmDialog(
                          context,
                          title: 'أرشفة الدور',
                          message:
                              'لن يظهر الدور للاختيار بعد الآن. الموظفون المرتبطون به يحتفظون بصلاحياتهم الحالية.',
                          confirmLabel: 'أرشفة',
                        )) {
                          cubit.archive(role);
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

  void _openForm(BuildContext context, Role? role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleFormScreen(role: role),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.onTap, required this.onArchive});

  final Role role;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final granted = role.permissions.values.where((v) => v).length;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: role.isSystem
              ? Icon(Icons.shield_outlined, color: scheme.primary)
              : const Icon(Icons.verified_user_outlined),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                role.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (role.isSystem)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'نظامي',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role.description.isNotEmpty)
              Text(
                role.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 3),
            Text(
              '$granted صلاحية مفعلة',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'archive') onArchive();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
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