import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/providers.dart';

/// Ad slot: fetches the creatives for a placement and shows them as a swipeable
/// carousel (swipe left/right to change; the dots track the position).
///
/// Two kinds of creative share the rotation, told apart by their target:
///   - House ads — ours — carry an in-app route ("/sell", "/notebook"), open
///     inside the app, and are labelled "FROM GYAN HUB".
///   - Paid ads carry an external URL, open in the browser, and say "SPONSORED".
///
/// Impressions follow what the reader actually sees: an ad is counted when its
/// page comes into view, once per ad. Renders nothing when there are no ads.
class AdBanner extends ConsumerStatefulWidget {
  final String placement;

  const AdBanner({super.key, required this.placement});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  static const _maxAds = 6;

  final _controller = PageController();
  final _reported = <String>{};
  List<AdCreative> _ads = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ads = await ref.read(adsApiProvider).serve(widget.placement);
    if (!mounted) return;
    setState(() => _ads = ads.take(_maxAds).toList());
    _report(0);
  }

  void _report(int index) {
    if (index < 0 || index >= _ads.length) return;
    final ad = _ads[index];
    if (_reported.add(ad.id)) {
      ref.read(adsApiProvider).impression(ad.id);
    }
  }

  static bool _isHouseAd(AdCreative ad) => ad.targetUrl.startsWith('/');

  void _open(AdCreative ad) {
    ref.read(adsApiProvider).click(ad.id);
    if (_isHouseAd(ad)) {
      context.push(ad.targetUrl);
      return;
    }
    final url = Uri.tryParse(ad.targetUrl);
    if (url != null && url.hasScheme) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final current = _ads[_index.clamp(0, _ads.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isHouseAd(current) ? 'FROM GYAN HUB' : 'SPONSORED',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppTokens.s1),
        SizedBox(
          height: 110 * AppTokens.scale,
          child: PageView.builder(
            controller: _controller,
            itemCount: _ads.length,
            onPageChanged: (index) {
              setState(() => _index = index);
              _report(index);
            },
            itemBuilder: (context, index) {
              final ad = _ads[index];
              return ClipRRect(
                borderRadius: AppTokens.brMd,
                child: GestureDetector(
                  onTap: () => _open(ad),
                  child: CachedNetworkImage(
                    imageUrl: ad.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ),
        if (_ads.length > 1) ...[
          const SizedBox(height: AppTokens.s2),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_ads.length, (index) {
                final selected = index == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: (selected ? 18 : 6) * AppTokens.scale,
                  height: 6 * AppTokens.scale,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTokens.ink
                        : AppTokens.ink.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                );
              }),
            ),
          ),
        ],
        const SizedBox(height: AppTokens.s2),
      ],
    );
  }
}
