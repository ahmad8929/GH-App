import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/api/api_services.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/features/shop/shop_screen.dart';
import 'package:gyan_hub/state/providers.dart';

// Records the searches it's asked for and returns an empty page — enough to
// drive ShopScreen without any network.
class _FakeListingsApi implements ListingsApi {
  final List<String> searches = [];

  @override
  Future<Paginated<Listing>> list({
    String? search,
    String? categoryId,
    String? listingType,
    String? condition,
    String? city,
    num? minPrice,
    num? maxPrice,
    String sort = 'newest',
    int page = 1,
    int limit = 12,
  }) async {
    searches.add(search ?? '');
    return const Paginated<Listing>(data: [], pagination: Pagination.empty);
  }

  @override
  Future<Listing> byId(String id) => throw UnimplementedError();
}

class _FakeAdsApi implements AdsApi {
  @override
  Future<List<AdCreative>> serve(String placement) async => const [];
  @override
  Future<void> impression(String id) async {}
  @override
  Future<void> click(String id) async {}
}

void main() {
  testWidgets('re-searching from Home updates the Shop query & field',
      (tester) async {
    final listings = _FakeListingsApi();

    Widget host(String query) => ProviderScope(
          overrides: [
            listingsApiProvider.overrideWithValue(listings),
            adsApiProvider.overrideWithValue(_FakeAdsApi()),
          ],
          // Same key at the same position → the second pump reuses the
          // ShopScreen State (didUpdateWidget), exactly like the go_router
          // StatefulShellRoute branch does when Home re-navigates to /shop?q=.
          child: MaterialApp(
            home: ShopScreen(key: const ValueKey('shop'), initialSearch: query),
          ),
        );

    // First search from Home: "pen".
    await tester.pumpWidget(host('pen'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'pen');

    // Second search from Home while the Shop tab is still alive: "pencil".
    await tester.pumpWidget(host('pencil'));
    await tester.pump(const Duration(milliseconds: 50));

    // The field must now show the new query, not the stale one...
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'pencil');
    // ...and the reload must actually query for "pencil".
    expect(listings.searches, contains('pencil'));
  });
}
