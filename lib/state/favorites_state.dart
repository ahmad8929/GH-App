import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'providers.dart';

/// Set of favorited listing ids for the signed-in user (empty for guests).
class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._ref) : super(const {});

  final Ref _ref;

  Future<void> onAuthChanged() async {
    final auth = _ref.read(authControllerProvider);
    if (!auth.isSignedIn) {
      state = const {};
      return;
    }
    try {
      final res = await _ref.read(favoritesApiProvider).list(limit: 100);
      state = res.data.map((favorite) => favorite.listingId).toSet();
    } catch (_) {
      state = const {};
    }
  }

  /// Returns true when the listing is now favorited. Throws for guests —
  /// callers should route to login instead.
  Future<bool> toggle(String listingId) async {
    final favorited = await _ref.read(favoritesApiProvider).toggle(listingId);
    final next = {...state};
    favorited ? next.add(listingId) : next.remove(listingId);
    state = next;
    return favorited;
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, Set<String>>((ref) {
  final controller = FavoritesController(ref);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous?.status != next.status ||
        previous?.user?.id != next.user?.id) {
      controller.onAuthChanged();
    }
  }, fireImmediately: true);
  return controller;
});
