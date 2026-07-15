import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_card.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/providers.dart';

/// The "Gyaan Hub" wordmark + logo run 20% bigger than the rest of the app bar.
const _brandScale = 1.2;

/// Multiplies whatever text scaling is already in effect (the app-wide 0.8x
/// from [AppTextScaler], plus any OS accessibility setting) by [_factor], so
/// wrapping a subtree in this always renders that much bigger *relative to
/// its current size* rather than at some guessed absolute font size.
class _RelativeTextScaler extends TextScaler {
  const _RelativeTextScaler(this._factor, this._inner);

  final double _factor;
  final TextScaler _inner;

  @override
  double scale(double fontSize) => _inner.scale(fontSize) * _factor;

  // Deprecated upstream but still abstract, so it has to be implemented.
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => _inner.textScaleFactor * _factor;
}

/// Drives the "Trending Products" row. `sort: featured` puts the flagged
/// listings first but still returns unflagged ones to fill the page, hence the
/// filter — so the limit has to leave room for more trending items than we
/// currently have, or new ones get silently cut off.
final _featuredProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'featured', limit: 12);
  return res.data.where((listing) => listing.isFeatured).toList();
});

final _newestProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'newest', limit: 6);
  return res.data;
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return const [];
  try {
    return await ref.watch(announcementsApiProvider).list();
  } catch (_) {
    return const [];
  }
});

