import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/auth_state.dart';
import '../../state/favorites_state.dart';
import 'common.dart';

class FavoriteButton extends ConsumerWidget {
  final String listingId;
  final double size;

  const FavoriteButton({super.key, required this.listingId, this.size = 20});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorited = ref.watch(
        favoritesControllerProvider.select((ids) => ids.contains(listingId)));
    final signedIn =
        ref.watch(authControllerProvider.select((a) => a.isSignedIn));

    return Material(
      color: AppTokens.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          if (!signedIn) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Log in to save favorites')));
            context.push('/login');
            return;
          }
          try {
            final nowFavorited = await ref
                .read(favoritesControllerProvider.notifier)
                .toggle(listingId);
            if (context.mounted) {
              showSuccess(context,
                  nowFavorited ? 'Saved to favorites' : 'Removed from favorites');
            }
          } catch (err) {
            if (context.mounted) showError(context, err);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s2),
          child: Icon(
            favorited ? Icons.favorite : Icons.favorite_border,
            size: size,
            color: favorited ? AppTokens.coral : AppTokens.primaryDark,
          ),
        ),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: listing.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: listing.images.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const _Placeholder(),
                        )
                      : const _Placeholder(),
                ),
                Positioned(
                  top: AppTokens.s2,
                  right: AppTokens.s2,
                  child: FavoriteButton(listingId: listing.id, size: 18),
                ),
                if (listing.isFeatured)
                  const Positioned(
                    top: AppTokens.s2,
                    left: AppTokens.s2,
                    child: AppPill(label: '★ Featured', color: AppTokens.accent),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(inr(listing.price),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: AppTokens.primary)),
                        const SizedBox(width: AppTokens.s2),
                        if (listing.hasDiscount)
                          Expanded(
                            child: Text(
                              inr(listing.originalPrice),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s1),
                    Expanded(
                      child: Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: AppTokens.s1),
                    Text(
                      conditionLabels[listing.condition] ?? listing.condition,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTokens.tint,
      alignment: Alignment.center,
      child: const Text('📚', style: TextStyle(fontSize: 34)),
    );
  }
}
