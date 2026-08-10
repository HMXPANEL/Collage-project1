import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/actions/actions_screen.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/home/home_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import 'state/providers.dart';

/// App-level navigation. Route names are stable so screens can link to each
/// other without hardcoding paths.
abstract final class AppRoutes {
  static const splash = 'splash';
  static const welcome = 'welcome';
  static const home = 'home';
  static const impact = 'impact';
  static const actions = 'actions';
  static const challenges = 'challenges';
  static const profile = 'profile';
}

/// Router that redirects to onboarding until a completed profile exists.
final goRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref);
  ref.onDispose(router.dispose);
  ref.listen(profileProvider, (_, __) => router.refresh());
  return router;
});

GoRouter createAppRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final profileState = ref.read(profileProvider);
      final location = state.matchedLocation;

      if (profileState.isLoading || profileState.hasError) {
        return location == '/splash' ? null : '/splash';
      }
      final profile = profileState.value;
      final onboarded = profile?.onboarded ?? false;
      if (!onboarded) {
        return location == '/welcome' ? null : '/welcome';
      }
      if (location == '/splash' || location == '/welcome') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: AppRoutes.welcome,
        builder: (context, state) => const OnboardingFlow(),
      ),
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
}
