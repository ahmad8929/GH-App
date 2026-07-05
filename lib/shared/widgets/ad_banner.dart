import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_tokens.dart';
import '../../state/providers.dart';

/// Ad slot: fetches creatives for a placement, fires an impression once per
/// creative, and reports clicks. Renders nothing when there are no ads.
class AdBanner extends ConsumerStatefulWidget {
  final String placement;

  const AdBanner({super.key, required this.placement});

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  List<AdCreative> _ads = const [];
  final _reported = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ads = await ref.read(adsApiProvider).serve(widget.placement);
    if (!mounted) return;
    setState(() => _ads = ads.take(3).toList());
    for (final ad in _ads) {
      if (_reported.add(ad.id)) {
        ref.read(adsApiProvider).impression(ad.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SPONSORED',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: AppTokens.s1),
        ..._ads.map((ad) => Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s2),
              child: ClipRRect(
                borderRadius: AppTokens.brMd,
                child: GestureDetector(
                  onTap: () {
                    ref.read(adsApiProvider).click(ad.id);
                    final url = Uri.tryParse(ad.targetUrl);
                    if (url != null && url.hasScheme) {
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: ad.image,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}
