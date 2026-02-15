import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../collections/collections_providers.dart';
import '../shared/design_tokens.dart';
import '../shared/url_validator.dart';
import 'inbox_providers.dart';

class QuickSaveOverlay extends ConsumerStatefulWidget {
  const QuickSaveOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  ConsumerState<QuickSaveOverlay> createState() => _QuickSaveOverlayState();
}

class _QuickSaveOverlayState extends ConsumerState<QuickSaveOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final TextEditingController _urlController = TextEditingController();

  bool _isSaving = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _animationController.forward();
    _prefillFromClipboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text?.trim();

    if (!mounted || clipboardText == null || clipboardText.isEmpty) {
      return;
    }

    if (isValidWebUrl(clipboardText)) {
      _urlController.text = clipboardText;
      _urlController.selection = TextSelection.collapsed(
        offset: clipboardText.length,
      );
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) {
      return;
    }

    _isDismissing = true;
    await _animationController.reverse();

    if (mounted) {
      widget.onDismiss();
    }
  }

  Future<void> _save() async {
    final validationError = validateRequiredWebUrl(_urlController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.createItem(url: _urlController.text.trim());

      if (mounted) {
        ref.invalidate(inboxProvider);
        ref.invalidate(collectionsProvider);
        ref.invalidate(tagsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL saved successfully!')),
        );
      }

      await _dismiss();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }

      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        final message = errorData is Map<String, dynamic>
            ? (errorData['message'] as String? ??
                  'This URL has already been saved')
            : 'This URL has already been saved';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        await _dismiss();
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save URL: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save URL: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: RecallColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RecallColors.neutral200),
              boxShadow: RecallShadows.quickSaveCard,
            ),
            padding: const EdgeInsets.all(17),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 38,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: RecallColors.neutral050,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: RecallColors.neutral200),
                    ),
                    child: TextField(
                      controller: _urlController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isSaving) {
                          _save();
                        }
                      },
                      style: RecallTextStyles.quickSaveInput,
                      decoration: const InputDecoration(
                        hintText: 'Paste URL to save...',
                        hintStyle: RecallTextStyles.quickSavePlaceholder,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 79.36,
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _dismiss,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: RecallColors.white,
                          side: const BorderSide(
                            color: RecallColors.neutral200,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          foregroundColor: RecallColors.neutral700,
                          textStyle: RecallTextStyles.quickSaveButton,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 63.75),
                      child: SizedBox(
                        height: 38,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: RecallColors.linkPurple,
                            disabledBackgroundColor: RecallColors.linkPurple
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: RecallTextStyles.quickSaveButton,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save', maxLines: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
