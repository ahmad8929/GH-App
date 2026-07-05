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

  List<Listing> readGuestCart() {
    final raw = _prefs.getString(_guestCartKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeGuestCart(List<Listing> listings) => _prefs.setString(
      _guestCartKey, jsonEncode(listings.map((l) => l.toJson()).toList()));

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
