import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/api/api_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/api',
    routes: [
      GoRoute(
        path: '/',
        redirect: (BuildContext context, GoRouterState state) => '/api',
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/api',
            builder: (BuildContext context, GoRouterState state) {
              return const ApiScreen();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsScreen();
            },
          ),
        ],
      ),
    ],
  );
}
