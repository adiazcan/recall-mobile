import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../models/item.dart';
import '../shared/design_tokens.dart';
import '../shared/image_url_resolver.dart';

class ItemCard extends ConsumerWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final Item item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final token = ref.watch(authTokenProvider).asData?.value;
    final rawImageUrl = item.thumbnailImageUrl;
    final imageUrl = resolveImageUrl(rawImageUrl, config.apiBaseUrl);
    final requiresAuth = imageUrl != null
        ? imageUrlRequiresAuth(imageUrl, config.apiBaseUrl)
        : false;
    final imageHeaders = buildImageAuthHeaders(
      imageUrl: imageUrl,
      apiBaseUrl: config.apiBaseUrl,
      bearerToken: token,
    );
    final hasImage = imageUrl != null && (!requiresAuth || imageHeaders != null);
    final timeAgo = _formatTimeAgo(item.createdAt);
    final initial = _fallbackInitial();

    if (config.logHttp && rawImageUrl != null) {
      final source = item.previewImageUrl?.trim().isNotEmpty == true
          ? 'previewImageUrl'
          : 'thumbnailUrl';
      debugPrint(
        '[Image] Inbox item=${item.id} source=$source raw=$rawImageUrl resolved=${imageUrl ?? 'invalid'} requiresAuth=$requiresAuth hasAuthHeader=${imageHeaders != null}',
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: const BoxDecoration(
          color: RecallColors.white,
          border: Border(bottom: BorderSide(color: RecallColors.neutral100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FaviconTile(
              hasImage: hasImage,
              imageUrl: imageUrl,
              httpHeaders: imageHeaders,
              initial: initial,
              logHttp: config.logHttp,
              itemId: item.id,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RecallTextStyles.itemTitle,
                        ),
                      ),
                      if (item.isFavorite) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: RecallColors.favorite,
                        ),
                      ],
                    ],
                  ),
                  if (item.excerpt != null && item.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.excerpt!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RecallTextStyles.itemExcerpt,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RecallTextStyles.itemDomain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _MetaDot(),
                      const SizedBox(width: 8),
                      Text(timeAgo, style: RecallTextStyles.itemMeta),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...item.tags
                                    .take(2)
                                    .map(
                                      (tag) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: _TagPill(label: '#${tag.name}'),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackInitial() {
    final source = item.domain.isNotEmpty ? item.domain : item.title;
    final first = source.trim().isEmpty ? 'R' : source.trim()[0];
    return first.toUpperCase();
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays >= 1) {
      final value = diff.inDays;
      return '$value ${value == 1 ? 'day' : 'days'} ago';
    }

    if (diff.inHours >= 1) {
      final value = diff.inHours;
      return '$value ${value == 1 ? 'hour' : 'hours'} ago';
    }

    if (diff.inMinutes >= 1) {
      final value = diff.inMinutes;
      return '$value ${value == 1 ? 'minute' : 'minutes'} ago';
    }

    return 'Just now';
  }
}

class _FaviconTile extends StatelessWidget {
  const _FaviconTile({
    required this.hasImage,
    required this.imageUrl,
    required this.httpHeaders,
    required this.initial,
    required this.logHttp,
    required this.itemId,
  });

  final bool hasImage;
  final String? imageUrl;
  final Map<String, String>? httpHeaders;
  final String initial;
  final bool logHttp;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: RecallColors.neutral100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RecallColors.neutral200),
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                httpHeaders: httpHeaders,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) {
                  if (logHttp) {
                    debugPrint('[Image] Loaded inbox thumbnail item=$itemId url=$imageUrl');
                  }
                  return Image(
                    image: imageProvider,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  );
                },
                errorWidget: (context, url, error) =>
                    Builder(
                      builder: (context) {
                        if (logHttp) {
                          debugPrint(
                            '[Image] Failed inbox thumbnail item=$itemId url=$url error=$error',
                          );
                        }
                        return Text(
                          initial,
                          style: RecallTextStyles.faviconFallback,
                        );
                      },
                    ),
              ),
            )
          : Text(initial, style: RecallTextStyles.faviconFallback),
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 4,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RecallColors.neutral300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: RecallColors.neutral100,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(label, style: RecallTextStyles.tag),
    );
  }
}
