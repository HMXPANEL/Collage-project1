import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/actions/action_log_screen.dart';
import '../features/actions/actions_screen.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/community/community_screen.dart';
import '../features/home/home_screen.dart';
import '../features/impact/impact_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/methodology_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
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
  static const logAction = 'logAction';
  static const challenges = 'challenges';
  static const profile = 'profile';
  static const community = 'community';
  static const coach = 'coach';
  static const settings = 'settings';
  static const privacy = 'privacy';
  static const about = 'about';
  static const methodology = 'methodology';
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
              GoRoute(
                path: '/actions/:actionId',
                name: AppRoutes.logAction,
                builder: (context, state) => ActionLogScreen(
                  actionId: state.pathParameters['actionId']!,
                ),
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
              GoRoute(
                path: '/community',
                name: AppRoutes.community,
                builder: (context, state) => const CommunityScreen(),
              ),
              GoRoute(
                path: '/coach',
                name: AppRoutes.coach,
                builder: (context, state) => const CoachScreen(),
              ),
              GoRoute(
                path: '/settings',
                name: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/privacy',
                name: AppRoutes.privacy,
                builder: (context, state) => const PrivacyScreen(),
              ),
              GoRoute(
                path: '/about',
                name: AppRoutes.about,
                builder: (context, state) => const AboutScreen(),
              ),
              GoRoute(
                path: '/methodology',
                name: AppRoutes.methodology,
                builder: (context, state) => const MethodologyScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
