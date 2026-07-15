import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/api/api_services.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/core/storage/token_store.dart';
import 'package:gyan_hub/features/home/home_screen.dart';
import 'package:gyan_hub/features/shop/categories_screen.dart';
import 'package:gyan_hub/features/shop/shop_screen.dart';
import 'package:gyan_hub/router.dart';
import 'package:gyan_hub/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Empty-but-successful APIs: enough to render Home and Shop with no network.
class _FakeListingsApi implements ListingsApi {
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
  }) async =>
      const Paginated<Listing>(data: [], pagination: Pagination.empty);

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
  testWidgets('Home "View All" opens the categories page, not search',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Tall enough that every category card is laid out (a lazy sliver only
    // builds what fits, and the assertions below check all of them).
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(TokenStore()),
        listingsApiProvider.overrideWithValue(_FakeListingsApi()),
        adsApiProvider.overrideWithValue(_FakeAdsApi()),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    // The whole point of the fix: a categories page, not the Shop/search tab.
    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.byType(ShopScreen), findsNothing);

    // Every category is listed, not just the ones that fit on the home strip.
    for (final category in shopCategories) {
      expect(find.text(category.label), findsOneWidget);
    }

    // Picking one hands off to the Shop tab.
    await tester.tap(find.text('Old Books'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsOneWidget);
  });
}
