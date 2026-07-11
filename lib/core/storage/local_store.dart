import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Non-sensitive local persistence: guest cart snapshots and dismissed
/// announcement ids.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _guestCartKey = 'gh.guestCart';
  static const _dismissedKey = 'gh.dismissedAnnouncements';

  /// Guest cart lines as (listing, quantity). Reads both the current
  /// `{listing, quantity}` shape and the legacy plain-listing list (qty 1).
  List<(Listing, int)> readGuestCart() {
    final raw = _prefs.getString(_guestCartKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).whereType<Map<String, dynamic>>().map((e) {
        if (e['listing'] is Map<String, dynamic>) {
          return (
            Listing.fromJson(e['listing'] as Map<String, dynamic>),
            (e['quantity'] as num?)?.toInt() ?? 1,
          );
        }
        return (Listing.fromJson(e), 1); // legacy shape
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeGuestCart(List<(Listing, int)> lines) =>
      _prefs.setString(
          _guestCartKey,
          jsonEncode(lines
              .map((l) => {'listing': l.$1.toJson(), 'quantity': l.$2})
              .toList()));

  Future<void> clearGuestCart() async {
    await _prefs.remove(_guestCartKey);
  }

  Set<String> readDismissedAnnouncements() =>
      (_prefs.getStringList(_dismissedKey) ?? []).toSet();

  Future<void> dismissAnnouncement(String id) async {
    final current = readDismissedAnnouncements()..add(id);
    await _prefs.setStringList(_dismissedKey, current.take(50).toList());
  }
}
