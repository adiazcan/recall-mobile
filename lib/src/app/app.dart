import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../auth/auth_state.dart';
import 'providers.dart';

/// MethodChannel for reading pending shared URLs from the native side
const _pendingUrlsChannel = MethodChannel('com.recall.mobile/pendingUrls');

class RecallApp extends ConsumerStatefulWidget {
  const RecallApp({super.key, this.configError});

  final String? configError;

  @override
  ConsumerState<RecallApp> createState() => _RecallAppState();
}

class _RecallAppState extends ConsumerState<RecallApp>
    with WidgetsBindingObserver {
  StreamSubscription? _intentMediaStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharingIntent();
    // Check for pending URLs from share extension on launch
    _checkPendingSharedUrls();
    // Sync auth config to extension so it can make API calls
    _syncAuthConfigToExtension();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentMediaStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for pending URLs every time the app comes to foreground
      _checkPendingSharedUrls();
      // Re-sync token in case it was refreshed
      _syncAuthConfigToExtension();
    }
  }

  void _initSharingIntent() {
    // Handle shared URLs when app is already running (warm start)
    _intentMediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              // Handle URLs and text shared from other apps
              for (var media in value) {
                if (media.type == SharedMediaType.url ||
                    media.type == SharedMediaType.text ||
                    media.path.startsWith('http')) {
                  _handleSharedUrl(media.path);
                  ReceiveSharingIntent.instance.reset();
                  break;
                }
              }
            }
          },
          onError: (err) {
            debugPrint('Error receiving shared media: $err');
          },
        );

    // Handle shared URLs when app starts from share action (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        for (var media in value) {
          if (media.type == SharedMediaType.url ||
              media.type == SharedMediaType.text ||
              media.path.startsWith('http')) {
            _handleSharedUrl(media.path);
            ReceiveSharingIntent.instance.reset();
            break;
          }
        }
      }
    });
  }

  void _handleSharedUrl(String sharedText) {
    // Extract URL from shared text (some apps share URLs with additional context)
    final urlPattern = RegExp(r'https?://[^\s]+');
    final match = urlPattern.firstMatch(sharedText);
    final url = match?.group(0) ?? sharedText.trim();

    // Store the shared URL in a provider so it can be picked up by the router
    // We'll create a sharedUrlProvider to handle this
    ref.read(sharedUrlProvider.notifier).setSharedUrl(url);
  }

  /// Check shared UserDefaults for URLs saved by the Share Extension.
  /// The extension stores pending URLs in group.com.recall.mobile UserDefaults
  /// under the key "pendingSharedURLs". We read them, process the first one,
  /// and clear the list.
  Future<void> _checkPendingSharedUrls() async {
    try {
      final result = await _pendingUrlsChannel.invokeMethod<List<dynamic>>(
        'getPendingUrls',
      );
      if (result != null && result.isNotEmpty) {
        // Process the first pending URL
        final url = result.first as String;
        debugPrint('[Share] Found pending URL from extension: $url');
        _handleSharedUrl(url);
        // Clear after reading
        await _pendingUrlsChannel.invokeMethod<void>('clearPendingUrls');
      }
    } on MissingPluginException {
      // Channel not implemented on this platform, ignore
      debugPrint('[Share] Pending URLs channel not available');
    } catch (e) {
      debugPrint('[Share] Error checking pending URLs: $e');
    }
  }

  /// Sync the current access token and API base URL to shared UserDefaults
  /// so the Share Extension can make authenticated API calls directly.
  Future<void> _syncAuthConfigToExtension() async {
    try {
      final tokenStore = ref.read(tokenStoreProvider);
      final config = ref.read(appConfigProvider);
      final token = await tokenStore.getToken();
      debugPrint(
        '[Share] _syncAuthConfigToExtension: token=${token != null ? "present (${token.length} chars)" : "NULL"}, apiBaseUrl=${config.apiBaseUrl}',
      );
      if (token != null) {
        await _pendingUrlsChannel.invokeMethod<void>('syncAuthConfig', {
          'accessToken': token,
          'apiBaseUrl': config.apiBaseUrl,
        });
        debugPrint('[Share] Synced auth config to extension successfully');
      } else {
        debugPrint('[Share] No token available — skipping sync');
      }
    } on MissingPluginException {
      debugPrint('[Share] syncAuthConfig channel not available');
    } catch (e) {
      debugPrint('[Share] Error syncing auth config: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync auth config to share extension whenever auth state changes
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final status = next.valueOrNull?.status;
      if (status == AuthStatus.authenticated) {
        debugPrint(
          '[Share] Auth state → authenticated, syncing token to extension',
        );
        _syncAuthConfigToExtension();
      }
    });

    if (widget.configError != null) {
      return MaterialApp(
        title: 'Recall',
        home: MissingConfigScreen(message: widget.configError!),
      );
    }

    return MaterialApp.router(
      title: 'Recall',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      builder: (context, child) {
        final networkStatusAsync = ref.watch(networkStatusProvider);
        final isOffline = networkStatusAsync.maybeWhen(
          data: (status) => status == NetworkStatus.offline,
          orElse: () => false,
        );

        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Offline mode: showing cached data',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      routerConfig: ref.watch(routerProvider),
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
