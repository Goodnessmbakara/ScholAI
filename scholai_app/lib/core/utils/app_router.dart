import 'package:go_router/go_router.dart';
import 'package:scholai_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:scholai_app/features/checkin/presentation/screens/checkin_screen.dart';
import 'package:scholai_app/features/journal/presentation/screens/journal_screen.dart';
import 'package:scholai_app/features/trends/presentation/screens/trends_screen.dart';
import 'package:scholai_app/features/habits/presentation/screens/habit_picker_screen.dart';
import 'package:scholai_app/features/habits/presentation/screens/habits_screen.dart';
import 'package:scholai_app/features/crisis/presentation/screens/crisis_screen.dart';
import 'package:scholai_app/features/live/presentation/screens/gemini_live_screen.dart';
import 'package:scholai_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_request_form_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_request_status_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_chat_screen.dart';
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
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/trends',
            builder: (context, state) => const TrendsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/habits/setup',
        builder: (context, state) {
          final edit = state.uri.queryParameters['edit'] == '1';
          return HabitPickerScreen(fromSettings: edit);
        },
      ),
      GoRoute(
        path: '/crisis',
        builder: (context, state) => const CrisisScreen(),
      ),
      GoRoute(
        path: '/live',
        builder: (context, state) => const GeminiLiveScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/pro-request',
        builder: (context, state) => const ProRequestFormScreen(),
      ),
      GoRoute(
        path: '/pro-request/:id',
        builder: (context, state) => ProRequestStatusScreen(
          requestId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/pro-request/:id/chat',
        builder: (context, state) => ProChatScreen(
          requestId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
