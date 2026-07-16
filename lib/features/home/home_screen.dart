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
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/providers.dart';

final _featuredProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'featured', limit: 12);
  return res.data.where((listing) => listing.isFeatured).toList();
});

final _newestProvider = FutureProvider<List<Listing>>((ref) async {
  final res =
      await ref.watch(listingsApiProvider).list(sort: 'newest', limit: 10);
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74 * AppTokens.scale,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => context.push('/categories'),
        ),
        title: const _BrandHeader(),
        actions: [
          _HeaderActionIcon(
            icon: Icons.notifications_none_rounded,
            showDot: auth.isSignedIn,
            onTap: () => auth.isSignedIn
                ? context.push('/notifications')
                : context.push('/login?next=/notifications'),
          ),
          _HeaderActionIcon(
            icon: Icons.shopping_cart_outlined,
            badgeCount: cartCount,
            onTap: () => context.go('/cart'),
          ),
          const SizedBox(width: AppTokens.s2),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_featuredProvider);
          ref.invalidate(_newestProvider);
          ref.invalidate(announcementsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s4, AppTokens.s2, AppTokens.s4, AppTokens.s5),
          children: [
            const _HomeSearchBar(),
            const SizedBox(height: AppTokens.s3),
            const _LocationBar(),
            const SizedBox(height: AppTokens.s3),
            const _AnnouncementsStrip(),
            const _HeroCarousel(),
            const SizedBox(height: AppTokens.s4),
            _SectionHeading(
              title: 'Shop By Category',
              actionLabel: 'View All',
              onAction: () => context.push('/categories'),
            ),
            const SizedBox(height: AppTokens.s2),
            const _QuickCategoryRail(),
            const SizedBox(height: AppTokens.s4),
            _SectionHeading(
              title: 'Category Tags',
              actionLabel: 'View All',
              onAction: () => context.push('/categories'),
            ),
            const SizedBox(height: AppTokens.s2),
            const _TagWrap(),
            const SizedBox(height: AppTokens.s4),
            const _PromoCardRow(),
            const SizedBox(height: AppTokens.s4),
            featured.maybeWhen(
              data: (listings) => listings.isEmpty
                  ? const SizedBox.shrink()
                  : _ProductShelf(
                      title: 'Trending Products',
                      actionLabel: 'View All',
                      onAction: () => context.go('/shop'),
                      listings: listings,
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppTokens.s3),
            const AdBanner(placement: 'home_top'),
            const SizedBox(height: AppTokens.s2),
            newest.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTokens.s6),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const EmptyState(
                title: "Couldn't reach the store",
                body: 'Check your connection and pull to refresh.',
              ),
              data: (listings) => listings.isEmpty
                  ? const EmptyState(
                      title: 'The shelves are being stocked',
                      body: 'New items appear as soon as they are approved.',
                    )
                  : _ProductShelf(
                      title: "Today's Deal",
                      trailing: const _DealCountdown(),
                      actionLabel: 'View All',
                      onAction: () => context.go('/shop'),
                      listings: listings,
                    ),
            ),
            const SizedBox(height: AppTokens.s4),
            const _TrustSignals(),
            const SizedBox(height: AppTokens.s4),
            const AdBanner(placement: 'home_mid'),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppTokens.brMd,
          child: Image.asset(
            'assets/images/logo.png',
            width: 34 * AppTokens.scale,
            height: 34 * AppTokens.scale,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Gyaan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTokens.primaryDark,
                    ),
                  ),
                  TextSpan(
                    text: 'Hub',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTokens.success,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Everything for every student',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTokens.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionIcon extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final bool showDot;
  final VoidCallback onTap;

  const _HeaderActionIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount > 0 || showDot;
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(icon: Icon(icon), onPressed: onTap),
          if (showBadge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppTokens.danger,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 0 ? '$badgeCount' : '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _HeroData(
      eyebrow: 'BACK TO',
      title: 'SCHOOL SALE',
      subtitle: 'Up to 40% OFF',
      body: 'Books, stationery and daily essentials',
      cta: 'Shop now',
      route: '/shop',
      pushRoute: false,
      backgroundStart: Color(0xFF0E2D71),
      backgroundEnd: Color(0xFFFFB400),
      accent: Color(0xFFFFD45A),
      assets: [
        'assets/images/categories/notebook.jpg',
        'assets/images/categories/stationery.jpg',
        'assets/images/categories/books.jpg',
      ],
    ),
    _HeroData(
      eyebrow: 'EARN FROM',
      title: 'OLD BOOKS',
      subtitle: 'Sell or donate in minutes',
      body: 'Upload used books and help the next student save more',
      cta: 'Upload now',
      route: '/sell',
      pushRoute: false,
      backgroundStart: Color(0xFFDFF7EE),
      backgroundEnd: Color(0xFF8FE0B8),
      accent: Color(0xFF24B899),
      darkText: true,
      assets: [
        'assets/images/categories/books.jpg',
        'assets/images/categories/books.jpg',
      ],
    ),
    _HeroData(
      eyebrow: 'CREATE YOUR',
      title: 'OWN NOTEBOOK',
      subtitle: 'Custom covers and 3D preview',
      body: 'Design a notebook that feels like yours before you order it',
      cta: 'Start now',
      route: '/notebook',
      backgroundStart: Color(0xFFFAE5D7),
      backgroundEnd: Color(0xFFF7B977),
      accent: Color(0xFFF48A1D),
      darkText: true,
      assets: [
        'assets/images/categories/notebook.jpg',
        'assets/images/categories/art.jpg',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168 * AppTokens.scale,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) =>
                _HeroCard(data: _slides[index], selected: index == _index),
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final active = index == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6 * AppTokens.scale,
              width: (active ? 18 : 6) * AppTokens.scale,
              decoration: BoxDecoration(
                color: active ? AppTokens.success : AppTokens.tint,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroData {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String body;
  final String cta;
  final String route;
  final bool pushRoute;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color accent;
  final bool darkText;
  final List<String> assets;

  const _HeroData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.cta,
    required this.route,
    this.pushRoute = true,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.accent,
    this.darkText = false,
    required this.assets,
  });
}

class _HeroCard extends StatelessWidget {
  final _HeroData data;
  final bool selected;

  const _HeroCard({required this.data, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = data.darkText ? AppTokens.ink : Colors.white;
    return AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: const Duration(milliseconds: 200),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppTokens.brLg,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [data.backgroundStart, data.backgroundEnd],
          ),
          boxShadow: AppTokens.softShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -20,
              child: Container(
                width: 110 * AppTokens.scale,
                height: 110 * AppTokens.scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              right: 16 * AppTokens.scale,
              bottom: 16 * AppTokens.scale,
              child: _HeroArtwork(
                assets: data.assets,
                darkText: data.darkText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s4),
              child: SizedBox(
                width: 170 * AppTokens.scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.eyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: data.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      data.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s2),
                    Text(
                      data.subtitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s1),
                    Text(
                      data.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            data.darkText ? data.accent : Colors.white,
                        foregroundColor:
                            data.darkText ? Colors.white : AppTokens.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s4,
                          vertical: AppTokens.s2,
                        ),
                      ),
                      onPressed: () {
                        if (data.pushRoute) {
                          context.push(data.route);
                        } else {
                          context.go(data.route);
                        }
                      },
                      child: Text(data.cta),
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

class _HeroArtwork extends StatelessWidget {
  final List<String> assets;
  final bool darkText;

  const _HeroArtwork({required this.assets, required this.darkText});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 130 * AppTokens.scale,
      height: 120 * AppTokens.scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 18,
            child: Transform.rotate(
              angle: -0.15,
              child: _HeroAssetCard(
                path: assets.first,
                width: 74 * AppTokens.scale,
                height: 96 * AppTokens.scale,
              ),
            ),
          ),
          if (assets.length > 1)
            Positioned(
              right: 0,
              top: 0,
              child: _HeroAssetCard(
                path: assets[1],
                width: 84 * AppTokens.scale,
                height: 104 * AppTokens.scale,
              ),
            ),
          if (assets.length > 2)
            Positioned(
              right: 4,
              bottom: -8,
              child: Container(
                width: 44 * AppTokens.scale,
                height: 44 * AppTokens.scale,
                decoration: BoxDecoration(
                  color: darkText
                      ? Colors.white.withValues(alpha: 0.92)
                      : AppTokens.gold.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  boxShadow: AppTokens.softShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(assets[2], fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroAssetCard extends StatelessWidget {
  final String path;
  final double width;
  final double height;

  const _HeroAssetCard({
    required this.path,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: AppTokens.brLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: AppTokens.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(path, fit: BoxFit.cover),
    );
  }
}

class _QuickCategoryRail extends StatelessWidget {
  const _QuickCategoryRail();

  static const _items = [
    _QuickCategory(
      label: 'Books',
      icon: Icons.menu_book_rounded,
      gradient: [Color(0xFFEAE8FF), Color(0xFFD3D7FF)],
      route: '/shop?cat=old-books',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'Stationery',
      icon: Icons.edit_note_rounded,
      gradient: [Color(0xFFE7F6FF), Color(0xFFD8ECFF)],
      route: '/shop?cat=stationery',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'School',
      icon: Icons.backpack_rounded,
      gradient: [Color(0xFFE8FFF2), Color(0xFFD1F4E1)],
      route: '/shop?cat=uniforms',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'College',
      icon: Icons.school_rounded,
      gradient: [Color(0xFFFFF1DD), Color(0xFFFFE4BF)],
      route: '/shop?q=college',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'Electronics',
      icon: Icons.laptop_mac_rounded,
      gradient: [Color(0xFFF0F4FF), Color(0xFFDDE7FF)],
      route: '/shop?q=calculator',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'Art & Craft',
      icon: Icons.palette_outlined,
      gradient: [Color(0xFFFFF0F5), Color(0xFFFADFEA)],
      route: '/shop?q=art',
      pushRoute: false,
    ),
    _QuickCategory(
      label: 'More',
      icon: Icons.apps_rounded,
      gradient: [Color(0xFFF7F7FB), Color(0xFFE9ECF5)],
      route: '/categories',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppTokens.s2;
        final itemWidth = (constraints.maxWidth - (gap * (_items.length - 1))) /
            _items.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              SizedBox(
                width: itemWidth,
                child: _QuickCategoryTile(item: _items[i]),
              ),
              if (i != _items.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class _QuickCategory {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  final bool pushRoute;

  const _QuickCategory({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
    this.pushRoute = true,
  });
}

class _QuickCategoryTile extends StatelessWidget {
  final _QuickCategory item;

  const _QuickCategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppTokens.brMd,
      onTap: () {
        if (item.pushRoute) {
          context.push(item.route);
        } else {
          context.go(item.route);
        }
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 46 * AppTokens.scale,
              height: 46 * AppTokens.scale,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: item.gradient,
                ),
                borderRadius: AppTokens.brLg,
                boxShadow: AppTokens.softShadow,
              ),
              child: Icon(item.icon, color: AppTokens.primaryDark, size: 19),
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              item.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap();

  static const _tags = [
    _TagData('School', Icons.holiday_village_rounded, '/shop?q=school'),
    _TagData('College', Icons.school_rounded, '/shop?q=college'),
    _TagData('Stationery', Icons.draw_rounded, '/shop?cat=stationery'),
    _TagData('Corporate', Icons.apartment_rounded, '/shop?cat=corporate'),
    _TagData('Used Books', Icons.auto_stories_rounded, '/shop?cat=old-books'),
    _TagData('Electronics', Icons.computer_rounded, '/shop?q=calculator'),
    _TagData('Office', Icons.work_outline_rounded, '/shop?q=office'),
    _TagData('Exam Prep', Icons.emoji_events_rounded, '/shop?q=exam'),
    _TagData('Bags', Icons.backpack_outlined, '/shop?q=bag'),
    _TagData('Art & Craft', Icons.palette_outlined, '/shop?q=art'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        final gap = AppTokens.s2;
        final chipWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: _tags
              .map((tag) => InkWell(
                    borderRadius: AppTokens.brSm,
                    onTap: () => context.go(tag.route),
                    child: Container(
                      width: chipWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s2,
                        vertical: AppTokens.s2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppTokens.brSm,
                        border: Border.all(color: AppTokens.tint),
                      ),
                      child: Row(
                        children: [
                          Icon(tag.icon, size: 13, color: AppTokens.primary),
                          const SizedBox(width: AppTokens.s1),
                          Expanded(
                            child: Text(
                              tag.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _TagData {
  final String label;
  final IconData icon;
  final String route;

  const _TagData(this.label, this.icon, this.route);
}

class _PromoCardRow extends StatelessWidget {
  const _PromoCardRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 340;
        final cards = [
          Expanded(
            child: _PromoCard(
              title: 'Sell your\nsecond hand books',
              subtitle: 'Earn money and help others',
              cta: 'Upload books',
              route: '/sell',
              pushRoute: false,
              start: const Color(0xFFD8F7EA),
              end: const Color(0xFFA4E7C7),
              accent: AppTokens.success,
              image: 'assets/images/categories/books.jpg',
            ),
          ),
          SizedBox(
            width: stacked ? 0 : AppTokens.s3,
            height: stacked ? AppTokens.s3 : 0,
          ),
          Expanded(
            child: _PromoCard(
              title: 'Purchase\nsecond hand books',
              subtitle: 'Save more, read more',
              cta: 'Explore now',
              route: '/shop?cat=old-books',
              pushRoute: false,
              start: const Color(0xFFFFF0E1),
              end: const Color(0xFFFFD3A8),
              accent: const Color(0xFFF48A1D),
              image: 'assets/images/categories/notebook.jpg',
            ),
          ),
        ];

        return stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards)
            : Row(children: cards);
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final String route;
  final bool pushRoute;
  final Color start;
  final Color end;
  final Color accent;
  final String image;

  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
    required this.pushRoute,
    required this.start,
    required this.end,
    required this.accent,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: AppTokens.brLg,
      onTap: () {
        if (pushRoute) {
          context.push(route);
        } else {
          context.go(route);
        }
      },
      child: Container(
        height: 138 * AppTokens.scale,
        decoration: BoxDecoration(
          borderRadius: AppTokens.brLg,
          gradient: LinearGradient(colors: [start, end]),
          boxShadow: AppTokens.softShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -10,
              child: Container(
                width: 88 * AppTokens.scale,
                height: 88 * AppTokens.scale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: ClipRRect(
                borderRadius: AppTokens.brMd,
                child: Image.asset(
                  image,
                  width: 78 * AppTokens.scale,
                  height: 58 * AppTokens.scale,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: SizedBox(
                width: 132 * AppTokens.scale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTokens.primaryDark,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s1),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s3,
                        ),
                      ),
                      onPressed: () {
                        if (pushRoute) {
                          context.push(route);
                        } else {
                          context.go(route);
                        }
                      },
                      child: Text(cta),
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

class _ProductShelf extends StatelessWidget {
  final String title;
  final List<Listing> listings;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const _ProductShelf({
    required this.title,
    required this.listings,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: title,
          trailing: trailing,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        const SizedBox(height: AppTokens.s2),
        SizedBox(
          height: 225 * AppTokens.scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppTokens.s3),
            itemBuilder: (context, index) => SizedBox(
              width: 138 * AppTokens.scale,
              child: _HomeProductCard(listing: listings[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeProductCard extends ConsumerWidget {
  final Listing listing;

  const _HomeProductCard({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inCart = ref.watch(
      cartControllerProvider.select((cart) => cart.contains(listing.id)),
    );

    final discount = listing.hasDiscount && listing.originalPriceValue > 0
        ? (((listing.originalPriceValue - listing.priceValue) /
                    listing.originalPriceValue) *
                100)
            .round()
        : 0;

    return Material(
      color: Colors.white,
      borderRadius: AppTokens.brLg,
      elevation: 1,
      shadowColor: AppTokens.ink.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: AppTokens.brLg,
        onTap: () => context.push('/listing/${listing.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTokens.background,
                          borderRadius: AppTokens.brMd,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListingImage(listing: listing),
                      ),
                    ),
                    Positioned(
                      top: AppTokens.s1,
                      left: AppTokens.s1,
                      child: _ProductFlag(
                        text: discount > 0
                            ? '$discount% OFF'
                            : (listing.isFeatured ? 'Featured' : 'Popular'),
                        color: discount > 0 ? AppTokens.danger : AppTokens.gold,
                        textColor:
                            discount > 0 ? Colors.white : AppTokens.primaryDark,
                      ),
                    ),
                    Positioned(
                      top: AppTokens.s1,
                      right: AppTokens.s1,
                      child: FavoriteButton(
                        listingId: listing.id,
                        size: 30 * AppTokens.scale,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                listing.category?.name ??
                    listing.subject ??
                    conditionLabels[listing.condition] ??
                    'Student essential',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTokens.inkSoft,
                    ),
              ),
              const SizedBox(height: AppTokens.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.isBulk
                              ? 'from ${inr(listing.lowestUnitPrice)}/u'
                              : inr(listing.price),
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTokens.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (listing.hasDiscount && !listing.isBulk)
                          Text(
                            inr(listing.originalPrice),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTokens.inkSoft,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.s3,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () async {
                      if (inCart) {
                        context.go('/cart');
                        return;
                      }
                      try {
                        await ref.read(cartControllerProvider.notifier).add(listing);
                        if (context.mounted) {
                          showSuccess(context, 'Added to cart');
                        }
                      } catch (err) {
                        if (context.mounted) showError(context, err);
                      }
                    },
                    child: Text(inCart ? 'Cart' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductFlag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _ProductFlag({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeading({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s1,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTokens.s2),
                trailing!,
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTokens.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}

class _DealCountdown extends StatelessWidget {
  const _DealCountdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: AppTokens.brSm,
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Text(
        'Ends in 06:45:32',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTokens.danger,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _TrustSignals extends StatelessWidget {
  const _TrustSignals();

  static const _signals = [
    (
      Icons.local_shipping_outlined,
      'Free Delivery',
      'Above Rs 199',
      Color(0xFFE9F8F0),
    ),
    (
      Icons.shield_outlined,
      'Secure Payments',
      'Trusted checkout',
      Color(0xFFEEF3FF),
    ),
    (
      Icons.assignment_return_outlined,
      'Easy Returns',
      'Simple support',
      Color(0xFFFFF2E8),
    ),
    (
      Icons.workspace_premium_outlined,
      'Best Prices',
      'Student friendly',
      Color(0xFFFFF4F8),
    ),
    (
      Icons.school_outlined,
      'Student Discounts',
      'Offers every week',
      Color(0xFFF1F2FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: AppTokens.s3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.brLg,
        border: Border.all(color: AppTokens.tint.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _signals.length; i++) ...[
            Expanded(child: _TrustSignalCard(signal: _signals[i])),
            if (i != _signals.length - 1) const SizedBox(width: AppTokens.s2),
          ],
        ],
      ),
    );
  }
}

class _TrustSignalCard extends StatelessWidget {
  final (IconData, String, String, Color) signal;

  const _TrustSignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26 * AppTokens.scale,
          height: 26 * AppTokens.scale,
          decoration: BoxDecoration(
            color: signal.$4,
            borderRadius: AppTokens.brSm,
          ),
          child: Icon(signal.$1, color: AppTokens.success, size: 15),
        ),
        const SizedBox(height: AppTokens.s1),
        Text(
          signal.$2,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
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
            items.where((a) => !dismissed.contains(a.id)).take(2).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.s3),
          child: Column(
            children: visible
                .map(
                  (announcement) => Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.s2),
                    padding: const EdgeInsets.all(AppTokens.s3),
                    decoration: BoxDecoration(
                      color: switch (announcement.type) {
                        'warning' || 'maintenance' =>
                          AppTokens.warning.withValues(alpha: 0.12),
                        'success' => AppTokens.success.withValues(alpha: 0.12),
                        _ => AppTokens.tint.withValues(alpha: 0.45),
                      },
                      borderRadius: AppTokens.brMd,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          announcement.type == 'success'
                              ? Icons.check_circle_outline_rounded
                              : Icons.campaign_outlined,
                          color: AppTokens.primaryDark,
                          size: 18,
                        ),
                        const SizedBox(width: AppTokens.s2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                announcement.content,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTokens.inkSoft),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await ref
                                .read(localStoreProvider)
                                .dismissAnnouncement(announcement.id);
                            ref
                                    .read(dismissedAnnouncementsProvider.notifier)
                                    .state =
                                {...dismissed, announcement.id};
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTokens.brMd,
        border: Border.all(color: AppTokens.tint),
        boxShadow: AppTokens.softShadow,
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _submit,
        decoration: InputDecoration(
          hintText: 'Search books, notebooks, schools, classes...',
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppTokens.inkSoft),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none_rounded, color: AppTokens.inkSoft),
            onPressed: () => _submit(_controller.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3,
            vertical: AppTokens.s3,
          ),
        ),
      ),
    );
  }
}

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
                const Icon(
                  Icons.location_on_outlined,
                  color: AppTokens.success,
                  size: 18,
                ),
                const SizedBox(width: AppTokens.s1),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Deliver to: ',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTokens.inkSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: _city,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTokens.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTokens.inkSoft,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        Row(
          children: [
            const Icon(
              Icons.delivery_dining_rounded,
              color: AppTokens.success,
              size: 18,
            ),
            const SizedBox(width: AppTokens.s1),
            Text(
              'Delivery in 30 mins',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTokens.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
