import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/notification_cubit.dart';
import '../widgets/admin_ui.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit(),
      child: Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: BlocListener<NotificationCubit, NotificationState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) =>
            showMessage(context, message: state.message, error: state.error),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _ComposerCard(),
            const SizedBox(height: 16),
            const Text(
              'الإشعارات المرسلة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                switch (state.status) {
                  case NotificationStatus.initial:
                  case NotificationStatus.loading:
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  case NotificationStatus.error:
                    return const ErrorView(message: 'تعذر تحميل الإشعارات');
                  case NotificationStatus.empty:
                    return const EmptyView(
                      icon: Icons.notifications_off_outlined,
                      message: 'لا توجد إشعارات مرسلة بعد',
                    );
                  case NotificationStatus.loaded:
                    return Column(
                      children: [
                        for (final n in state.notifications)
                          _NotificationTile(notification: n),
                      ],
                    );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(context),
        icon: const Icon(Icons.send_outlined),
        label: const Text('إرسال إشعار'),
      ),
      ),
    );
  }

  void _openComposer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _ComposerScreen()),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تصل الإشعارات إلى الأجهزة عبر خادم إشعارات، وتظهر هنا للأعضاء عند تسجيل الدخول.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final dynamic notification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = notification.title as String;
    final body = notification.body as String;
    final sentByName = notification.sentByName as String;
    final sentAt = notification.sentAt as DateTime?;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.notifications_active_outlined, color: scheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) Text(body, style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(
              sentAt != null
                  ? '$sentByName — ${DateFormat('yyyy/MM/dd HH:mm').format(sentAt)}'
                  : sentByName,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ComposerScreen extends StatefulWidget {
  const _ComposerScreen();

  @override
  State<_ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<_ComposerScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _targetKeyController = TextEditingController();
  String _type = 'general';
  String _target = 'all';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => NotificationCubit(),
      child: Scaffold(
      appBar: AppBar(title: const Text('إرسال إشعار')),
      body: BlocListener<NotificationCubit, NotificationState>(
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
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('عام')),
                    DropdownMenuItem(value: 'system', child: Text('نظام')),
                    DropdownMenuItem(value: 'approval', child: Text('موافقة')),
                    DropdownMenuItem(value: 'alert', child: Text('تنبيه')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'general'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _target,
                  decoration: const InputDecoration(
                    labelText: 'الجمهور المستهدف',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('جميع المستخدمين')),
                    DropdownMenuItem(value: 'role', child: Text('دور محدد')),
                    DropdownMenuItem(value: 'department', child: Text('قسم محدد')),
                    DropdownMenuItem(value: 'user', child: Text('مستخدم محدد')),
                  ],
                  onChanged: (v) => setState(() => _target = v ?? 'all'),
                ),
                if (_target != 'all') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetKeyController,
                    decoration: InputDecoration(
                      labelText: switch (_target) {
                        'role' => 'المعرّف الخاص بالدور',
                        'department' => 'المعرّف الخاص بالقسم',
                        _ => 'المعرّف الخاص بالمستخدم',
                      },
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'النص',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'النص مطلوب' : null,
                ),
                const SizedBox(height: 20),
                BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: 'إرسال',
                      loading: state.saving,
                      onPressed: _send,
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_target != 'all')
                  Text(
                    'يجب أن يكون المعرّف مطابقًا تمامًا لما هو محفوظ في قاعدة البيانات.',
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final actorName = context
            .select<AuthCubit, String?>((c) => c.state.profile?.name) ??
        'مدير';
    final key = _targetKeyController.text.trim();
    await context.read<NotificationCubit>().send(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: _type,
          target: _target,
          targetId: _target == 'all' ? '' : key,
          actorName: actorName,
        );
  }
}