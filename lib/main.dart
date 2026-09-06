import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/repositories/bootstrap_repository.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/family_cases/presentation/cubits/family_case_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupDependencies();
  try {
    await BootstrapRepository.instance.ensureDefaults();
  } catch (_) {
    // لا نُوقف تشغيل التطبيق لو تعذّر إنشاء البيانات الافتراضية
    // (مثلاً: غياب الاتصال أو قواعد Firestore).
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => FamilyCaseCubit()),
      ],
      child: MaterialApp(
        title: 'نبض العطاء',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        locale: const Locale('ar'),
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}