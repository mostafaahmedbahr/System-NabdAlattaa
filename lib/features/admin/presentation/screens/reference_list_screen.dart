import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/reference_config.dart';
import '../../data/models/reference_item.dart';
import '../cubits/reference_cubit.dart';
import '../widgets/admin_ui.dart';
import 'reference_form_screen.dart';

class ReferenceListScreen extends StatelessWidget {
  const ReferenceListScreen({super.key, required this.kind});

  final ReferenceKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReferenceCubit(kind),
      child: const _ReferenceListView(),
    );
  }
}

class _ReferenceListView extends StatelessWidget {
  const _ReferenceListView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReferenceCubit>();
    final config = cubit.config;
    return BlocListener<ReferenceCubit, ReferenceState>(
      listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
      listener: (context, state) =>
          showMessage(context, message: state.message, error: state.error),
      child: Scaffold(
        appBar: AppBar(
          title: Text(config.title),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: Text('إضافة ${config.singularLabel}'),
        ),
        body: BlocBuilder<ReferenceCubit, ReferenceState>(
          builder: (context, state) {
            switch (state.status) {
              case ReferenceStatus.initial:
              case ReferenceStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ReferenceStatus.error:
                return ErrorView(message: state.error);
              case ReferenceStatus.empty:
                return EmptyView(
                  icon: adminIcon(config.icon),
                  message: 'لا يوجد عناصر — أضف أول ${config.singularLabel}',
                  actionLabel: 'إضافة',
                  onAction: () => _openForm(context, null),
                );
              case ReferenceStatus.loaded:
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _ItemTile(
                      config: config,
                      item: item,
                      onEdit: () => _openForm(context, item),
                      onToggle: () => cubit.toggleActive(item, !item.isActive),
                      onArchive: () async {
                        if (await confirmDialog(
                          context,
                          title: 'أرشفة',
                          message:
                              'هل تريد أرشفة هذا العنصر؟ لن يظهر في القوائم بعد الآن.',
                        )) {
                          cubit.archive(item);
                        }
                      },
                    );
                  },
                );
            }
          },
        ),
      ),
    );
  }

  void _openForm(BuildContext context, ReferenceItem? item) {
    final kind = context.read<ReferenceCubit>().kind;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReferenceFormScreen(kind: kind, item: item),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.config,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onArchive,
  });

  final ReferenceConfig config;
  final ReferenceItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = adminColor(item.color.isEmpty ? config.color : item.color);
    final chips = <String>[
      for (final field in config.fields)
        if (!item.extraBool('needsApproval') &&
            field.type == ReferenceFieldType.switchField)
          ''
        else if (item.extraValue(field.key) != null &&
            item.extraValue(field.key).toString().isNotEmpty)
          _format(field, item),
    ].where((c) => c.isNotEmpty).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: baseColor.withValues(alpha: 0.15),
          child: Icon(adminIcon(item.icon), color: baseColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (item.extraBool('needsApproval'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'يحتاج اعتماد',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade800,
                  ),
                ),
              ),
            if (!item.isActive)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.pause_circle_outline,
                    size: 18, color: Colors.grey),
              ),
          ],
        ),
        subtitle: item.description.isEmpty
            ? (chips.isEmpty ? null : Text(chips.join(' • ')))
            : Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'toggle':
                onToggle();
                break;
              case 'archive':
                onArchive();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('تعديل'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(item.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                title: Text(item.isActive ? 'تعطيل' : 'تفعيل'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
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

  String _format(ReferenceField field, ReferenceItem item) {
    final value = item.extraValue(field.key);
    if (field.type == ReferenceFieldType.switchField) {
      return value == true ? 'يحتاج اعتماد' : '';
    }
    return '${field.label}: $value';
  }
}