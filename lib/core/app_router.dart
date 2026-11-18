import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/food/custom_food_screen.dart';
import '../features/food/daily_log_screen.dart';
import '../features/food/food_detail_screen.dart';
import '../features/food/food_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/workout/exercise_log_screen.dart';
import '../features/workout/session_screen.dart';
import '../features/workout/summary_screen.dart';
import '../features/workout/workout_screen.dart';
import '../widgets/bite_bottom_nav.dart';
import '../core/utils/format_numbers.dart';
import 'bite_page.dart';
import 'constants/meals.dart';

// How it works: the four tabs stay in the shell. Detail screens are pushed
// on top, so the bar is hidden. Onboarding runs once, then Home opens.

GoRouter createBiteRouter(
  ProfileRepository profiles,
  SessionController session,
) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: session,
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = session.accountId != null;
      final String here = state.matchedLocation;
      final bool atAuth = here == '/login' || here == '/signup';
      if (!loggedIn && !atAuth) {
        return '/login';
      }
      if (!loggedIn) {
        return null;
      }
      final bool done = profiles.isOnboardingDone();
      final bool atOnboarding = here == '/onboarding';
      if (atAuth) {
        return done ? '/home' : '/onboarding';
      }
      if (!done && !atOnboarding) {
        return '/onboarding';
      }
      if (done && atOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const LoginScreen());
        },
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const SignupScreen());
        },
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const OnboardingScreen());
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const ProfileScreen());
        },
      ),
      GoRoute(
        path: '/premium',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const PremiumScreen());
        },
      ),
      GoRoute(
        path: '/log',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(
            state,
            DailyLogScreen(initialDay: dateFromKey(state.uri.queryParameters['date'])),
          );
        },
      ),
      GoRoute(
        path: '/food/custom',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(state, const CustomFoodScreen());
        },
      ),
      GoRoute(
        path: '/food/:id',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final int foodId = int.parse(state.pathParameters['id']!);
          final String meal =
              state.uri.queryParameters['meal'] ?? mealForTime(DateTime.now());
          final String? logText = state.uri.queryParameters['logId'];
          return bitePage(
            state,
            FoodDetailScreen(
              foodId: foodId,
              meal: meal,
              logId: logText == null ? null : int.tryParse(logText),
              date: state.uri.queryParameters['date'],
            ),
          );
        },
      ),
      GoRoute(
        path: '/workout/session/:id',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(
            state,
            SessionScreen(sessionId: int.parse(state.pathParameters['id']!)),
          );
        },
      ),
      GoRoute(
        path: '/workout/exercise/:id',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(
            state,
            ExerciseLogScreen(
              exerciseId: int.parse(state.pathParameters['id']!),
              sessionId: int.parse(state.uri.queryParameters['session'] ?? '0'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/workout/summary/:id',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return bitePage(
            state,
            SummaryScreen(sessionId: int.parse(state.pathParameters['id']!)),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BiteBottomNav(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (BuildContext context, GoRouterState state) {
                  return const HomeScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/food',
                builder: (BuildContext context, GoRouterState state) {
                  return FoodScreen(date: state.uri.queryParameters['date']);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                builder: (BuildContext context, GoRouterState state) {
                  return const WorkoutScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProgressScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
