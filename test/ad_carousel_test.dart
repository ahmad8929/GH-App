import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/api/api_services.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/shared/widgets/ad_banner.dart';
import 'package:gyan_hub/state/providers.dart';

class _FakeAdsApi implements AdsApi {
  final List<AdCreative> ads;
  final List<String> impressions = [];
  final List<String> clicks = [];

  _FakeAdsApi(this.ads);

  @override
  Future<List<AdCreative>> serve(String placement) async => ads;

  @override
  Future<void> impression(String id) async => impressions.add(id);

  @override
  Future<void> click(String id) async => clicks.add(id);
}

// Two house ads (in-app routes) plus one paid ad (external URL) — the mix the
// home carousel actually serves.
final _ads = [
  const AdCreative(id: 'a1', image: 'https://cdn/a1.png', targetUrl: '/sell'),
  const AdCreative(id: 'a2', image: 'https://cdn/a2.png', targetUrl: '/notebook'),
  const AdCreative(
      id: 'a3', image: 'https://cdn/a3.png', targetUrl: 'https://example.com/x'),
];

Future<_FakeAdsApi> _pumpBanner(WidgetTester tester) async {
  final api = _FakeAdsApi(_ads);
  await tester.pumpWidget(ProviderScope(
    overrides: [adsApiProvider.overrideWithValue(api)],
    child: const MaterialApp(
      home: Scaffold(body: AdBanner(placement: 'home_top')),
    ),
  ));
  await tester.pump(); // let the serve() future resolve
  return api;
}

void main() {
  testWidgets('carousel swipes between ads and tracks the visible one',
      (tester) async {
    final api = await _pumpBanner(tester);

    // Only the ad on screen is counted, not all three.
    expect(api.impressions, ['a1']);
    // A house ad is showing, so the slot must not claim it's paid for.
    expect(find.text('FROM GYAN HUB'), findsOneWidget);
    expect(find.text('SPONSORED'), findsNothing);
    // One dot per ad.
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    // Swipe left → second ad.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(api.impressions, ['a1', 'a2']);

    // Swipe left again → the paid ad, which relabels the slot.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(api.impressions, ['a1', 'a2', 'a3']);
    expect(find.text('SPONSORED'), findsOneWidget);
    expect(find.text('FROM GYAN HUB'), findsNothing);

    // Swipe back right → already-seen ad is not double-counted.
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(api.impressions, ['a1', 'a2', 'a3']);
  });

  testWidgets('a single ad renders without dots', (tester) async {
    final api = _FakeAdsApi([_ads.first]);
    await tester.pumpWidget(ProviderScope(
      overrides: [adsApiProvider.overrideWithValue(api)],
      child: const MaterialApp(
        home: Scaffold(body: AdBanner(placement: 'home_top')),
      ),
    ));
    await tester.pump();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
  });
}
