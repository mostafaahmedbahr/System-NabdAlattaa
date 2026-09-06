import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/repositories/approval_repository.dart';
import '../cubits/approval_cubit.dart';
import '../widgets/admin_ui.dart';

class ApprovalInboxScreen extends StatelessWidget {
  const ApprovalInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApprovalCubit(),
      child: Scaffold(
      appBar: AppBar(title: const Text('الموافقات')),
      body: BlocListener<ApprovalCubit, ApprovalState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) =>
            showMessage(context, message: state.message, error: state.error),
        child: BlocBuilder<ApprovalCubit, ApprovalState>(
          builder: (context, state) {
            switch (state.status) {
              case ApprovalStatus.initial:
              case ApprovalStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ApprovalStatus.error:
                return ErrorView(message: state.error);
              case ApprovalStatus.empty:
                return const EmptyView(
                  icon: Icons.fact_check_outlined,
                  message: 'لا توجد طلبات بانتظار الموافقة',
                );
              case ApprovalStatus.loaded:
                final actorName = context
                        .select<AuthCubit, String?>(
                          (c) => c.state.profile?.name,
                        ) ??
                    'مدير';
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.requests.length,
                  itemBuilder: (context, index) {
                    final request = state.requests[index];
                    return _ApprovalTile(
                      request: request,
                      saving: state.saving,
                      actorName: actorName,
                      onApprove: () => context
                          .read<ApprovalCubit>()
                          .decide(request, approve: true, actorName: actorName),
                      onReject: () async {
                        final cubit = context.read<ApprovalCubit>();
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (ctx) => _RejectDialog(),
                        );
                        if (reason != null) {
                          cubit.decide(
                                request,
                                approve: false,
                                reason: reason,
                                actorName: actorName,
                              );
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
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.request,
    required this.saving,
    required this.actorName,
    required this.onApprove,
    required this.onReject,
  });

  final PendingApproval request;
  final bool saving;
  final String actorName;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static const _moduleLabels = <String, String>{
    'aids': 'مساعدة',
    'donations': 'تبرع',
    'expenses': 'مصروف',
    'inventory': 'مخزون',
    'families': 'أسرة',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moduleLabel = _moduleLabels[request.module] ?? request.module;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'طلب $moduleLabel رقم ${request.recordId}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'بانتظار',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'قدّمه: ${request.requestedByName}',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            if (request.requestedAt != null)
              Text(
                'بتاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(request.requestedAt!)}',
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            if (request.change.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final e in request.change.entries.take(4))
                    Chip(
                      label: Text('${e.key}: ${e.value}'),
                      labelStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: saving ? null : onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('اعتماد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: saving ? null : onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  String _selected = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('سبب الرفض'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selected.isEmpty ? null : _selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'أو اختر سببًا جاهزًا',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'البيانات غير مكتملة', child: Text('البيانات غير مكتملة')),
              DropdownMenuItem(value: 'المستندات غير متوفرة', child: Text('المستندات غير متوفرة')),
              DropdownMenuItem(value: 'تم تقديم المساعدة مسبقًا', child: Text('تم تقديم المساعدة مسبقًا')),
            ],
            onChanged: (v) => setState(() => _selected = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'اكتب سببًا مخصصًا',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _controller.text.trim().isNotEmpty
                ? _controller.text.trim()
                : _selected;
            Navigator.of(context).pop(reason);
          },
          child: const Text('رفض'),
        ),
      ],
    );
  }
}