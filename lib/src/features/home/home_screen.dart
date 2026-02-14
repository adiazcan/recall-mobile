import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.showApiRoute,
    required this.child,
  });

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  final Widget child;
  final bool showApiRoute;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedRoute = _getSelectedRoute(path);

    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text(
                  'Recall',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              _DrawerItem(
                icon: Icons.inbox,
                label: 'Inbox',
                selected: selectedRoute == '/inbox',
                onTap: () {
                  Navigator.of(context).pop();
                  if (selectedRoute != '/inbox') {
                    context.go('/inbox');
                  }
                },
              ),
              _DrawerItem(
                icon: Icons.folder,
                label: 'Collections',
                selected: selectedRoute == '/collections',
                onTap: () {
                  Navigator.of(context).pop();
                  if (selectedRoute != '/collections') {
                    context.go('/collections');
                  }
                },
              ),
              _DrawerItem(
                icon: Icons.settings,
                label: 'Settings',
                selected: selectedRoute == '/settings',
                onTap: () {
                  Navigator.of(context).pop();
                  if (selectedRoute != '/settings') {
                    context.go('/settings');
                  }
                },
              ),
              if (showApiRoute)
                _DrawerItem(
                  icon: Icons.api,
                  label: 'API',
                  selected: selectedRoute == '/api',
                  onTap: () {
                    Navigator.of(context).pop();
                    if (selectedRoute != '/api') {
                      context.go('/api');
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  String _getSelectedRoute(String path) {
    if (path.startsWith('/inbox')) return '/inbox';
    if (path.startsWith('/collections')) return '/collections';
    if (path.startsWith('/settings')) return '/settings';
    if (path.startsWith('/api')) return '/api';
    return '';
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
