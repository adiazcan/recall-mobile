import 'package:flutter/material.dart';

import 'router.dart';

class RecallApp extends StatelessWidget {
  const RecallApp({super.key, this.configError});

  final String? configError;

  @override
  Widget build(BuildContext context) {
    if (configError != null) {
      return MaterialApp(
        title: 'Recall',
        home: MissingConfigScreen(message: configError!),
      );
    }

    return MaterialApp.router(
      title: 'Recall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: createRouter(),
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recall configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Missing app configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set required --dart-define values and relaunch this entrypoint.',
            ),
            const SizedBox(height: 16),
            SelectableText(message),
          ],
        ),
      ),
    );
  }
}
