import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Init Firebase
  await Firebase.initializeApp();

  // Sign in anonymously on first launch
  await AuthService.instance.signInAnonymously();

  runApp(const ScholAIApp());
}

class ScholAIApp extends StatelessWidget {
  const ScholAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthService.instance),
        RepositoryProvider(create: (_) => GeminiService.instance),
      ],
      child: MaterialApp.router(
        title: 'ScholAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark, // Dark by default — students use at night
        routerConfig: AppRouter.router,
      ),
    );
  }
}
