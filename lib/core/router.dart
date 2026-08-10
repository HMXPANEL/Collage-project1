import 'package:go_router/go_router.dart';

import '../features/actions/actions_screen.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/home/home_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/home_shell.dart';

/// App-level navigation. Route names are stable so screens can link to each
/// other without hardcoding paths.
abstract final class AppRoutes {
  static const home = 'home';
  static const impact = 'impact';
  static const actions = 'actions';
  static const challenges = 'challenges';
  static const profile = 'profile';
}

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/impact',
              name: AppRoutes.impact,
              builder: (context, state) => const ImpactScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/actions',
              name: AppRoutes.actions,
              builder: (context, state) => const ActionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/challenges',
              name: AppRoutes.challenges,
              builder: (context, state) => const ChallengesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
