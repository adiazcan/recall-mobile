import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../models/collection.dart';
import '../../models/tag.dart';
import '../collections/collections_providers.dart';
import '../inbox/inbox_providers.dart';
import '../shared/design_tokens.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxProvider);
    final collectionsState = ref.watch(collectionsProvider);
    final tagsState = ref.watch(tagsProvider);

    final inboxCount = inboxState.maybeWhen(
      data: (state) => state.items.length,
      orElse: () => 0,
    );

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: RecallColors.white,
      surfaceTintColor: Colors.transparent,
      width: 256,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: RecallColors.white,
          border: Border(right: BorderSide(color: RecallColors.neutral200)),
          boxShadow: [
            BoxShadow(
              color: RecallColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    _NavItem(
                      icon: Icons.inbox_outlined,
                      label: 'Inbox',
                      count: inboxCount > 0 ? '$inboxCount' : null,
                      selected: currentPath == '/inbox',
                      onTap: () => _go(context, '/inbox'),
                    ),
                    _NavItem(
                      icon: Icons.star_outline,
                      label: 'Favorites',
                      selected: currentPath == '/favorites',
                      onTap: () => _go(context, '/favorites'),
                    ),
                    _NavItem(
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      selected: currentPath == '/archive',
                      onTap: () => _go(context, '/archive'),
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Collections',
                      onAdd: () => _showCreateCollectionDialog(context, ref),
                    ),
                    const SizedBox(height: 8),
                    ..._buildCollectionItems(context, collectionsState),
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Tags'),
                    const SizedBox(height: 8),
                    ..._buildTagItems(context, tagsState),
                  ],
                ),
              ),
              _ProfileFooter(
                selected: currentPath == '/settings',
                onSettingsTap: () => _go(context, '/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        child: Row(
          children: [
            const Text('Recall', style: RecallTextStyles.drawerBrand),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: RecallColors.neutral400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCollectionItems(
    BuildContext context,
    AsyncValue<List<Collection>> collectionsState,
  ) {
    return collectionsState.when(
      data: (collections) {
        if (collections.isEmpty) {
          return const [_EmptyLabel(text: 'No collections yet')];
        }

        return collections
            .map(
              (collection) => _NavItem(
                icon: Icons.folder_outlined,
                label: collection.name,
                count: collection.itemCount > 0
                    ? '${collection.itemCount}'
                    : null,
                selected: currentPath == '/collections/${collection.id}',
                onTap: () => _go(context, '/collections/${collection.id}'),
              ),
            )
            .toList();
      },
      loading: () => const [_EmptyLabel(text: 'Loading collections...')],
      error: (_, _) => const [_EmptyLabel(text: 'Unable to load collections')],
    );
  }

  List<Widget> _buildTagItems(
    BuildContext context,
    AsyncValue<List<Tag>> tagsState,
  ) {
    return tagsState.when(
      data: (tags) {
        if (tags.isEmpty) {
          return const [_EmptyLabel(text: 'No tags yet')];
        }

        return tags
            .map(
              (tag) => _TagNavItem(
                label: tag.name,
                count: tag.itemCount,
                selected: currentPath == '/tags/${tag.id}',
                onTap: () => _go(
                  context,
                  '/tags/${Uri.encodeComponent(tag.id)}',
                ),
              ),
            )
            .toList();
      },
      loading: () => const [_EmptyLabel(text: 'Loading tags...')],
      error: (_, _) => const [_EmptyLabel(text: 'Unable to load tags')],
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (currentPath != route) {
      context.go(route);
    }
  }

  Future<void> _showCreateCollectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New collection'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Collection name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (created != true) {
      return;
    }

    try {
      await ref
          .read(collectionsProvider.notifier)
          .createCollection(controller.text);
    } catch (_) {}
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onAdd});

  final String title;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: RecallTextStyles.drawerSectionHeader,
          ),
          if (onAdd != null) ...[
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAdd,
              child: const SizedBox(
                width: 14,
                height: 14,
                child: Icon(
                  Icons.add,
                  size: 14,
                  color: RecallColors.neutral400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;
  final String? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedIconColor = selected
        ? Theme.of(context).colorScheme.primary
        : RecallColors.neutral600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? RecallColors.neutral100 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: selectedIconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: selected
                          ? RecallTextStyles.drawerItemSelected
                          : RecallTextStyles.drawerItem,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count != null)
                    Text(count!, style: RecallTextStyles.drawerCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagNavItem extends StatelessWidget {
  const _TagNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? RecallColors.neutral100 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '#',
                    style: RecallTextStyles.drawerItem.copyWith(
                      color: selected
                          ? RecallColors.neutral900
                          : RecallColors.neutral600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: selected
                          ? RecallTextStyles.drawerItemSelected
                          : RecallTextStyles.drawerItem,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count != null && count! > 0)
                    Text('$count', style: RecallTextStyles.drawerCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({required this.onSettingsTap, required this.selected});

  final VoidCallback onSettingsTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: RecallColors.neutral100)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Material(
        color: selected ? RecallColors.neutral100 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onSettingsTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: RecallColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('JD', style: RecallTextStyles.drawerAvatar),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('John Doe', style: RecallTextStyles.drawerItem),
                ),
                const Icon(
                  Icons.settings,
                  size: 16,
                  color: RecallColors.neutral400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLabel extends StatelessWidget {
  const _EmptyLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Text(text, style: RecallTextStyles.drawerCount),
    );
  }
}
