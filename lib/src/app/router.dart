import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../features/api/api_screen.dart';
import '../features/collections/collections_screen.dart';
import '../features/home/home_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/item_detail/item_detail_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/save_url/save_url_screen.dart';
import '../features/settings/settings_screen.dart';
import 'providers.dart';

GoRouter createRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/inbox',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);

      final isAuthenticated = authState.maybeWhen(
        data: (state) => state.status == AuthStatus.authenticated,
        orElse: () => false,
      );

      final pendingSharedUrl = authState.maybeWhen(
        data: (state) => state.pendingSharedUrl,
        orElse: () => null,
      );

      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSaveUrl = state.matchedLocation.startsWith('/save');

      // Check for shared URL from external app
      final sharedUrl = ref.read(sharedUrlProvider);
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        // Clear the shared URL to prevent repeated navigation
        ref.read(sharedUrlProvider.notifier).clearSharedUrl();

        if (!isAuthenticated) {
          // Store the shared URL for after authentication
          ref.read(authStateProvider.notifier).setPendingSharedUrl(sharedUrl);
          return '/onboarding';
        }

        // If authenticated, navigate to save screen with the shared URL
        if (!isSaveUrl) {
          return Uri(
            path: '/save',
            queryParameters: {'url': sharedUrl},
          ).toString();
        }
      }

      // Handle pending shared URL after successful authentication
      if (isAuthenticated &&
          pendingSharedUrl != null &&
          pendingSharedUrl.isNotEmpty &&
          !isSaveUrl) {
        // Clear the pending URL and navigate to save screen
        final url = ref
            .read(authStateProvider.notifier)
            .clearPendingSharedUrl();
        if (url != null) {
          return Uri(path: '/save', queryParameters: {'url': url}).toString();
        }
      }

      // Standard auth redirect logic
      if (!isAuthenticated && !isOnboarding) {
        return '/onboarding';
      }

      if (isAuthenticated && isOnboarding && pendingSharedUrl == null) {
        return '/inbox';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/inbox',
            builder: (BuildContext context, GoRouterState state) {
              return const InboxScreen();
            },
          ),
          GoRoute(
            path: '/collections',
            builder: (BuildContext context, GoRouterState state) {
              return const CollectionsScreen();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsScreen();
            },
          ),
          GoRoute(
            path: '/api',
            builder: (BuildContext context, GoRouterState state) {
              return const ApiScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        builder: (BuildContext context, GoRouterState state) {
          final itemId = state.pathParameters['id']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/save',
        builder: (BuildContext context, GoRouterState state) {
          final prefilledUrl = state.uri.queryParameters['url'];
          return SaveUrlScreen(prefilledUrl: prefilledUrl);
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
    ref.listen(sharedUrlProvider, (previous, next) {
      // Notify router when a shared URL arrives
      if (next != null && next.isNotEmpty) {
        notifyListeners();
      }
    });
  }
}
