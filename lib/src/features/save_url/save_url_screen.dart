import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../models/tag.dart';
import '../collections/collections_providers.dart';
import '../inbox/inbox_providers.dart';
import '../shared/error_view.dart';
import '../shared/tag_picker.dart';

class SaveUrlScreen extends ConsumerStatefulWidget {
  const SaveUrlScreen({super.key, this.prefilledUrl});

  final String? prefilledUrl;

  @override
  ConsumerState<SaveUrlScreen> createState() => _SaveUrlScreenState();
}

class _SaveUrlScreenState extends ConsumerState<SaveUrlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  String? _selectedCollectionId;
  List<Tag> _selectedTags = [];
  bool _isSaving = false;
  String? _errorMessage;
  String? _duplicateItemId;
  _SaveMutationError? _mutationError;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUrl != null) {
      _urlController.text = widget.prefilledUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.hasAuthority) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }

    return null;
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _duplicateItemId = null;
      _mutationError = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createItem(
        url: _urlController.text.trim(),
        collectionId: _selectedCollectionId,
        tagIds: _selectedTags.map((tag) => tag.name).toList(),
      );

      if (mounted) {
        // Refresh inbox to show new item
        ref.invalidate(inboxProvider);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL saved successfully!')),
        );

        // Navigate back to inbox
        context.pop(true); // Pass true to signal success
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Duplicate URL
        final errorData = e.response?.data;
        final existingItemId = errorData is Map<String, dynamic>
            ? errorData['existingItemId'] as String?
            : null;

        setState(() {
          _isSaving = false;
          _errorMessage = errorData is Map<String, dynamic>
              ? (errorData['message'] as String? ??
                    'This URL has already been saved')
              : 'This URL has already been saved';
          _duplicateItemId = existingItemId;
        });
      } else {
        setState(() {
          _isSaving = false;
          _mutationError = _SaveMutationError(
            message: 'Failed to save URL: ${e.message}',
            onRetry: _saveUrl,
          );
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _mutationError = _SaveMutationError(
          message: 'Failed to save URL: $e',
          onRetry: _saveUrl,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Save URL')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // URL text field
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com/article',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  validator: _validateUrl,
                  enabled: !_isSaving,
                ),

                const SizedBox(height: 16),

                // Collection picker
                collectionsAsync.when(
                  data: (collections) {
                    return DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Collection (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                      initialValue: _selectedCollectionId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Inbox)'),
                        ),
                        ...collections.map((collection) {
                          return DropdownMenuItem<String?>(
                            value: collection.id,
                            child: Text(collection.name),
                          );
                        }),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCollectionId = value;
                              });
                            },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => ErrorView(
                    message: 'Failed to load collections',
                    onRetry: () => ref.invalidate(collectionsProvider),
                  ),
                ),

                const SizedBox(height: 16),

                // Tags section
                const Text(
                  'Tags (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TagPicker(
                  selectedTags: _selectedTags,
                  onTagsChanged: _isSaving
                      ? (_) {} // Disable during saving
                      : (tags) {
                          setState(() {
                            _selectedTags = tags;
                          });
                        },
                ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_duplicateItemId != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              final itemId = _duplicateItemId;
                              Navigator.of(context).pop();
                              if (itemId != null) {
                                context.push('/item/$itemId');
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('View existing item'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_mutationError != null) ...[
                  ErrorView(
                    message: _mutationError!.message,
                    onRetry: _mutationError!.onRetry,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _mutationError = null;
                        });
                      },
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Save button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveUrl,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveMutationError {
  const _SaveMutationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;
}
