import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/reference_config.dart';
import '../../data/models/reference_item.dart';
import '../cubits/reference_cubit.dart';
import '../widgets/admin_ui.dart';

class ReferenceFormScreen extends StatefulWidget {
  const ReferenceFormScreen({super.key, required this.kind, this.item});

  final ReferenceKind kind;
  final ReferenceItem? item;

  @override
  State<ReferenceFormScreen> createState() => _ReferenceFormScreenState();
}

class _ReferenceFormScreenState extends State<ReferenceFormScreen> {
  late final ReferenceConfig _config = ReferenceConfig.of(widget.kind);
  late final TextEditingController _nameController =
      TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _descController =
      TextEditingController(text: widget.item?.description ?? '');
  late String _icon = widget.item?.icon.isEmpty ?? true
      ? _config.icon
      : widget.item!.icon;
  late String _color = (widget.item?.color.isNotEmpty ?? false)
      ? widget.item!.color
      : _config.color;
  late final Map<String, dynamic> _extra = Map.of(widget.item?.extra ?? {});
  final Map<String, TextEditingController> _textControllers = {};
  late bool _isActive = widget.item?.isActive ?? true;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(ReferenceField field) {
    return _textControllers.putIfAbsent(
      field.key,
      () => TextEditingController(
        text: widget.item?.extraValue(field.key)?.toString() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReferenceCubit(widget.kind),
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null
            ? 'إضافة ${_config.singularLabel}'
            : 'تعديل ${_config.singularLabel}'),
      ),
      body: BlocListener<ReferenceCubit, ReferenceState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) {
          showMessage(context, message: state.message, error: state.error);
          if (state.message != null) {
            Navigator.of(context).pop();
          }
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
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
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
                if (_config.pickIcon) ...[
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
                ],
                if (_config.pickColor) ...[
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
                ],
                for (final field in _config.fields) ...[
                  const SizedBox(height: 12),
                  _buildField(field),
                ],
                if (widget.item != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'نشط',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
                const SizedBox(height: 20),
                BlocBuilder<ReferenceCubit, ReferenceState>(
                  builder: (context, state) {
                    return AppPrimaryButton(
                      label: 'حفظ',
                      loading: state.saving || _saving,
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

  Widget _buildField(ReferenceField field) {
    switch (field.type) {
      case ReferenceFieldType.text:
        return TextFormField(
          controller: _controllerFor(field),
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
        );
      case ReferenceFieldType.number:
        return TextFormField(
          controller: _controllerFor(field),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
        );
      case ReferenceFieldType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: widget.item?.extraValue(field.key)?.toString(),
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (v) => setState(() {
            if (v != null) {
              _extra[field.key] = v;
            }
          }),
        );
      case ReferenceFieldType.switchField:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          value: widget.item?.extraBool(field.key) ?? false,
          onChanged: (v) => setState(() => _extra[field.key] = v),
        );
    }
  }

  Future<void> _save(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final extra = Map<String, dynamic>.of(_extra);
    for (final field in _config.fields) {
      final controller = _textControllers[field.key];
      if (controller == null) continue;
      switch (field.type) {
        case ReferenceFieldType.text:
          if (controller.text.trim().isNotEmpty) {
            extra[field.key] = controller.text.trim();
          }
        case ReferenceFieldType.number:
          final parsed = num.tryParse(controller.text.trim());
          if (parsed != null) {
            extra[field.key] = parsed;
          }
        case ReferenceFieldType.dropdown:
        case ReferenceFieldType.switchField:
          break;
      }
    }

    final cubit = ctx.read<ReferenceCubit>();
    final item = widget.item;
    if (item == null) {
      await cubit.addItem(
        name: _nameController.text,
        description: _descController.text,
        icon: _icon,
        color: _config.pickColor ? _color : _config.color,
        extra: extra,
      );
    } else {
      await cubit.updateItem(
        item,
        name: _nameController.text,
        description: _descController.text,
        icon: _icon,
        color: _config.pickColor ? _color : item.color,
        extra: extra,
      );
    }
    if (mounted) setState(() => _saving = false);
  }
}