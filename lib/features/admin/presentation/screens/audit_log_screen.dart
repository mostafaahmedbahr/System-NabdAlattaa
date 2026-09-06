import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubits/audit_cubit.dart';
import '../widgets/admin_ui.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditCubit(),
      child: Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      body: BlocBuilder<AuditCubit, AuditState>(
        builder: (context, state) {
          switch (state.status) {
            case AuditStatus.initial:
            case AuditStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case AuditStatus.error:
              return const ErrorView(message: 'تعذر تحميل سجل العمليات');
            case AuditStatus.empty:
              return const EmptyView(
                icon: Icons.history_rounded,
                message: 'لا توجد عمليات مسجلة بعد',
              );
            case AuditStatus.loaded:
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  return _LogTile(entry: entry);
                },
              );
          }
        },
      ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = entry.message as String? ?? '';
    final userName = entry.userName as String;
    final module = entry.module as String;
    final action = entry.action as String;
    final timestamp = entry.timestamp as DateTime?;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.history, color: scheme.primary, size: 20),
        ),
        title: Text(
          message.isEmpty ? '$userName — $action' : message,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                module,
                style: TextStyle(fontSize: 10.5, color: scheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            if (timestamp != null)
              Expanded(
                child: Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(timestamp),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
        isThreeLine: false,
      ),
    );
  }
}