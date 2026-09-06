import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
        ),
      ],
    );
  }
}

class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.isRequired = true,
    this.decoration,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool isRequired;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      hint: Text(hint),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) return 'اختر $label';
        return null;
      },
      onChanged: onChanged,
    );
  }
}

class YesNoField extends StatelessWidget {
  const YesNoField({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: true, label: Text('نعم'), icon: Icon(Icons.check)),
            ButtonSegment(value: false, label: Text('لا'), icon: Icon(Icons.close)),
          ],
          selected: {?value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}