import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Environment: ${config.env.name}'),
          const SizedBox(height: 8),
          SelectableText('API_BASE_URL: ${config.apiBaseUrl}'),
          const SizedBox(height: 8),
          SelectableText('OPENAPI_SPEC_URL: ${config.openApiSpecUrl}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref.read(tokenStoreProvider).clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stored tokens cleared.')),
                );
              }
            },
            child: const Text('Clear tokens'),
          ),
        ],
      ),
    );
  }
}
