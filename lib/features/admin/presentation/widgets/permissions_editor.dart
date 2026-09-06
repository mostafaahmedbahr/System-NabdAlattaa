import 'package:flutter/material.dart';

import '../../../../core/security/permission_registry.dart';

/// محرر مصفوفة صلاحيات الدور (منح فقط).
/// يُرجع خريطة الصلاحيات المفعلة: `{ 'families.delete': true, ... }`.
class RolePermissionsEditor extends StatefulWidget {
  const RolePermissionsEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final Map<String, bool> initial;
  final ValueChanged<Map<String, bool>> onChanged;

  @override
  State<RolePermissionsEditor> createState() => _RolePermissionsEditorState();
}

class _RolePermissionsEditorState extends State<RolePermissionsEditor> {
  late Map<String, bool> _granted;

  @override
  void initState() {
    super.initState();
    _granted = Map.of(widget.initial);
  }

  void _toggle(String key, bool value) {
    setState(() {
      if (value) {
        _granted[key] = true;
      } else {
        _granted.remove(key);
      }
      widget.onChanged(Map.of(_granted));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final module in PermissionRegistry.allModules)
          _ModuleSection(
            module: module,
            granted: _granted,
            onToggle: _toggle,
          ),
      ],
    );
  }
}

/// محرر التجاوزات الفردية للموظف (ثلاثية الحالة):
/// مُورَّث (null) / ممنوح (true) / محظور (false).
/// يُرجع خريطة التجاوزات: `{ 'reports.view': true, 'families.delete': false }`.
class OverridePermissionsEditor extends StatefulWidget {
  const OverridePermissionsEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final Map<String, bool> initial;
  final ValueChanged<Map<String, bool>> onChanged;

  @override
  State<OverridePermissionsEditor> createState() =>
      _OverridePermissionsEditorState();
}

class _OverridePermissionsEditorState extends State<OverridePermissionsEditor> {
  late final Map<String, bool> _overrides = Map.of(widget.initial);

  void _set(String key, bool? value) {
    setState(() {
      if (value == null) {
        _overrides.remove(key);
      } else {
        _overrides[key] = value;
      }
      widget.onChanged(Map.of(_overrides));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final module in PermissionRegistry.allModules)
          _OverrideModuleSection(
            module: module,
            overrides: _overrides,
            onToggle: _set,
          ),
      ],
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.module,
    required this.granted,
    required this.onToggle,
  });

  final PermissionModule module;
  final Map<String, bool> granted;
  final void Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                module.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            for (final action in module.actions)
              CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(action.label),
                value: granted[module.perm(action.key)] ?? false,
                onChanged: (v) => onToggle(module.perm(action.key), v ?? false),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverrideModuleSection extends StatelessWidget {
  const _OverrideModuleSection({
    required this.module,
    required this.overrides,
    required this.onToggle,
  });

  final PermissionModule module;
  final Map<String, bool> overrides;
  final void Function(String key, bool? value) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                module.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            for (final action in module.actions)
              ListTile(
                dense: true,
                leading: SegmentedButton<bool?>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('منح')),
                    ButtonSegment(value: null, label: Text('مورّث')),
                    ButtonSegment(value: false, label: Text('منع')),
                  ],
                  selected: {overrides[module.perm(action.key)]},
                  onSelectionChanged: (s) => onToggle(module.perm(action.key), s.first),
                ),
                title: Text(action.label),
              ),
          ],
        ),
      ),
    );
  }
}