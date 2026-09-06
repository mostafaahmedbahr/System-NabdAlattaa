import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/security/app_permissions.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/admin_dashboard_cubit.dart';
import '../widgets/admin_ui.dart';
import 'approval_inbox_screen.dart';
import 'audit_log_screen.dart';
import 'department_list_screen.dart';
import 'employee_list_screen.dart';
import 'notification_screen.dart';
import 'reference_hub_screen.dart';
import 'role_list_screen.dart';
import 'settings_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AdminDashboardCubit()..refresh(),
        ),
      ],
      child: const _AdminHomeView(),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  const _AdminHomeView();

  AppPermissions _perms(BuildContext context) {
    return context.select<AuthCubit, AppPermissions?>(
          (c) => c.state.permissions,
        ) ??
        AppPermissions.empty;
  }

  @override
  Widget build(BuildContext context) {
    final perms = _perms(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminDashboardCubit>().refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _DashboardSection(),
            const SizedBox(height: 20),
            Text(
              'الإدارة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'إدارة الموظفين والصلاحيات والبيانات المرجعية',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: _cols(context),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                if (perms.has('employees', 'view'))
                  _navCard(
                    context,
                    icon: Icons.group_outlined,
                    title: 'الموظفون',
                    subtitle: 'إضافة وتعديل وإدارة الحسابات',
                    color: Colors.teal,
                    onTap: () => _push(context, const EmployeeListScreen()),
                  ),
                if (perms.has('employees', 'view'))
                  _navCard(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'الأدوار والصلاحيات',
                    subtitle: 'إنشاء أدوار ومصفوفات الصلاحيات',
                    color: Colors.indigo,
                    onTap: () => _push(context, const RoleListScreen()),
                  ),
                if (perms.has('departments', 'view'))
                  _navCard(
                    context,
                    icon: Icons.account_balance_outlined,
                    title: 'الأقسام',
                    subtitle: 'الأقسام وموظفيها',
                    color: Colors.deepOrange,
                    onTap: () => _push(context, const DepartmentListScreen()),
                  ),
                if (_hasRefView(perms))
                  _navCard(
                    context,
                    icon: Icons.list_alt_outlined,
                    title: 'القوائم المرجعية',
                    subtitle: 'المساعدات والوحدات والحالات والأولويات',
                    color: Colors.brown,
                    onTap: () => _push(context, const ReferenceHubScreen()),
                  ),
                if (perms.has('approvals', 'view'))
                  _navCard(
                    context,
                    icon: Icons.fact_check_outlined,
                    title: 'الموافقات',
                    subtitle: 'طلبات بانتظار الاعتماد أو الرفض',
                    color: Colors.amber.shade800,
                    onTap: () => _push(context, const ApprovalInboxScreen()),
                  ),
                if (perms.has('notifications', 'view'))
                  _navCard(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات',
                    subtitle: 'إرسال إشعار للموظفين',
                    color: Colors.pink.shade700,
                    onTap: () => _push(context, const NotificationScreen()),
                  ),
                if (perms.has('settings', 'view'))
                  _navCard(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    subtitle: 'بيانات الجمعية وإعدادات النظام',
                    color: Colors.blueGrey,
                    onTap: () => _push(context, const SettingsScreen()),
                  ),
                if (perms.has('audit', 'view'))
                  _navCard(
                    context,
                    icon: Icons.history_rounded,
                    title: 'سجل العمليات',
                    subtitle: 'آخر العمليات الحساسة',
                    color: Colors.red.shade700,
                    onTap: () => _push(context, const AuditLogScreen()),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _hasRefView(AppPermissions perms) {
    return perms.hasAny([
      'aids.view',
      'donations.view',
      'expenses.view',
      'inventory.view',
      'families.view',
    ]);
  }

  int _cols(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _navCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state.status == DashboardStatus.loading &&
            state.stats.recentActivities.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state.status == DashboardStatus.error) {
          return ErrorView(
            message: 'تعذر تحميل الإحصائيات',
            onRetry: () => context.read<AdminDashboardCubit>().refresh(),
          );
        }
        final stats = state.stats;
        final scheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                StatCard(
                  icon: Icons.group_outlined,
                  value: '${stats.activeEmployees} / ${stats.employees}',
                  label: 'موظف نشط',
                  color: Colors.teal,
                ),
                StatCard(
                  icon: Icons.account_balance_outlined,
                  value: '${stats.departments}',
                  label: 'الأقسام',
                  color: Colors.indigo,
                ),
                StatCard(
                  icon: Icons.family_restroom,
                  value: '${stats.families}',
                  label: 'الأسر المسجلة',
                  color: Colors.deepOrange,
                ),
                StatCard(
                  icon: Icons.fact_check_outlined,
                  value: '${stats.pendingApprovals}',
                  label: 'بانتظار الموافقة',
                  color: Colors.amber.shade800,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dashValue(stats.activeEmployees, 'موظف نشط'),
                  _dashValue(stats.families, 'الأسرة'),
                  _dashValue(stats.pendingApprovals, 'موافقة'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'آخر العمليات',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (stats.recentActivities.isEmpty)
              Text(
                'لا توجد عمليات مسجلة بعد.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              for (final entry in stats.recentActivities.take(6))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: scheme.primary,
                  ),
                  title: Text(entry.message.isEmpty
                      ? '${entry.userName} — ${entry.action}'
                      : entry.message),
                  subtitle: Text(
                    entry.timestamp == null
                        ? entry.userName
                        : '${entry.userName} • ${DateFormat('yyyy/MM/dd HH:mm').format(entry.timestamp!)}',
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _dashValue(int value, String label) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}