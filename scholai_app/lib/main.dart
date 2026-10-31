import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholai_app/core/services/auth_service.dart';
import 'package:scholai_app/core/services/encryption_service.dart';
import 'package:scholai_app/core/services/gemini_service.dart';
import 'package:scholai_app/core/services/notification_service.dart';
import 'package:scholai_app/core/theme/app_theme.dart';
import 'package:scholai_app/core/utils/app_logger.dart';
import 'package:scholai_app/core/utils/app_router.dart';
import 'package:scholai_app/features/account/data/account_service.dart';
import 'package:scholai_app/features/habits/data/habit_local_store.dart';
import 'package:scholai_app/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:scholai_app/features/pro/data/pro_request_service.dart';
import 'package:scholai_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local secrets before any Gemini service reads the key.
  // `--dart-define=GEMINI_API_KEY=...` still overrides .env via AppConfig.
  await dotenv.load(fileName: '.env', isOptional: true);

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);


  // Initialize client-side encryption
  try {
    await EncryptionService.instance.initialize();
    AppLogger.info('Zero-Knowledge Encryption initialized.');
  } catch (e, stack) {
    AppLogger.warning('Encryption initialization failed', error: e, stackTrace: stack);
  }

  // Graceful Firebase bootstrap: if config/auth is unavailable,
  // the app boots in offline demo mode without crashing.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AuthService.instance.signInAnonymously();
    await AccountService.instance.ensureProfile();
    firebaseReady = true;
    AppLogger.info('Firebase & Anonymous Auth initialized.');
  } catch (e) {
    AppLogger.info('Running in local demo mode (Firebase pending configuration).');
  }

  if (firebaseReady) {
    await NotificationService.instance.initialize();
  }

  final prefs = await SharedPreferences.getInstance();
  final resume = prefs.getString('last_place');
  AppRouter.initialLocation = prefs.getBool('onboarding_done') == true
      ? (resume != null && AppRouter.resumePlaces.contains(resume) ? resume : '/home')
      : '/onboarding';

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
        RepositoryProvider(create: (_) => HabitLocalStore.instance),
        RepositoryProvider(create: (_) => ProRequestService.instance),
      ],
      child: BlocProvider(
        create: (context) => HabitCubit(
          store: context.read<HabitLocalStore>(),
          gemini: context.read<GeminiService>(),
        )..load(),
        child: MaterialApp.router(
          title: 'ScholAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