final dismissedAnnouncementsProvider = StateProvider<Set<String>>(
    (ref) => ref.watch(localStoreProvider).readDismissedAnnouncements());

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final featured = ref.watch(_featuredProvider);
    final newest = ref.watch(_newestProvider);
    final cartCount =
        ref.watch(cartControllerProvider.select((cart) => cart.count));

    final media = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: AppTokens.brSm,
              child: Image.asset(
                'assets/images/logo.png',
                width: 32 * AppTokens.scale * _brandScale,
                height: 32 * AppTokens.scale * _brandScale,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppTokens.s2),
            // Composes on top of the app-wide text scaler (rather than a
            // hardcoded fontSize) so "Gyaan Hub" comes out exactly 20% bigger
            // than the AppBar's default title size, whatever that resolves to.
            MediaQuery(
              data: media.copyWith(
                textScaler: _RelativeTextScaler(_brandScale, media.textScaler),
              ),
              child: const Text('Gyaan Hub'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => auth.isSignedIn
                ? context.push('/notifications')
                : context.push('/login?next=/notifications'),
          ),
          IconButton(
            // Switches to the Cart tab rather than pushing a new route, so
            // it stays in step with the bottom-nav Cart destination (same
            // screen, same state) instead of opening a second copy of it.
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_featuredProvider);
          ref.invalidate(_newestProvider);
          ref.invalidate(announcementsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            const _HomeSearchBar(),
            const SizedBox(height: AppTokens.s3),
            const _LocationBar(),
            const SizedBox(height: AppTokens.s4),
            const _AnnouncementsStrip(),
            const AdBanner(placement: 'home_top'),
            const SizedBox(height: AppTokens.s3),
            SectionHeader('Shop by category',
                actionLabel: 'View All',
                onAction: () => context.push('/categories')),
            SizedBox(
              height: 116 * AppTokens.scale,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shopCategories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppTokens.s3),
                itemBuilder: (context, index) {
                  final category = shopCategories[index];
                  return _CategoryTile(category: category);
                },
              ),
            ),
            featured.maybeWhen(
              data: (listings) => listings.isEmpty
                  ? const SizedBox.shrink()
                  : _ListingRow(title: 'Trending Products 🔥', listings: listings),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppTokens.s2),
            const AdBanner(placement: 'home_mid'),
            newest.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTokens.s6),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EmptyState(
                  emoji: '😵',
                  title: "Couldn't reach the store",
                  body: 'Check your connection and pull to refresh.'),
              data: (listings) => listings.isEmpty
                  ? const EmptyState(
                      title: 'The shelves are being stocked',
                      body: 'New items appear as soon as they are approved.')
                  : _ListingRow(title: 'New in the store', listings: listings),
            ),
            const SizedBox(height: AppTokens.s4),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ShopCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116 * AppTokens.scale,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTokens.gradientFor(category.slug),
            borderRadius: AppTokens.brLg,
            boxShadow: AppTokens.softShadow,
          ),
          child: InkWell(
            borderRadius: AppTokens.brLg,
            onTap: () {
              if (category.slug == 'custom-notebooks') {
                context.push('/notebook');
              } else {
                context.go('/shop?cat=${category.slug}');
              }
            },
            child: Padding(
              // s2, not s3: the badge plus a two-line label needs every pixel
              // of a tile this size.
              padding: const EdgeInsets.all(AppTokens.s2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44 * AppTokens.scale,
                    height: 44 * AppTokens.scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: AppTokens.brMd,
                    ),
                    child:
                        Text(category.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const Spacer(),
                  Text(
                    category.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingRow extends StatelessWidget {
  final String title;
  final List<Listing> listings;

  const _ListingRow({required this.title, required this.listings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        SizedBox(
          height: 250 * AppTokens.scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTokens.s3),
            itemBuilder: (context, index) => SizedBox(
              width: 170 * AppTokens.scale,
              child: ListingCard(listing: listings[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsStrip extends ConsumerWidget {
  const _AnnouncementsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    final dismissed = ref.watch(dismissedAnnouncementsProvider);

    return announcements.maybeWhen(
      data: (items) {
        final visible =
            items.where((a) => !dismissed.contains(a.id)).take(3).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return Column(
          children: visible
              .map((announcement) => Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.s3),
                    padding: const EdgeInsets.all(AppTokens.s3),
                    decoration: BoxDecoration(
                      color: switch (announcement.type) {
                        'warning' || 'maintenance' =>
                          AppTokens.warning.withValues(alpha: 0.12),
                        'success' => AppTokens.success.withValues(alpha: 0.12),
                        _ => AppTokens.tint,
                      },
                      borderRadius: AppTokens.brMd,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📣'),
                        const SizedBox(width: AppTokens.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(announcement.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              Text(announcement.content,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 16 * AppTokens.scale),
                          onPressed: () async {
                            await ref
                                .read(localStoreProvider)
                                .dismissAnnouncement(announcement.id);
                            ref
                                    .read(dismissedAnnouncementsProvider
                                        .notifier)
                                    .state =
                                {...dismissed, announcement.id};
                          },
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Home search entry point. Typing + submitting hands off to the real search
/// on the Shop tab (which reads `?q=`), so there's one search implementation.
class _HomeSearchBar extends StatefulWidget {
  const _HomeSearchBar();

  @override
  State<_HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<_HomeSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final query = value.trim();
    context.go(query.isEmpty ? '/shop' : '/shop?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: _submit,
      decoration: InputDecoration(
        hintText: 'Search books, notebooks, stationery…',
        prefixIcon: const Icon(Icons.search, color: AppTokens.inkSoft),
        suffixIcon: IconButton(
          icon: const Icon(Icons.mic_none_rounded, color: AppTokens.inkSoft),
          onPressed: () => _submit(_controller.text),
        ),
      ),
    );
  }
}

/// Delivery/location strip under the search bar. There is no location feature
/// yet, so the city is a styled placeholder — the row is here to match the
/// mockup's layout, ready to wire to a real location picker later.
class _LocationBar extends StatelessWidget {
  const _LocationBar();

  static const _city = 'Mumbai, Maharashtra';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: AppTokens.brSm,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location selection coming soon')),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 18, color: AppTokens.primary),
                const SizedBox(width: AppTokens.s1),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Deliver to: ',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTokens.inkSoft)),
                      TextSpan(
                          text: _city,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTokens.ink,
                              fontWeight: FontWeight.w700)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppTokens.inkSoft),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        Row(
          children: [
            const Text('🛵', style: TextStyle(fontSize: 14)),
            const SizedBox(width: AppTokens.s1),
            Text('Delivery in 30 mins',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppTokens.success, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
