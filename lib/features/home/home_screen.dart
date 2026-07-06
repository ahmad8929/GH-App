import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/listing_card.dart';
import '../../state/auth_state.dart';
import '../../state/providers.dart';

final _featuredProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'featured', limit: 4);
  return res.data.where((listing) => listing.isFeatured).toList();
});

final _newestProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'newest', limit: 6);
  return res.data;
});

final _blogTeasersProvider = FutureProvider<List<BlogPost>>((ref) async {
  try {
    final res = await ref.watch(blogsApiProvider).list();
    return res.data.take(3).toList();
  } catch (_) {
    return const [];
  }
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
    final blogs = ref.watch(_blogTeasersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: AppTokens.brSm,
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppTokens.s2),
            const Text('Gyan Hub'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => auth.isSignedIn
                ? context.push('/notifications')
                : context.push('/login?next=/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_featuredProvider);
          ref.invalidate(_newestProvider);
          ref.invalidate(_blogTeasersProvider);
          ref.invalidate(announcementsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s4),
          children: [
            Text(
              auth.isSignedIn
                  ? 'Hi, ${auth.user!.name.split(' ').first}! 👋'
                  : 'School things, shared smarter. 🎒',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              'Old books, new books, uniforms, stationery & custom notebooks.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppTokens.s4),
            const _AnnouncementsStrip(),
            const AdBanner(placement: 'home_top'),
            const SizedBox(height: AppTokens.s3),
            SectionHeader('Shop by category'),
            SizedBox(
              height: 108,
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
                  : _ListingRow(title: 'Staff picks ⭐', listings: listings),
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
            blogs.maybeWhen(
              data: (posts) => posts.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader('From the blog',
                            actionLabel: 'All articles',
                            onAction: () => context.push('/blogs')),
                        ...posts.map((post) => Card(
                              margin:
                                  const EdgeInsets.only(bottom: AppTokens.s3),
                              child: ListTile(
                                onTap: () =>
                                    context.push('/blogs/${post.slug}'),
                                title: Text(post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(post.excerpt,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                              ),
                            )),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
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
      width: 120,
      child: Card(
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
            padding: const EdgeInsets.all(AppTokens.s3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: AppTokens.s2),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
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
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTokens.s3),
            itemBuilder: (context, index) => SizedBox(
              width: 170,
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
                          icon: const Icon(Icons.close, size: 16),
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
