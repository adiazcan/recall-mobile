import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/collection.dart';
import '../../models/item.dart';
import '../../models/tag.dart';
import '../collections/collections_providers.dart';
import '../shared/design_tokens.dart';
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
      _showMutationError(message: 'Could not open URL: $url');
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
      _showMutationError(
        message: 'Failed to update favorite: $e',
        onRetry: () => _toggleFavorite(item),
      );
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
      _showMutationError(
        message: 'Failed to update status: $e',
        onRetry: () => _toggleArchive(item),
      );
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
        _showMutationError(
          message: 'Failed to update tags: $e',
          onRetry: () async {
            final notifier = ref.read(itemDetailNotifierProvider.notifier);
            await notifier.updateTags(item.id, selectedTags);
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Tags updated')));
            }
          },
        );
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

      if (selectedCollectionId == null) return;
      final targetCollectionId =
          selectedCollectionId == CollectionPickerDialog.inboxSentinel
          ? null
          : selectedCollectionId;

      setState(() => _isUpdating = true);
      try {
        final notifier = ref.read(itemDetailNotifierProvider.notifier);
        await notifier.moveToCollection(item.id, targetCollectionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                targetCollectionId == null
                    ? 'Moved to inbox'
                    : 'Moved to collection',
              ),
            ),
          );
        }
      } catch (e) {
        _showMutationError(
          message: 'Failed to move item: $e',
          onRetry: () async {
            final notifier = ref.read(itemDetailNotifierProvider.notifier);
            await notifier.moveToCollection(item.id, targetCollectionId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    targetCollectionId == null
                        ? 'Moved to inbox'
                        : 'Moved to collection',
                  ),
                ),
              );
            }
          },
        );
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    } catch (e) {
      _showMutationError(
        message: 'Failed to load collections: $e',
        onRetry: () => _moveToCollection(item),
      );
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
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item deleted')));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
        _showMutationError(
          message: 'Failed to delete item: $e',
          onRetry: _deleteItem,
        );
      }
    }
  }

  void _showMutationError({
    required String message,
    Future<void> Function()? onRetry,
  }) {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => unawaited(onRetry()),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemDetailProvider(widget.itemId));
    final item = itemAsync.asData?.value;

    return Scaffold(
      backgroundColor: RecallColors.white,
      appBar: AppBar(
        backgroundColor: RecallColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close, size: 20),
          color: RecallColors.neutral400,
          tooltip: 'Close',
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: const EdgeInsets.all(8),
        ),
        actions: [
          if (item != null)
            IconButton(
              onPressed: _isUpdating ? null : () => _toggleFavorite(item),
              icon: Icon(
                item.isFavorite ? Icons.star : Icons.star_border,
                size: 20,
              ),
              color: item.isFavorite
                  ? RecallColors.favorite
                  : RecallColors.neutral500,
              tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: const EdgeInsets.all(8),
            ),
          if (item != null)
            IconButton(
              onPressed: _isUpdating ? null : () => _toggleArchive(item),
              icon: Icon(
                item.status == ItemStatus.archived
                    ? Icons.unarchive_outlined
                    : Icons.inventory_2_outlined,
                size: 20,
              ),
              color: RecallColors.neutral500,
              tooltip: item.status == ItemStatus.archived
                  ? 'Unarchive'
                  : 'Archive',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: const EdgeInsets.all(8),
            ),
          if (item != null)
            IconButton(
              onPressed: _isUpdating ? null : _deleteItem,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: RecallColors.neutral400,
              tooltip: 'Delete',
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: const EdgeInsets.all(8),
            ),
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: RecallColors.neutral200,
          ),
        ),
      ),
      body: itemAsync.when(
        data: _buildItemDetails,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: 'Failed to load item: $error',
          onRetry: () => ref.invalidate(itemDetailProvider(widget.itemId)),
        ),
      ),
    );
  }

  Widget _buildItemDetails(Item item) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final collectionLabel = collectionsAsync.when(
      data: (collections) {
        if (item.collectionId == null) {
          return 'Inbox';
        }
        Collection? collection;
        for (final entry in collections) {
          if (entry.id == item.collectionId) {
            collection = entry;
            break;
          }
        }
        return collection?.name ?? 'Unknown collection';
      },
      loading: () => 'Loading…',
      error: (error, stackTrace) =>
          item.collectionId == null ? 'Inbox' : 'Unknown collection',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.previewImageUrl != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: RecallColors.shadow,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: item.previewImageUrl!,
                  width: double.infinity,
                  height: 193,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 193,
                    color: RecallColors.neutral100,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 193,
                    color: RecallColors.neutral100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: RecallColors.neutral400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(item.title, style: RecallTextStyles.detailTitle),
          const SizedBox(height: 16),

          InkWell(
            onTap: _isUpdating ? null : () => _openInBrowser(item.url),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: RecallColors.linkPurple,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    item.url,
                    style: RecallTextStyles.detailUrl,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionLabel(icon: Icons.folder_outlined, label: 'COLLECTION'),
          const SizedBox(height: 6),
          InkWell(
            onTap: _isUpdating ? null : () => _moveToCollection(item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RecallColors.neutral050,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RecallColors.neutral100),
              ),
              child: Text(
                collectionLabel,
                style: RecallTextStyles.detailSectionValue,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionLabel(icon: Icons.tag, label: 'TAGS'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...item.tags.map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: RecallColors.tagGreenBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag.name,
                    style: RecallTextStyles.detailTag.copyWith(
                      color: RecallColors.tagGreenText,
                    ),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _isUpdating ? null : () => _editTags(item),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 26),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: RecallColors.neutral200),
                  foregroundColor: RecallColors.neutral500,
                  shape: const StadiumBorder(),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  textStyle: RecallTextStyles.detailTag.copyWith(
                    color: RecallColors.neutral500,
                  ),
                ),
                child: const Text('+ Add'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionLabel(icon: Icons.calendar_today_outlined, label: 'ADDED'),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatDate(item.createdAt),
              style: RecallTextStyles.detailSectionValue,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(
            height: 1,
            thickness: 1,
            color: RecallColors.neutral100,
          ),
          const SizedBox(height: 20),

          const Text(
            'Personal Notes',
            style: RecallTextStyles.detailNotesLabel,
          ),
          const SizedBox(height: 8),
          Container(
            height: 128,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RecallColors.neutral050,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RecallColors.neutral200),
            ),
            child: Text(
              'Add your thoughts here...',
              style: RecallTextStyles.detailSectionValue.copyWith(
                color: RecallColors.neutral700.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy • h:mm a').format(date);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: RecallColors.neutral400),
        const SizedBox(width: 8),
        Text(label, style: RecallTextStyles.detailSectionLabel),
      ],
    );
  }
}

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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: RecallColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RecallColors.neutral100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RecallColors.neutral200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Tags',
                      style: RecallTextStyles.headerTitle,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      color: RecallColors.neutral500,
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: RecallColors.neutral100,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TagPicker(
                    selectedTags: _selectedTags,
                    onTagsChanged: (tags) =>
                        setState(() => _selectedTags = tags),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          side: const BorderSide(
                            color: RecallColors.neutral200,
                          ),
                          foregroundColor: RecallColors.neutral600,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedTags),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          backgroundColor: RecallColors.neutral900,
                          foregroundColor: RecallColors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CollectionPickerDialog extends ConsumerWidget {
  const CollectionPickerDialog({
    super.key,
    required this.collections,
    required this.currentCollectionId,
  });

  static const String inboxSentinel = '__inbox__';

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
              onTap: () => Navigator.of(
                context,
              ).pop(CollectionPickerDialog.inboxSentinel),
            ),
            const Divider(),
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
