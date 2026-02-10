import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(path);
    final showFab =
        path.startsWith('/inbox') || path.startsWith('/collections');

    return Scaffold(
      appBar: AppBar(title: const Text('Recall')),
      body: child,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => context.push('/save'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/inbox');
              break;
            case 1:
              context.go('/collections');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Collections'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _getSelectedIndex(String path) {
    if (path.startsWith('/inbox')) return 0;
    if (path.startsWith('/collections')) return 1;
    if (path.startsWith('/settings')) return 2;
    return 0;
  }
}
