import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'providers.dart';

class RecallApp extends ConsumerStatefulWidget {
  const RecallApp({super.key, this.configError});

  final String? configError;

  @override
  ConsumerState<RecallApp> createState() => _RecallAppState();
}

class _RecallAppState extends ConsumerState<RecallApp> {
  StreamSubscription? _intentMediaStreamSubscription;
  StreamSubscription? _intentTextStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  @override
  void dispose() {
    _intentMediaStreamSubscription?.cancel();
    _intentTextStreamSubscription?.cancel();
    super.dispose();
  }

  void _initSharingIntent() {
    // Handle shared URLs when app is already running (warm start)
    _intentMediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              // Some apps share URLs as media files
              for (var media in value) {
                if (media.path.startsWith('http')) {
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

    // Handle shared text/URLs (most common for URL sharing)
    _intentTextStreamSubscription = ReceiveSharingIntent.instance
        .getTextStream()
        .listen(
          (String value) {
            if (value.isNotEmpty) {
              _handleSharedUrl(value);
              ReceiveSharingIntent.instance.reset();
            }
          },
          onError: (err) {
            debugPrint('Error receiving shared text: $err');
          },
        );

    // Handle shared URLs when app starts from share action (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        for (var media in value) {
          if (media.path.startsWith('http')) {
            _handleSharedUrl(media.path);
            ReceiveSharingIntent.instance.reset();
            break;
          }
        }
      }
    });

    // Handle initial shared text (cold start)
    ReceiveSharingIntent.instance.getInitialText().then((String? value) {
      if (value != null && value.isNotEmpty) {
        _handleSharedUrl(value);
        ReceiveSharingIntent.instance.reset();
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

  @override
  Widget build(BuildContext context) {
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
