import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/system_settings.dart';
import '../cubits/settings_cubit.dart';
import '../widgets/admin_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(),
      child: Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (p, c) => c.message != null || c.error.isNotEmpty,
        listener: (context, state) =>
            showMessage(context, message: state.message, error: state.error),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'البيانات العامة'),
                  Tab(text: 'إعدادات النظام'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _SocietyTab(),
                    _SystemTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _SocietyTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state.status == SettingsStatus.loading ||
            state.status == SettingsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SocietyForm(settings: state.settings, saving: state.saving);
      },
    );
  }
}

class _SystemTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state.status == SettingsStatus.loading ||
            state.status == SettingsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SystemForm(settings: state.settings, saving: state.saving);
      },
    );
  }
}

class _SocietyForm extends StatefulWidget {
  const _SocietyForm({required this.settings, required this.saving});

  final SystemSettings settings;
  final bool saving;

  @override
  State<_SocietyForm> createState() => _SocietyFormState();
}

class _SocietyFormState extends State<_SocietyForm> {
  late final _controllers = {
    'societyName': TextEditingController(text: widget.settings.societyName),
    'phone': TextEditingController(text: widget.settings.phone),
    'email': TextEditingController(text: widget.settings.email),
    'address': TextEditingController(text: widget.settings.address),
    'governorate': TextEditingController(text: widget.settings.governorate),
    'center': TextEditingController(text: widget.settings.center),
    'website': TextEditingController(text: widget.settings.website),
    'logoUrl': TextEditingController(text: widget.settings.logoUrl),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field('societyName', 'اسم الجمعية'),
          const SizedBox(height: 12),
          _field('phone', 'الهاتف'),
          const SizedBox(height: 12),
          _field('email', 'البريد الإلكتروني'),
          const SizedBox(height: 12),
          _field('governorate', 'المحافظة'),
          const SizedBox(height: 12),
          _field('center', 'المركز/الحي'),
          const SizedBox(height: 12),
          _field('address', 'العنوان'),
          const SizedBox(height: 12),
          _field('website', 'الموقع الإلكتروني'),
          const SizedBox(height: 12),
          _field('logoUrl', 'رابط الشعار'),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'حفظ البيانات العامة',
            loading: widget.saving,
            onPressed: () {
              final fields = <String, dynamic>{
                for (final e in _controllers.entries) e.key: e.value.text.trim(),
              };
              context.read<SettingsCubit>().updateSociety(fields);
            },
          ),
        ],
      ),
    );
  }

  Widget _field(String key, String label) {
    return TextField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SystemForm extends StatefulWidget {
  const _SystemForm({required this.settings, required this.saving});

  final SystemSettings settings;
  final bool saving;

  @override
  State<_SystemForm> createState() => _SystemFormState();
}

class _SystemFormState extends State<_SystemForm> {
  late final _currencyController =
      TextEditingController(text: widget.settings.currency);
  late final _dateFormatController =
      TextEditingController(text: widget.settings.dateFormat);
  late bool _requireAidApproval = widget.settings.requireAidApproval;
  late bool _requireExpenseApproval = widget.settings.requireExpenseApproval;
  late bool _allowDelete = widget.settings.allowDelete;
  late bool _allowEditAfterApproval = widget.settings.allowEditAfterApproval;
  late bool _enableAuditLog = widget.settings.enableAuditLog;
  late String _language = widget.settings.language;

  @override
  void dispose() {
    _currencyController.dispose();
    _dateFormatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final toggles = <(String, String, bool)>[
      ('requireAidApproval', 'مطالبة بالموافقة على المساعدات', _requireAidApproval),
      ('requireExpenseApproval', 'مطالبة بالموافقة على المصروفات', _requireExpenseApproval),
      ('allowDelete', 'السماح بالحذف النهائي', _allowDelete),
      ('allowEditAfterApproval', 'السماح بالتعديل بعد الاعتماد', _allowEditAfterApproval),
      ('enableAuditLog', 'تفعيل سجل العمليات', _enableAuditLog),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(
              labelText: 'اللغة',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'ar'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'العملة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dateFormatController,
            decoration: const InputDecoration(
              labelText: 'صيغة التاريخ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (final (key, label, value) in toggles)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: const TextStyle(fontSize: 13.5)),
                    value: value,
                    onChanged: (v) => setState(() {
                      switch (key) {
                        case 'requireAidApproval':
                          _requireAidApproval = v;
                          break;
                        case 'requireExpenseApproval':
                          _requireExpenseApproval = v;
                          break;
                        case 'allowDelete':
                          _allowDelete = v;
                          break;
                        case 'allowEditAfterApproval':
                          _allowEditAfterApproval = v;
                          break;
                        case 'enableAuditLog':
                          _enableAuditLog = v;
                          break;
                      }
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'حفظ إعدادات النظام',
            loading: widget.saving,
            onPressed: () {
              context.read<SettingsCubit>().updateSystem({
                'language': _language,
                'currency': _currencyController.text.trim(),
                'dateFormat': _dateFormatController.text.trim(),
                'requireAidApproval': _requireAidApproval,
                'requireExpenseApproval': _requireExpenseApproval,
                'allowDelete': _allowDelete,
                'allowEditAfterApproval': _allowEditAfterApproval,
                'enableAuditLog': _enableAuditLog,
              });
            },
          ),
        ],
      ),
    );
  }
}