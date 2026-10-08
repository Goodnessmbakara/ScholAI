import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/services/encryption_service.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/core/utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize client-side encryption
  try {
    await EncryptionService.instance.initialize();
    AppLogger.info('Zero-Knowledge Encryption initialized.');
  } catch (e, stack) {
    AppLogger.warning('Encryption initialization failed', error: e, stackTrace: stack);
  }

  // Graceful Firebase bootstrap: if google-services.json is not yet provided,
  // the app boots in offline demo mode without crashing.
  try {
    await Firebase.initializeApp();
    await AuthService.instance.signInAnonymously();
    AppLogger.info('Firebase & Anonymous Auth initialized.');
  } catch (e) {
    AppLogger.info('Running in local demo mode (Firebase pending configuration).');
  }

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
        themeMode: ThemeMode.dark, // Midnight warm charcoal dark mode by default
        routerConfig: AppRouter.router,
      ),
    );
  }
}
