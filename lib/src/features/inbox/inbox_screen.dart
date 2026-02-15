import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../models/collection.dart';
import '../../models/tag.dart';
import '../collections/collections_providers.dart';
import '../home/home_screen.dart';
import '../shared/app_header.dart';
import '../shared/design_tokens.dart';
import '../shared/empty_state.dart';
import '../shared/error_view.dart';
import 'inbox_providers.dart';
import 'item_card.dart';

enum InboxViewFilter { inbox, favorites, archive }

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({
    super.key,
    this.viewFilter = InboxViewFilter.inbox,
    this.collectionId,
    this.tagId,
  });

  final InboxViewFilter viewFilter;
  final String? collectionId;
  final String? tagId;

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _scrollController = ScrollController();
  bool _showFilterBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future<void>.microtask(_syncRouteFilters);
  }

  @override
  void didUpdateWidget(covariant InboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewFilter != widget.viewFilter ||
        oldWidget.collectionId != widget.collectionId ||
        oldWidget.tagId != widget.tagId) {
      Future<void>.microtask(_syncRouteFilters);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when reaching 90% of scroll
      ref.read(inboxProvider.notifier).loadMore();
    }
  }

  Future<void> _syncRouteFilters() async {
    final notifier = ref.read(inboxProvider.notifier);
    final currentFilters = ref.read(inboxProvider).asData?.value.filters;

    final targetFilters = _buildRouteFilters();
    if (currentFilters != null && _sameFilters(currentFilters, targetFilters)) {
      return;
    }

    await notifier.updateFilters(targetFilters);
  }

  InboxFilters _buildRouteFilters() {
    if (widget.collectionId != null && widget.collectionId!.isNotEmpty) {
      return InboxFilters(collectionId: widget.collectionId);
    }

    if (widget.tagId != null && widget.tagId!.isNotEmpty) {
      return InboxFilters(tagIds: [widget.tagId!]);
    }

    switch (widget.viewFilter) {
      case InboxViewFilter.favorites:
        return const InboxFilters(isFavorite: true);
      case InboxViewFilter.archive:
        return const InboxFilters(status: 'archived');
      case InboxViewFilter.inbox:
        return const InboxFilters(status: 'unread');
    }
  }

  bool _sameFilters(InboxFilters left, InboxFilters right) {
    final leftTags = left.tagIds ?? const <String>[];
    final rightTags = right.tagIds ?? const <String>[];

    return left.status == right.status &&
        left.isFavorite == right.isFavorite &&
        left.collectionId == right.collectionId &&
        leftTags.length == rightTags.length &&
        leftTags.every(rightTags.contains);
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);
    final collectionsState = ref.watch(collectionsProvider);
    final tagsState = ref.watch(tagsProvider);
    final itemCount = inboxState.maybeWhen(
      data: (state) => state.items.length,
      orElse: () => 0,
    );
    final headerTitle = _resolveHeaderTitle(collectionsState, tagsState);

    return Scaffold(
      appBar: _buildInboxAppBar(headerTitle, itemCount),
      body: Column(
        children: [
          // Filter bar
          if (_showFilterBar) _buildFilterBar(),

          // Content
          Expanded(
            child: inboxState.when(
              data: (state) => _buildContent(state),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorView(
                message: 'Failed to load items: ${error.toString()}',
                onRetry: () => ref.read(inboxProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveHeaderTitle(
    AsyncValue<List<Collection>> collectionsState,
    AsyncValue<List<Tag>> tagsState,
  ) {
    if (widget.collectionId != null && widget.collectionId!.isNotEmpty) {
      final collections = collectionsState.asData?.value;
      if (collections != null) {
        for (final collection in collections) {
          if (collection.id == widget.collectionId) {
            return collection.name;
          }
        }
      }
      return 'Collection';
    }

    if (widget.tagId != null && widget.tagId!.isNotEmpty) {
      final tags = tagsState.asData?.value;
      if (tags != null) {
        for (final tag in tags) {
          if (tag.id == widget.tagId) {
            return '#${tag.name}';
          }
        }
      }
      return 'Tag';
    }

    switch (widget.viewFilter) {
      case InboxViewFilter.favorites:
        return 'Favorites';
      case InboxViewFilter.archive:
        return 'Archive';
      case InboxViewFilter.inbox:
        return 'Inbox';
    }
  }

  PreferredSizeWidget _buildInboxAppBar(String title, int itemCount) {
    return RecallAppBar(
      onMenuPressed: () => HomeScreen.scaffoldKey.currentState?.openDrawer(),
      title: Row(
        children: [
          Text(title, style: RecallTextStyles.headerTitle),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: const BoxDecoration(
              color: RecallColors.neutral100,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Text('$itemCount', style: RecallTextStyles.headerCount),
          ),
        ],
      ),
      actions: [
        HeaderIconAction(
          onPressed: null,
          icon: Icons.search,
          tooltip: 'Search',
        ),
        HeaderIconAction(
          onPressed: () {
            setState(() {
              _showFilterBar = !_showFilterBar;
            });
          },
          icon: _showFilterBar ? Icons.filter_alt : Icons.filter_alt_outlined,
          tooltip: 'Filters',
        ),
        HeaderAddButton(onTap: () => context.push('/save')),
      ],
    );
  }

  Widget _buildFilterBar() {
    final state = ref.watch(inboxProvider).asData?.value;
    if (state == null) return const SizedBox.shrink();

    final filters = state.filters;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              if (filters.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    ref
                        .read(inboxProvider.notifier)
                        .updateFilters(_buildRouteFilters());
                  },
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Status filter
              _buildStatusChip(filters.status),

              // Favorites filter
              _buildFavoritesChip(filters.isFavorite),

              // Collection filter (placeholder - will be implemented later)
              // TODO: Implement collection dropdown when collections UI is ready

              // Tags filter (placeholder - will be implemented later)
              // TODO: Implement tags multi-select when tags UI is ready
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? currentStatus) {
    return FilterChip(
      label: Text(currentStatus ?? 'All'),
      selected: currentStatus != null,
      onSelected: (selected) {
        final notifier = ref.read(inboxProvider.notifier);
        final currentFilters =
            ref.read(inboxProvider).asData?.value.filters ??
            const InboxFilters();

        String? newStatus;
        if (selected) {
          newStatus = 'unread';
        } else if (currentStatus == 'unread') {
          newStatus = 'archived';
        }

        notifier.updateFilters(
          currentFilters.copyWith(status: () => newStatus),
        );
      },
      avatar: currentStatus != null
          ? const Icon(Icons.check_circle, size: 18)
          : null,
    );
  }

  Widget _buildFavoritesChip(bool? isFavorite) {
    return FilterChip(
      label: const Text('Favorites'),
      selected: isFavorite == true,
      onSelected: (selected) {
        final notifier = ref.read(inboxProvider.notifier);
        final currentFilters =
            ref.read(inboxProvider).asData?.value.filters ??
            const InboxFilters();

        notifier.updateFilters(
          currentFilters.copyWith(isFavorite: () => selected ? true : null),
        );
      },
      avatar: isFavorite == true ? const Icon(Icons.star, size: 18) : null,
    );
  }

  Widget _buildContent(InboxState state) {
    if (state.items.isEmpty && !state.isLoadingMore) {
      return RefreshIndicator(
        onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              message: state.filters.hasActiveFilters
                  ? 'No items match your filters'
                  : 'No items saved yet\nTap the + button to save your first URL',
              icon: state.filters.hasActiveFilters
                  ? Icons.search_off
                  : Icons.inbox_outlined,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
      child: Column(
        children: [
          if (state.backgroundError != null)
            MaterialBanner(
              content: Text(state.backgroundError!),
              actions: [
                TextButton(
                  onPressed: () => ref.read(inboxProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  // Loading indicator at the bottom
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: state.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final item = state.items[index];
                return ItemCard(
                  item: item,
                  onTap: () {
                    context.push('/item/${item.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
