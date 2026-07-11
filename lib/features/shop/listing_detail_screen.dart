import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_card.dart';
import '../../shared/widgets/listing_image.dart';
import '../../shared/widgets/quantity_stepper.dart';
import '../../state/cart_state.dart';
import '../../state/providers.dart';

final _listingProvider = FutureProvider.family<Listing, String>(
    (ref, id) => ref.watch(listingsApiProvider).byId(id));

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ListingDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _imageIndex = 0;
  bool _adding = false;
  int? _quantity; // bulk only; null until the listing loads (starts at MOQ)

  Future<void> _addToCart(Listing listing) async {
    setState(() => _adding = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .add(listing, quantity: _quantity);
      if (mounted) showSuccess(context, 'Added to cart');
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(_listingProvider(widget.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Item')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          emoji: '🔍',
          title: 'Item not found',
          body: err.toString(),
          ctaLabel: 'Back to shop',
          onCta: () => context.go('/shop'),
        ),
        data: (listing) {
          final inCart = ref.watch(cartControllerProvider
              .select((cart) => cart.contains(listing.id)));
          final sold = listing.status == 'sold';

          return ListView(
            padding: const EdgeInsets.all(AppTokens.s4),
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s4),
                decoration: BoxDecoration(
                  gradient: AppTokens.gradientFor(listing.id),
                  borderRadius: AppTokens.brXl,
                  boxShadow: AppTokens.softShadow,
                ),
                child: Column(
                  children: [
                    if (listing.subject?.isNotEmpty == true ||
                        listing.grade?.isNotEmpty == true)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppPill(
                          label: listing.subject?.isNotEmpty == true
                              ? listing.subject!
                              : listing.grade!,
                          color: Colors.white,
                          textColor: AppTokens.ink,
                        ),
                      ),
                    const SizedBox(height: AppTokens.s3),
                    ClipRRect(
                      borderRadius: AppTokens.brLg,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child:
                            ListingImage(listing: listing, index: _imageIndex),
                      ),
                    ),
                  ],
                ),
              ),
              if (listing.images.length > 1) ...[
                const SizedBox(height: AppTokens.s2),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: listing.images.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppTokens.s2),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => setState(() => _imageIndex = index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppTokens.brSm,
                          border: Border.all(
                            color: index == _imageIndex
                                ? AppTokens.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: AppTokens.brSm,
                          child: CachedNetworkImage(
                            imageUrl: listing.images[index],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(listing.title,
                        style: theme.textTheme.headlineSmall),
                  ),
                  FavoriteButton(listingId: listing.id),
                ],
              ),
              const SizedBox(height: AppTokens.s2),
              if (listing.isBulk)
                _BulkPricing(
                  listing: listing,
                  quantity: _quantity ?? listing.moq,
                  onQuantityChanged: (qty) => setState(() => _quantity = qty),
                )
              else
                Row(
                  children: [
                    Text(inr(listing.price),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppTokens.ink)),
                    const SizedBox(width: AppTokens.s2),
                    if (listing.hasDiscount)
                      Text(inr(listing.originalPrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                  ],
                ),
              const SizedBox(height: AppTokens.s3),
              Wrap(
                spacing: AppTokens.s2,
                runSpacing: AppTokens.s2,
                children: [
                  AppPill(
                      label:
                          conditionLabels[listing.condition] ?? listing.condition),
                  AppPill(
                      label: listingTypeLabels[listing.listingType] ??
                          listing.listingType,
                      color: AppTokens.accent),
                  if (listing.grade != null) AppPill(label: listing.grade!),
                  if (listing.subject != null) AppPill(label: listing.subject!),
                  if (listing.city != null) AppPill(label: '📍 ${listing.city}'),
                ],
              ),
              if (listing.description != null &&
                  listing.description!.isNotEmpty) ...[
                const SizedBox(height: AppTokens.s4),
                Text('About this item', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTokens.s2),
                Text(listing.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: AppTokens.s4),
              Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: AppTokens.brSm,
                    child: Image.asset('assets/images/logo.png',
                        width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  title: const Text('Sold by Gyaan Hub'),
                  subtitle: const Text(
                      'Checked, approved, and delivered by our team.'),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              // Same creative pool as the home screen banner — the
              // 'listing_detail' placement has no ads assigned yet, so this
              // slot was invisible. Serve the home_top ads here too.
              const AdBanner(placement: 'home_top'),
              const SizedBox(height: AppTokens.s2),
              if (sold)
                const FilledButton(onPressed: null, child: Text('Sold out'))
              else if (inCart)
                OutlinedButton.icon(
                  onPressed: () => context.go('/cart'),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('In cart — view'),
                )
              else
                FilledButton.icon(
                  onPressed: _adding ? null : () => _addToCart(listing),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.gold,
                    foregroundColor: AppTokens.ink,
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(_adding
                      ? 'Adding…'
                      : listing.isBulk
                          ? 'Add ${_quantity ?? listing.moq} to cart · ${inr(listing.unitPriceFor(_quantity ?? listing.moq) * (_quantity ?? listing.moq))}'
                          : 'Buy now'),
                ),
              const SizedBox(height: AppTokens.s4),
            ],
          );
        },
      ),
    );
  }
}

/// Bulk pricing block: live unit price at the chosen quantity, a quantity
/// stepper anchored at the MOQ, and the tier ladder ("500+ · ₹4.20/unit").
class _BulkPricing extends StatelessWidget {
  final Listing listing;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const _BulkPricing({
    required this.listing,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = listing.unitPriceFor(quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${inr(unit)}/unit',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppTokens.ink)),
                  Text('MOQ ${listing.moq} units',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppTokens.inkSoft)),
                ],
              ),
            ),
            QuantityStepper(
              value: quantity,
              min: listing.moq,
              max: listing.stock,
              onChanged: onQuantityChanged,
            ),
          ],
        ),
        if (listing.priceTiers.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s3),
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            children: listing.priceTiers
                // Tap a tier to jump straight to its quantity — no + spam.
                .map((tier) => GestureDetector(
                      onTap: () => onQuantityChanged(tier.minQty),
                      child: AppPill(
                        label: '${tier.minQty}+ · ${inr(tier.unitPrice)}/unit',
                        color: quantity >= tier.minQty
                            ? AppTokens.gold
                            : AppTokens.tint,
                        textColor: AppTokens.ink,
                      ),
                    ))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.s1),
            child: Text('Tap a tier to jump to it · tap the count to type',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppTokens.inkSoft)),
          ),
        ],
      ],
    );
  }
}
