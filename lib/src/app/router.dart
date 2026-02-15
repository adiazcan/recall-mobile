import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
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
  final config = ref.read(appConfigProvider);

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
        if (!isAuthenticated) {
          // Store the shared URL for after authentication (side effect)
          // TODO: Move this mutation to a listener for purity
          ref.read(authStateProvider.notifier).setPendingSharedUrl(sharedUrl);
          ref.read(sharedUrlProvider.notifier).clearSharedUrl();
          return '/onboarding';
        }

        // If authenticated, navigate to save screen with the shared URL
        if (!isSaveUrl) {
          // Clear after deciding to navigate (side effect)
          // TODO: Move this mutation to a listener for purity
          ref.read(sharedUrlProvider.notifier).clearSharedUrl();
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
        // Clear the pending URL and navigate to save screen (side effect)
        // TODO: Move this mutation to a listener for purity
        ref.read(authStateProvider.notifier).clearPendingSharedUrl();
        return Uri(
          path: '/save',
          queryParameters: {'url': pendingSharedUrl},
        ).toString();
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
              return InboxScreen(key: ValueKey(state.uri.toString()));
            },
          ),
          GoRoute(
            path: '/favorites',
            builder: (BuildContext context, GoRouterState state) {
              return InboxScreen(
                key: ValueKey(state.uri.toString()),
                viewFilter: InboxViewFilter.favorites,
              );
            },
          ),
          GoRoute(
            path: '/archive',
            builder: (BuildContext context, GoRouterState state) {
              return InboxScreen(
                key: ValueKey(state.uri.toString()),
                viewFilter: InboxViewFilter.archive,
              );
            },
          ),
          GoRoute(
            path: '/collections/:id',
            builder: (BuildContext context, GoRouterState state) {
              return InboxScreen(
                key: ValueKey(state.uri.toString()),
                collectionId: state.pathParameters['id'],
              );
            },
          ),
          GoRoute(
            path: '/tags/:id',
            builder: (BuildContext context, GoRouterState state) {
              return InboxScreen(
                key: ValueKey(state.uri.toString()),
                tagId: state.pathParameters['id'],
              );
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
          // Dev-only route for API inspection
          if (config.env == AppEnvironment.dev)
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
    ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (previous, next) => notifyListeners(),
    );
    ref.listen<String?>(sharedUrlProvider, (previous, next) {
      // Notify router when a shared URL arrives
      if (next != null && next.isNotEmpty) {
        notifyListeners();
      }
    });
  }
}
