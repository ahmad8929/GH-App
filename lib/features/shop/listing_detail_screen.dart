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

  Future<void> _addToCart(Listing listing) async {
    setState(() => _adding = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(listing);
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
              ClipRRect(
                borderRadius: AppTokens.brLg,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: listing.images.isEmpty
                      ? Container(
                          color: AppTokens.tint,
                          alignment: Alignment.center,
                          child:
                              const Text('📚', style: TextStyle(fontSize: 64)),
                        )
                      : CachedNetworkImage(
                          imageUrl: listing.images[_imageIndex],
                          fit: BoxFit.cover,
                        ),
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
              Row(
                children: [
                  Text(inr(listing.price),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppTokens.primary)),
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
                  title: const Text('Sold by Gyan Hub'),
                  subtitle: const Text(
                      'Checked, approved, and delivered by our team.'),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              const AdBanner(placement: 'listing_detail'),
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
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(_adding ? 'Adding…' : 'Add to cart'),
                ),
              const SizedBox(height: AppTokens.s4),
            ],
          );
        },
      ),
    );
  }
}
