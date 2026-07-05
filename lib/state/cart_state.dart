import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/models/models.dart';
import 'auth_state.dart';
import 'providers.dart';

/// One line per unique listing — the backend cart has no quantity column.
@immutable
class CartLine {
  final String? serverId; // null for guest (local) lines
  final Listing listing;
  const CartLine({this.serverId, required this.listing});
}

@immutable
class CartState {
  final List<CartLine> lines;
  final bool loading;
  final CouponValidation? coupon;

  const CartState({
    this.lines = const [],
    this.loading = true,
    this.coupon,
  });

  double get subtotal =>
      lines.fold(0, (sum, line) => sum + line.listing.priceValue);
  double get total => coupon?.finalAmount ?? subtotal;
  int get count => lines.length;

  bool contains(String listingId) =>
      lines.any((line) => line.listing.id == listingId);

  CartState copyWith({
    List<CartLine>? lines,
    bool? loading,
    CouponValidation? coupon,
    bool clearCoupon = false,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        loading: loading ?? this.loading,
        coupon: clearCoupon ? null : (coupon ?? this.coupon),
      );
}

class CartController extends StateNotifier<CartState> {
  CartController(this._ref) : super(const CartState());

  final Ref _ref;
  String? _mergedForUser;

  bool get _signedIn => _ref.read(authControllerProvider).isSignedIn;

  /// Called whenever auth state settles/changes.
  Future<void> onAuthChanged() async {
    final auth = _ref.read(authControllerProvider);
    if (auth.status == AuthStatus.restoring) return;
    state = state.copyWith(loading: true, clearCoupon: true);
    try {
      if (auth.isSignedIn) {
        await _mergeGuestCart(auth.user!.id);
        await _loadServer();
      } else {
        _mergedForUser = null;
        _loadGuest();
      }
    } catch (_) {
      state = state.copyWith(lines: [], loading: false);
    }
  }

  Future<void> _mergeGuestCart(String userId) async {
    final local = _ref.read(localStoreProvider);
    final guest = local.readGuestCart();
    if (guest.isEmpty || _mergedForUser == userId) return;
    _mergedForUser = userId;
    for (final listing in guest) {
      try {
        await _ref.read(cartApiProvider).add(listing.id);
      } on ApiException {
        // already in cart / sold / own listing — skip quietly
      }
    }
    await local.clearGuestCart();
  }

  Future<void> _loadServer() async {
    final items = await _ref.read(cartApiProvider).get();
    state = state.copyWith(
      lines: items
          .map((item) => CartLine(serverId: item.id, listing: item.listing))
          .toList(),
      loading: false,
    );
  }

  void _loadGuest() {
    final guest = _ref.read(localStoreProvider).readGuestCart();
    state = state.copyWith(
      lines: guest.map((listing) => CartLine(listing: listing)).toList(),
      loading: false,
    );
  }

  Future<void> add(Listing listing) async {
    state = state.copyWith(clearCoupon: true);
    if (_signedIn) {
      try {
        await _ref.read(cartApiProvider).add(listing.id);
      } on ApiException catch (err) {
        if (err.statusCode != 409) rethrow; // already in cart is fine
      }
      await _loadServer();
    } else {
      final local = _ref.read(localStoreProvider);
      final guest = local.readGuestCart();
      if (!guest.any((item) => item.id == listing.id)) {
        await local.writeGuestCart([...guest, listing]);
      }
      _loadGuest();
    }
  }

  Future<void> remove(CartLine line) async {
    state = state.copyWith(clearCoupon: true);
    if (line.serverId != null) {
      await _ref.read(cartApiProvider).removeItem(line.serverId!);
      await _loadServer();
    } else {
      final local = _ref.read(localStoreProvider);
      final guest = local.readGuestCart()
        ..removeWhere((item) => item.id == line.listing.id);
      await local.writeGuestCart(guest);
      _loadGuest();
    }
  }

  Future<void> clear() async {
    state = state.copyWith(clearCoupon: true);
    if (_signedIn) {
      await _ref.read(cartApiProvider).clear();
      await _loadServer();
    } else {
      await _ref.read(localStoreProvider).clearGuestCart();
      _loadGuest();
    }
  }

  Future<CouponValidation> applyCoupon(String code) async {
    final result = await _ref.read(couponsApiProvider).validate(code);
    state = state.copyWith(coupon: result);
    return result;
  }

  void clearCoupon() => state = state.copyWith(clearCoupon: true);

  /// Refresh after checkout (server cart was consumed).
  Future<void> reload() => onAuthChanged();
}

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  final controller = CartController(ref);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous?.status != next.status ||
        previous?.user?.id != next.user?.id) {
      controller.onAuthChanged();
    }
  }, fireImmediately: true);
  return controller;
});
