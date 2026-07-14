import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/api/api_services.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/core/storage/token_store.dart';
import 'package:gyan_hub/features/cart/cart_screen.dart';
import 'package:gyan_hub/features/home/home_screen.dart';
import 'package:gyan_hub/router.dart';
import 'package:gyan_hub/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Empty-but-successful APIs: enough to render Home and Cart with no network
// (mirrors the fakes in categories_nav_test.dart).
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

class _FakeBlogsApi implements BlogsApi {
  @override
  Future<Paginated<BlogPost>> list({int page = 1}) async =>
      const Paginated<BlogPost>(data: [], pagination: Pagination.empty);

  @override
  Future<BlogPost> bySlug(String slug) => throw UnimplementedError();
}

void main() {
  testWidgets('Home\'s cart icon opens the Cart tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(TokenStore()),
        listingsApiProvider.overrideWithValue(_FakeListingsApi()),
        adsApiProvider.overrideWithValue(_FakeAdsApi()),
        blogsApiProvider.overrideWithValue(_FakeBlogsApi()),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Scoped to the AppBar: the bottom nav's Cart destination uses the same
    // icon for its unselected state, so an unscoped lookup would be ambiguous.
    final cartIcon = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.shopping_cart_outlined),
    );
    expect(cartIcon, findsOneWidget);

    await tester.tap(cartIcon);
    await tester.pumpAndSettle();

    // Switches to the existing Cart tab rather than opening a second copy.
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
