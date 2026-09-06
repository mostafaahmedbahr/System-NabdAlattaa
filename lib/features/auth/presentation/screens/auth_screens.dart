import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/form_widgets.dart';
import '../../data/models/user_profile.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

const _kLogoPath = 'assets/images/logo.jpg';

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.surface,
            scheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.subtitle, this.big = true});

  final String subtitle;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = big ? 92.0 : 78.0;
    return Column(
      children: [
        Container(
          width: size + 18,
          height: size + 18,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              _kLogoPath,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'نبض العطاء',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _authDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
  );
}

Widget _authPrimaryButton({
  required BuildContext context,
  required bool loading,
  required VoidCallback onPressed,
  required String label,
}) {
  return FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    child: loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(label),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _listenState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      widget.onSuccess?.call();
    } else if (state.status == AuthStatus.error &&
        (state.errorMessage?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _listenState,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final loading = state.status == AuthStatus.authenticating;
          return Scaffold(
            body: _AuthBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandHeader(subtitle: 'تسجيل الدخول للموظفين'),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: _authDecoration(
                                context,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'أدخل البريد الإلكتروني'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: _authDecoration(
                                context,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'أدخل كلمة المرور'
                                  : null,
                            ),
                            const SizedBox(height: 26),
                            _authPrimaryButton(
                              context: context,
                              loading: loading,
                              label: 'دخول',
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;
                                context.read<AuthCubit>().signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                              },
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SignupScreen(
                                      onSuccess: () => Navigator.of(context)
                                          .popUntil((r) => r.isFirst),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('إنشاء حساب جديد'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _department;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _listenState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      widget.onSuccess?.call();
    } else if (state.status == AuthStatus.error &&
        (state.errorMessage?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _listenState,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final loading = state.status == AuthStatus.authenticating;
          return Scaffold(
            body: _AuthBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandHeader(
                              subtitle: 'إنشاء حساب جديد للموظفين',
                              big: false,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: _authDecoration(
                                context,
                                label: 'اسم الموظف',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'أدخل اسم الموظف'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.next,
                              decoration: _authDecoration(
                                context,
                                label: 'رقم التلفون',
                                icon: Icons.phone_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'أدخل رقم التلفون';
                                }
                                if (v.trim().length < 9) {
                                  return 'رقم التلفون غير صالح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppDropdownField(
                              label: 'القسم',
                              items: kDepartments,
                              value: _department,
                              hint: 'اختر القسم',
                              onChanged: (v) =>
                                  setState(() => _department = v),
                              decoration: _authDecoration(
                                context,
                                label: 'القسم',
                                icon: Icons.work_outline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.next,
                              decoration: _authDecoration(
                                context,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'أدخل البريد الإلكتروني';
                                }
                                if (!v.contains('@')) {
                                  return 'بريد إلكتروني غير صالح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: _authDecoration(
                                context,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'أدخل كلمة المرور';
                                }
                                if (v.length < 6) {
                                  return 'كلمة المرور لا تقل عن 6 أحرف';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 26),
                            _authPrimaryButton(
                              context: context,
                              loading: loading,
                              label: 'إنشاء الحساب',
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;
                                context.read<AuthCubit>().signUp(
                                      name: _nameController.text,
                                      phone: _phoneController.text,
                                      department: _department!,
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    );
                              },
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => LoginScreen(
                                      onSuccess: () => Navigator.of(context)
                                          .popUntil((r) => r.isFirst),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('لديك حساب بالفعل؟ سجّل دخول'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}