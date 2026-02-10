import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/empty_state.dart';
import '../shared/error_view.dart';
import 'inbox_providers.dart';
import 'item_card.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilterBar ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showFilterBar = !_showFilterBar;
              });
            },
            tooltip: 'Filters',
          ),
        ],
      ),
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

  Widget _buildFilterBar() {
    final state = ref.watch(inboxProvider).valueOrNull;
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
                    ref.read(inboxProvider.notifier).clearFilters();
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
            ref.read(inboxProvider).valueOrNull?.filters ??
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
            ref.read(inboxProvider).valueOrNull?.filters ??
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
    );
  }
}
