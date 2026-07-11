import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_services.dart';
import '../core/models/models.dart';
import '../core/storage/local_store.dart';
import '../core/storage/token_store.dart';

/// Overridden in main() with real instances created before runApp.
final sharedPrefsProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());
final tokenStoreProvider =
    Provider<TokenStore>((ref) => throw UnimplementedError());

final localStoreProvider =
    Provider<LocalStore>((ref) => LocalStore(ref.watch(sharedPrefsProvider)));

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(tokenStoreProvider)));

final authApiProvider = Provider((ref) => AuthApi(ref.watch(apiClientProvider)));
final profileApiProvider =
    Provider((ref) => ProfileApi(ref.watch(apiClientProvider)));
final listingsApiProvider =
    Provider((ref) => ListingsApi(ref.watch(apiClientProvider)));
final cartApiProvider = Provider((ref) => CartApi(ref.watch(apiClientProvider)));
final couponsApiProvider =
    Provider((ref) => CouponsApi(ref.watch(apiClientProvider)));
final ordersApiProvider =
    Provider((ref) => OrdersApi(ref.watch(apiClientProvider)));
final favoritesApiProvider =
    Provider((ref) => FavoritesApi(ref.watch(apiClientProvider)));
final sellbackApiProvider =
    Provider((ref) => SellbackApi(ref.watch(apiClientProvider)));
final adsApiProvider = Provider((ref) => AdsApi(ref.watch(apiClientProvider)));
final advertiseApiProvider =
    Provider((ref) => AdvertiseApi(ref.watch(apiClientProvider)));
final themesApiProvider =
    Provider((ref) => ThemesApi(ref.watch(apiClientProvider)));
final blogsApiProvider =
    Provider((ref) => BlogsApi(ref.watch(apiClientProvider)));
final notebooksApiProvider =
    Provider((ref) => NotebooksApi(ref.watch(apiClientProvider)));
final announcementsApiProvider =
    Provider((ref) => AnnouncementsApi(ref.watch(apiClientProvider)));
final notificationsApiProvider =
    Provider((ref) => NotificationsApi(ref.watch(apiClientProvider)));

/// The fixed shop category set. Real categoryIds are resolved by scanning the
/// `category` refs embedded in listings (there is no public categories API).
class ShopCategory {
  final String slug;
  final String label;
  final String emoji;
  final List<String> hints;
  const ShopCategory(this.slug, this.label, this.emoji, this.hints);
}

const shopCategories = <ShopCategory>[
  ShopCategory('old-books', 'Old Books', '📚', ['old-book', 'old book', 'used book']),
  ShopCategory('new-books', 'New Books', '📖', ['new-book', 'new book']),
  ShopCategory('uniforms', 'Uniforms', '👕', ['uniform']),
  ShopCategory('stationery', 'Stationery', '✏️', ['stationery', 'stationary']),
  ShopCategory('corporate', 'Corporate Bulk', '🏢', ['corporate', 'bulk']),
  ShopCategory('custom-notebooks', 'Custom Notebook', '📒', ['custom', 'notebook']),
];

final categoryOptionsProvider = FutureProvider<List<CategoryRef>>((ref) async {
  final res = await ref.watch(listingsApiProvider).list(limit: 100);
  final map = <String, CategoryRef>{};
  for (final listing in res.data) {
    final category = listing.category;
    if (category != null) map[category.id] = category;
  }
  final options = map.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return options;
});

CategoryRef? matchCategory(List<CategoryRef> options, ShopCategory shop) {
  for (final option in options) {
    final haystack = '${option.slug ?? ''} ${option.name}'.toLowerCase();
    if (haystack.contains(shop.slug) ||
        shop.hints.any((hint) => haystack.contains(hint))) {
      return option;
    }
  }
  return null;
}
