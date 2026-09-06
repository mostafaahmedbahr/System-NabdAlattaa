import 'package:flutter/material.dart';

import '../../data/models/reference_config.dart';

/// يحوّل اسم أيقونة (مخزّن في Firestore) إلى IconData.
IconData adminIcon(String name) {
  const map = <String, IconData>{
    'handshake': Icons.handshake_outlined,
    'volunteer': Icons.volunteer_activism_outlined,
    'family': Icons.family_restroom,
    'money': Icons.payments_outlined,
    'warehouse': Icons.warehouse_outlined,
    'swap': Icons.swap_horiz_outlined,
    'straighten': Icons.straighten,
    'status': Icons.assignment_turned_in_outlined,
    'priority': Icons.flag_outlined,
    'block': Icons.block,
    'category': Icons.category_outlined,
    'medical': Icons.medical_services_outlined,
    'clothes': Icons.checkroom,
    'food': Icons.lunch_dining_outlined,
    'water': Icons.water_drop_outlined,
    'education': Icons.school_outlined,
    'home': Icons.home_outlined,
    'favorite': Icons.favorite_outline,
    'report': Icons.description_outlined,
    'settings': Icons.settings_outlined,
  };
  return map[name] ?? Icons.category_outlined;
}

/// يحوّل سلسلة لون (hex) إلى [Color].
Color adminColor(String hex, {Color fallback = const Color(0xFF00695C)}) {
  var value = hex.replaceAll('#', '').trim();
  if (value.isEmpty) return fallback;
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

/// يجب ظهور رسائل نجاح/خطأ على كل الشاشات.
void showMessage(BuildContext context, {String? message, String? error}) {
  if (message != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  } else if (error != null && error.isNotEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('حدث خطأ: $error'),
        backgroundColor: Colors.red.shade700,
      ));
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.withValues(alpha: 0.9), c.withValues(alpha: 0.6)],
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حقل إدخال بستايل موحّد لأجزاء الإدارة.
InputDecoration appFieldDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
    prefixIcon: icon != null ? Icon(icon) : null,
  );
}

/// زر أساسي موحّد مع قدرة عرض حالة التحميل.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(label),
    );
  }
}

/// أيقونات جاهزة للاختيار في النماذج، وألوان جاهزة.
const kIconNames = kAdminIconNames;

const kColorChoices = [
  '#00695C',
  '#00897B',
  '#3949AB',
  '#5E35B1',
  '#D84315',
  '#E53935',
  '#F9A825',
  '#6D4C41',
  '#0288D1',
  '#2E7D32',
  '#AD1457',
  '#455A64',
];