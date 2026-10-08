import 'package:go_router/go_router.dart';
import 'package:scholai_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:scholai_app/features/checkin/presentation/screens/checkin_screen.dart';
import 'package:scholai_app/features/journal/presentation/screens/journal_screen.dart';
import 'package:scholai_app/features/trends/presentation/screens/trends_screen.dart';
import 'package:scholai_app/features/crisis/presentation/screens/crisis_screen.dart';
import 'package:scholai_app/features/live/presentation/screens/gemini_live_screen.dart';
import 'package:scholai_app/shared/widgets/main_shell.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const CheckInScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/trends',
            builder: (context, state) => const TrendsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/crisis',
        builder: (context, state) => const CrisisScreen(),
      ),
      GoRoute(
        path: '/live',
        builder: (context, state) => const GeminiLiveScreen(),
      ),
    ],
  );
}
