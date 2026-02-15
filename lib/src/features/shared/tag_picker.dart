import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/tag.dart';
import 'design_tokens.dart';

class TagPicker extends ConsumerStatefulWidget {
  const TagPicker({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  final List<Tag> selectedTags;
  final ValueChanged<List<Tag>> onTagsChanged;

  @override
  ConsumerState<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends ConsumerState<TagPicker> {
  final _newTagController = TextEditingController();
  bool _isCreatingTag = false;

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _createTag(String name) async {
    if (name.trim().isEmpty) return;

    setState(() => _isCreatingTag = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final newTag = await apiClient.createTag(name.trim());

      // Add to selected tags
      widget.onTagsChanged([...widget.selectedTags, newTag]);

      // Refresh tags list
      ref.invalidate(tagsProvider);

      // Clear input
      _newTagController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tag "$name" created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tag: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingTag = false);
      }
    }
  }

  void _toggleTag(Tag tag) {
    final isSelected = widget.selectedTags.any((t) => t.id == tag.id);
    if (isSelected) {
      widget.onTagsChanged(
        widget.selectedTags.where((t) => t.id != tag.id).toList(),
      );
    } else {
      widget.onTagsChanged([...widget.selectedTags, tag]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected tags chips
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedTags.map((tag) {
              return Chip(
                label: Text(
                  tag.name,
                  style: RecallTextStyles.detailTag.copyWith(
                    color: RecallColors.tagGreenText,
                  ),
                ),
                backgroundColor: RecallColors.tagGreenBg,
                side: BorderSide.none,
                deleteIconColor: RecallColors.tagGreenText,
                deleteIcon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
                onDeleted: () => _toggleTag(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Available tags
        tagsAsync.when(
          data: (allTags) {
            final unselectedTags = allTags
                .where((tag) => !widget.selectedTags.any((t) => t.id == tag.id))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unselectedTags.isNotEmpty) ...[
                  Text(
                    'Available tags:',
                    style: RecallTextStyles.detailSectionLabel,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unselectedTags.map((tag) {
                      return ActionChip(
                        label: Text(
                          tag.name,
                          style: RecallTextStyles.detailTag.copyWith(
                            color: RecallColors.neutral600,
                          ),
                        ),
                        backgroundColor: RecallColors.neutral050,
                        side: const BorderSide(color: RecallColors.neutral200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        onPressed: () => _toggleTag(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // New tag input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTagController,
                        style: RecallTextStyles.detailSectionValue,
                        decoration: InputDecoration(
                          labelText: 'Create new tag',
                          hintText: 'Enter tag name',
                          labelStyle: RecallTextStyles.itemMeta,
                          hintStyle: RecallTextStyles.detailSectionValue
                              .copyWith(color: RecallColors.neutral400),
                          filled: true,
                          fillColor: RecallColors.neutral050,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: RecallColors.neutral200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: RecallColors.neutral200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: RecallColors.linkPurple,
                            ),
                          ),
                        ),
                        enabled: !_isCreatingTag,
                        onSubmitted: _createTag,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        backgroundColor: RecallColors.neutral900,
                        foregroundColor: RecallColors.white,
                        disabledBackgroundColor: RecallColors.neutral300,
                        disabledForegroundColor: RecallColors.white,
                      ),
                      onPressed: _isCreatingTag
                          ? null
                          : () => _createTag(_newTagController.text),
                      child: _isCreatingTag
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RecallColors.white,
                              ),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load tags: $error',
              style: RecallTextStyles.detailSectionValue.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
