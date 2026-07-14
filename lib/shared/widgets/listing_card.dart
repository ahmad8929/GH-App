import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/favorites_state.dart';
import 'common.dart';
import 'listing_image.dart';

/// A round, floating icon button used over product imagery (favorite, etc.).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final double size;
  final VoidCallback onTap;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppTokens.ink,
    this.background = Colors.white,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppTokens.ink.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: iconColor),
        ),
      ),
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  final String listingId;
  final double size;

  const FavoriteButton({super.key, required this.listingId, this.size = 36});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorited = ref.watch(
        favoritesControllerProvider.select((ids) => ids.contains(listingId)));
    final signedIn =
        ref.watch(authControllerProvider.select((a) => a.isSignedIn));

    return CircleIconButton(
      size: size,
      icon: favorited ? Icons.favorite : Icons.favorite_border,
      iconColor: favorited ? AppTokens.coral : AppTokens.ink,
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
    );
  }
}

/// Gold "add to cart" pill/circle shown on product cards — the primary
/// shopping CTA colour from the redesign.
class _AddToCartButton extends ConsumerWidget {
  final Listing listing;

  const _AddToCartButton({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref
        .watch(cartControllerProvider.select((c) => c.contains(listing.id)));
    final sold = listing.status == 'sold';

    return CircleIconButton(
      size: 40 * AppTokens.scale,
      background: sold ? AppTokens.tint : AppTokens.gold,
      iconColor: AppTokens.ink,
      icon: inCart ? Icons.check_rounded : Icons.add_rounded,
      onTap: () async {
        if (sold) return;
        if (inCart) {
          context.push('/cart');
          return;
        }
        try {
          await ref.read(cartControllerProvider.notifier).add(listing);
          if (context.mounted) showSuccess(context, 'Added to cart');
        } catch (err) {
          if (context.mounted) showError(context, err);
        }
      },
    );
  }
}

class ListingCard extends StatelessWidget {
  final Listing listing;

  const ListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: AppTokens.brXl,
        boxShadow: AppTokens.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(color: AppTokens.background),
                    child: ListingImage(listing: listing),
                  ),
                  Positioned(
                    top: AppTokens.s2,
                    right: AppTokens.s2,
                    child: FavoriteButton(listingId: listing.id, size: 34 * AppTokens.scale),
                  ),
                  if (listing.isFeatured)
                    const Positioned(
                      top: AppTokens.s3,
                      left: AppTokens.s3,
                      child: AppPill(
                          label: '★ Featured',
                          color: AppTokens.gold,
                          textColor: AppTokens.ink),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.s3, AppTokens.s3, AppTokens.s2, AppTokens.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.isBulk
                        ? 'Bulk · MOQ ${listing.moq}'
                        : listing.subject?.isNotEmpty == true
                            ? listing.subject!
                            : (conditionLabels[listing.condition] ??
                                listing.condition),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppTokens.inkSoft),
                  ),
                  const SizedBox(height: AppTokens.s2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (listing.hasDiscount && !listing.isBulk)
                              Text(
                                inr(listing.originalPrice),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTokens.inkSoft,
                                ),
                              ),
                            Text(
                                listing.isBulk
                                    ? 'from ${inr(listing.lowestUnitPrice)}/u'
                                    : inr(listing.price),
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: AppTokens.ink)),
                          ],
                        ),
                      ),
                      _AddToCartButton(listing: listing),
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
}
