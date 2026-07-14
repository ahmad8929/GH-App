import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyan_hub/core/api/api_services.dart';
import 'package:gyan_hub/core/models/models.dart';
import 'package:gyan_hub/core/storage/token_store.dart';
import 'package:gyan_hub/router.dart';
import 'package:gyan_hub/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Empty-but-successful APIs: enough to render Home and Categories with no
// network (mirrors the fakes in categories_nav_test.dart).
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
  testWidgets(
      '"Gyaan Hub" renders ~20% bigger than an equivalent default AppBar title',
      (tester) async {
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

    final brandSize = tester.getSize(find.text('Gyaan Hub'));

    // Categories' AppBar title uses plain default title styling — the same
    // styling "Gyaan Hub" had before this change — so it's the "no brand
    // scaling" baseline. Scope to the AppBar since the same words also show
    // up as Home's (unrelated, differently-styled) section header.
    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();
    final baselineSize = tester.getSize(find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Shop by category'),
    ));

    // Height is purely a function of font size + line-height metrics for a
    // single line of one font/weight, so comparing it sidesteps having to
    // measure glyph widths across two different strings.
    final ratio = brandSize.height / baselineSize.height;
    expect(ratio, closeTo(1.2, 0.05));
  });
}
