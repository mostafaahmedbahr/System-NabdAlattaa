import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/app_permissions.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/models/reference_config.dart';
import '../widgets/admin_ui.dart';
import 'reference_list_screen.dart';

class ReferenceHubScreen extends StatelessWidget {
  const ReferenceHubScreen({super.key});

  AppPermissions _perms(BuildContext context) {
    return context.select<AuthCubit, AppPermissions?>(
          (c) => c.state.permissions,
        ) ??
        AppPermissions.empty;
  }

  bool _visible(AppPermissions perms, ReferenceConfig config) {
    return switch (config.kind) {
      ReferenceKind.aidTypes => perms.has('aids', 'view'),
      ReferenceKind.donationTypes => perms.has('donations', 'view'),
      ReferenceKind.expenseCategories => perms.has('expenses', 'view'),
      ReferenceKind.inventoryCategories ||
      ReferenceKind.stockReasons ||
      ReferenceKind.units =>
        perms.has('inventory', 'view'),
      ReferenceKind.familyStatuses ||
      ReferenceKind.priorities ||
      ReferenceKind.rejectionReasons =>
        perms.has('families', 'view'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final perms = _perms(context);
    final visible =
        ReferenceConfig.configs.where((c) => _visible(perms, c)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('القوائم المرجعية')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final config in visible)
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: adminColor(config.color).withValues(alpha: 0.15),
                  child: Icon(
                    adminIcon(config.icon),
                    color: adminColor(config.color),
                  ),
                ),
                title: Text(
                  config.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(config.description.isEmpty
                    ? 'إدارة ${config.singularLabel}'
                    : config.description),
                trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReferenceListScreen(kind: config.kind),
                    ),
                  );
                },
              ),
            ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('لا توجد قوائم متاحة لصلاحياتك')),
            ),
        ],
      ),
    );
  }
}