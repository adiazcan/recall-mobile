import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../models/item.dart';
import '../../models/tag.dart';
import '../shared/error_view.dart';
import '../shared/tag_picker.dart';
import 'item_detail_providers.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isUpdating = false;

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $url'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Item item) async {
    setState(() => _isUpdating = true);
    try {
      final notifier = ref.read(itemDetailNotifierProvider.notifier);
      await notifier.toggleFavorite(item.id, item.isFavorite);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.isFavorite ? 'Removed from favorites' : 'Added to favorites',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _toggleArchive(Item item) async {
    setState(() => _isUpdating = true);
    try {
      final notifier = ref.read(itemDetailNotifierProvider.notifier);
      final newStatus = item.status == ItemStatus.unread
          ? ItemStatus.archived
          : ItemStatus.unread;
      await notifier.updateStatus(item.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == ItemStatus.archived ? 'Archived' : 'Unarchived',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _editTags(Item item) async {
    final selectedTags = await showModalBottomSheet<List<Tag>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagEditSheet(initialTags: item.tags),
    );

    if (selectedTags != null && mounted) {
      setState(() => _isUpdating = true);
      try {
        final notifier = ref.read(itemDetailNotifierProvider.notifier);
        await notifier.updateTags(item.id, selectedTags);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tags updated')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update tags: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  Future<void> _moveToCollection(Item item) async {
    try {
      final collections = await ref.read(collectionsProvider.future);

      if (!mounted) return;

      final selectedCollectionId = await showDialog<String?>(
        context: context,
        builder: (context) => CollectionPickerDialog(
          collections: collections,
          currentCollectionId: item.collectionId,
        ),
      );

      if (selectedCollectionId == null && !mounted) return;

      setState(() => _isUpdating = true);
      try {
        final notifier = ref.read(itemDetailNotifierProvider.notifier);
        await notifier.moveToCollection(item.id, selectedCollectionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                selectedCollectionId == null
                    ? 'Moved to inbox'
                    : 'Moved to collection',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to move item: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    } catch (e) {
      // Error loading collections
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load collections: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        final notifier = ref.read(itemDetailNotifierProvider.notifier);
        await notifier.deleteItem(widget.itemId);

        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item deleted')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          if (_isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: itemAsync.when(
        data: (item) => _buildItemDetails(item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Failed to load item: $error',
          onRetry: () => ref.invalidate(itemDetailProvider(widget.itemId)),
        ),
      ),
    );
  }

  Widget _buildItemDetails(Item item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview image
          if (item.previewImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.previewImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Title
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),

          // Domain
          Row(
            children: [
              Icon(
                Icons.language,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                item.domain,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Excerpt
          if (item.excerpt != null && item.excerpt!.isNotEmpty) ...[
            Text(item.excerpt!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],

          // Status and favorite indicators
          Row(
            children: [
              Chip(
                label: Text(item.status.name.toUpperCase()),
                avatar: Icon(
                  item.status == ItemStatus.archived
                      ? Icons.archive
                      : Icons.inbox,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              if (item.isFavorite)
                const Chip(
                  label: Text('FAVORITE'),
                  avatar: Icon(Icons.star, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Tags
          if (item.tags.isNotEmpty) ...[
            Text('Tags', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags.map((tag) {
                return Chip(
                  label: Text(tag.name),
                  avatar: const Icon(Icons.label, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Timestamps
          Text(
            'Created: ${_formatDate(item.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated: ${_formatDate(item.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _isUpdating ? null : () => _openInBrowser(item.url),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _toggleFavorite(item),
                icon: Icon(item.isFavorite ? Icons.star : Icons.star_border),
                label: Text(
                  item.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _toggleArchive(item),
                icon: Icon(
                  item.status == ItemStatus.archived
                      ? Icons.unarchive
                      : Icons.archive,
                ),
                label: Text(
                  item.status == ItemStatus.archived ? 'Unarchive' : 'Archive',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _editTags(item),
                icon: const Icon(Icons.label),
                label: const Text('Edit Tags'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : () => _moveToCollection(item),
                icon: const Icon(Icons.folder),
                label: const Text('Move to Collection'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : _deleteItem,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Tag edit bottom sheet
class TagEditSheet extends StatefulWidget {
  const TagEditSheet({super.key, required this.initialTags});

  final List<Tag> initialTags;

  @override
  State<TagEditSheet> createState() => _TagEditSheetState();
}

class _TagEditSheetState extends State<TagEditSheet> {
  late List<Tag> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialTags);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Tags',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TagPicker(
              selectedTags: _selectedTags,
              onTagsChanged: (tags) => setState(() => _selectedTags = tags),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_selectedTags),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// Collection picker dialog
class CollectionPickerDialog extends ConsumerWidget {
  const CollectionPickerDialog({
    super.key,
    required this.collections,
    required this.currentCollectionId,
  });

  final List<Collection> collections;
  final String? currentCollectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Move to Collection'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Inbox option
            ListTile(
              title: const Text('Inbox'),
              // ignore: deprecated_member_use
              leading: Radio<String?>(
                value: null,
                // ignore: deprecated_member_use
                groupValue: currentCollectionId,
                // ignore: deprecated_member_use
                onChanged: null,
              ),
              onTap: () => Navigator.of(context).pop(null),
            ),
            const Divider(),
            // Collections
            ...collections.map((collection) {
              return ListTile(
                title: Text(collection.name),
                // ignore: deprecated_member_use
                leading: Radio<String?>(
                  value: collection.id,
                  // ignore: deprecated_member_use
                  groupValue: currentCollectionId,
                  // ignore: deprecated_member_use
                  onChanged: null,
                ),
                onTap: () => Navigator.of(context).pop(collection.id),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Collections provider (needed for collection picker)
final collectionsProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.getCollections();
});
