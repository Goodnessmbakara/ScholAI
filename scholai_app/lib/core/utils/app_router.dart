import 'package:go_router/go_router.dart';
import 'package:scholai_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:scholai_app/features/checkin/presentation/screens/checkin_screen.dart';
import 'package:scholai_app/features/journal/presentation/screens/journal_screen.dart';
import 'package:scholai_app/features/trends/presentation/screens/trends_screen.dart';
import 'package:scholai_app/features/habits/presentation/screens/habit_picker_screen.dart';
import 'package:scholai_app/features/habits/domain/habit_models.dart';
import 'package:scholai_app/features/habits/presentation/screens/habits_screen.dart';
import 'package:scholai_app/features/habits/presentation/screens/urge_timer_screen.dart';
import 'package:scholai_app/features/crisis/presentation/screens/crisis_screen.dart';
import 'package:scholai_app/features/live/presentation/screens/gemini_live_screen.dart';
import 'package:scholai_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/my_cases_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_apply_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_request_form_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/support_hub_screen.dart';
import 'package:scholai_app/features/admin/presentation/screens/admin_console_screen.dart';
import 'package:scholai_app/features/admin/presentation/screens/staff_chat_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_request_status_screen.dart';
import 'package:scholai_app/features/pro/presentation/screens/pro_chat_screen.dart';
import 'package:scholai_app/shared/widgets/main_shell.dart';

class AppRouter {
  static const resumePlaces = {'/home', '/journal', '/habits', '/trends'};

  /// Set from the last session before [router] is first read.
  static String initialLocation = '/onboarding';

  static final router = GoRouter(
    initialLocation: initialLocation,
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
        path: '/habits/surf',
        builder: (context, state) {
          final habit = HabitKind.tryParse(
                state.uri.queryParameters['habit'] ?? '',
              ) ??
              HabitKind.smoking;
          return UrgeTimerScreen(habit: habit);
        },
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
        path: '/support',
        builder: (context, state) => const SupportHubScreen(),
      ),
      GoRoute(
        path: '/pro-apply',
        builder: (context, state) => const ProApplyScreen(),
      ),
      GoRoute(
        path: '/my-cases',
        builder: (context, state) => const MyCasesScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminConsoleScreen(),
      ),
      GoRoute(
        path: '/admin/chat/:uid/:requestId',
        builder: (context, state) => StaffChatScreen(
          userId: state.pathParameters['uid']!,
          requestId: state.pathParameters['requestId']!,
        ),
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
