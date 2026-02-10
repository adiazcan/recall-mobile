import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../auth/auth_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authStateProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configuration', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Environment: ${config.env.name}'),
          const SizedBox(height: 8),
          SelectableText('API_BASE_URL: ${config.apiBaseUrl}'),
          const SizedBox(height: 8),
          SelectableText('OPENAPI_SPEC_URL: ${config.openApiSpecUrl}'),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('Authentication', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          authState.when(
            data: (state) {
              final isSigningOut = state.status == AuthStatus.loading;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        state.status == AuthStatus.authenticated
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: state.status == AuthStatus.authenticated
                            ? Colors.green
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.status == AuthStatus.authenticated
                            ? 'Signed in'
                            : 'Not signed in',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: isSigningOut
                        ? null
                        : () async {
                            final shouldSignOut = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text(
                                  'Are you sure you want to sign out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldSignOut == true) {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .signOut();
                            }
                          },
                    icon: isSigningOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: Text(isSigningOut ? 'Signing out...' : 'Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(authStateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text('Development', style: Theme.of(context).textTheme.titleLarge),
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
