import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/collection.dart';
import '../home/home_screen.dart';
import '../shared/app_header.dart';
import '../shared/empty_state.dart';
import '../shared/error_view.dart';
import 'collections_providers.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: RecallAppBar(
        onMenuPressed: () => HomeScreen.scaffoldKey.currentState?.openDrawer(),
        title: const HeaderTitle('Collections'),
        actions: [
          HeaderAddButton(onTap: () => _showCreateDialog(context, ref)),
        ],
      ),
      body: collectionsAsync.when(
        data: (collections) {
          if (collections.isEmpty) {
            return EmptyState(
              message: 'No collections yet',
              icon: Icons.folder_outlined,
              action: FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Create collection'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(collectionsProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: collections.length,
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final collection = collections[index];
                return _CollectionListTile(collection: collection);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: 'Failed to load collections: $error',
          onRetry: () => ref.invalidate(collectionsProvider),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create collection'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Research',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a collection name';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) async {
                    if (!isSubmitting) {
                      await _submitCreate(
                        dialogContext,
                        ref,
                        formKey,
                        controller.text,
                        setState,
                        () => isSubmitting,
                        (value) => isSubmitting = value,
                      );
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          await _submitCreate(
                            dialogContext,
                            ref,
                            formKey,
                            controller.text,
                            setState,
                            () => isSubmitting,
                            (value) => isSubmitting = value,
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Collection created.')));
    }
  }

  Future<void> _submitCreate(
    BuildContext dialogContext,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    String name,
    void Function(void Function()) setState,
    bool Function() getSubmitting,
    void Function(bool) setSubmitting,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => setSubmitting(true));
    try {
      await ref.read(collectionsProvider.notifier).createCollection(name);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop(true);
      }
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text(_errorMessageFrom(error))));
      }
      if (getSubmitting()) {
        setState(() => setSubmitting(false));
      }
    }
  }

  String _errorMessageFrom(Object error) {
    if (error is DuplicateCollectionNameException) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    if (error is InvalidCollectionNameException) {
      return 'Collection name cannot be empty.';
    }
    return 'Unable to save collection. Please try again.';
  }
}

class _CollectionListTile extends ConsumerWidget {
  const _CollectionListTile({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(collection.name),
      subtitle: Text(
        collection.itemCount == 1 ? '1 item' : '${collection.itemCount} items',
      ),
      trailing: PopupMenuButton<_CollectionAction>(
        onSelected: (action) async {
          switch (action) {
            case _CollectionAction.rename:
              await _showRenameDialog(context, ref, collection);
              break;
            case _CollectionAction.delete:
              await _showDeleteDialog(context, ref, collection);
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: _CollectionAction.rename, child: Text('Rename')),
          PopupMenuItem(value: _CollectionAction.delete, child: Text('Delete')),
        ],
      ),
      onTap: () async {
        if (context.mounted) {
          context.go('/collections/${collection.id}');
        }
      },
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    final controller = TextEditingController(text: collection.name);
    final formKey = GlobalKey<FormState>();

    final renamed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rename collection'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  enabled: !isSubmitting,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a collection name';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await ref
                                .read(collectionsProvider.notifier)
                                .renameCollection(
                                  collection.id,
                                  controller.text,
                                );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_errorMessage(error))),
                              );
                            }
                            setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (renamed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Collection renamed.')));
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Collection collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete collection?'),
          content: Text(
            'Delete "${collection.name}"? Items in this collection will move to Inbox.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(collectionsProvider.notifier)
          .deleteCollection(collection.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Collection deleted.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete collection. Please try again.'),
          ),
        );
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is DuplicateCollectionNameException) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    if (error is InvalidCollectionNameException) {
      return 'Collection name cannot be empty.';
    }
    return 'Unable to update collection. Please try again.';
  }
}

enum _CollectionAction { rename, delete }
