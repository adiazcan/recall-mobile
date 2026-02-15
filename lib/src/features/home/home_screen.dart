import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    return Scaffold(
      key: scaffoldKey,
      drawer: AppDrawer(currentPath: path),
      body: child,
    );
  }
}
