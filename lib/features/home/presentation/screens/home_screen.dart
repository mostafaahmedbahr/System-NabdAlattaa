import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/models/user_profile.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_state.dart';
import '../../../admin/presentation/screens/admin_home_screen.dart';
import '../../../../core/security/app_permissions.dart';
import '../../../family_cases/presentation/screens/case_list_screen.dart';
import '../../../programs/presentation/screens/programs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد فعلاً تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      context.read<AuthCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.select<AuthCubit, User?>((c) => c.state.user);
    final profile =
        context.select<AuthCubit, UserProfile?>((c) => c.state.profile);
    final perms = context.select<AuthCubit, AppPermissions?>(
          (c) => c.state.permissions,
        ) ??
        AppPermissions.empty;
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) =>
          c.status == AuthStatus.authenticated &&
          (c.errorMessage?.isNotEmpty ?? false),
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image(
                  image: AssetImage('assets/images/logo.jpg'),
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'نبض العطاء',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _confirmSignOut(context),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GreetingCard(user: user, profile: profile),
                const SizedBox(height: 24),
                Text(
                  'الأقسام',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر القسم للبدء في إدارة بيانات الأسر',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: _gridColumns(context),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _buildSectionCard(
                      context,
                      icon: Icons.family_restroom,
                      title: 'استقبال الأسر',
                      subtitle: 'تسجيل الحالات الجديدة وبيانات الأسر والقوائم',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CaseListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSectionCard(
                      context,
                      icon: Icons.handshake_outlined,
                      title: 'قسم البرامج',
                      subtitle: 'دراسة الاحتياج وتحديد البرنامج المناسب',
                      color: Colors.deepOrange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProgramsScreen(),
                          ),
                        );
                      },
                    ),
                    if (perms.hasAnyModuleView)
                      _buildSectionCard(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'نظام الإدارة',
                        subtitle: 'الموظفون والصلاحيات والأقسام والإعدادات',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminHomeScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.9),
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'فتح',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({this.user, this.profile});

  final User? user;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prof = profile;
    final name = prof?.name ?? user?.displayName ?? 'موظف';
    final initial = name.isNotEmpty ? name[0] : 'م';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (prof != null)
                      _InfoChip(
                        icon: Icons.badge_outlined,
                        text: prof.department,
                      )
                    else
                      _InfoChip(
                        icon: Icons.badge_outlined,
                        text: user?.email ?? 'موظف',
                      ),
                    if (prof != null)
                      _InfoChip(
                        icon: Icons.phone_outlined,
                        text: prof.phone,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}