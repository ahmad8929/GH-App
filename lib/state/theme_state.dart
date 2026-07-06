import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import 'auth_state.dart';
import 'providers.dart';

/// The signed-in user's selected [ThemeOption], re-fetched whenever auth
/// state changes (login/logout/restore) — mirrors the Website's
/// theme-context, which re-derives from the profile rather than local state
/// so the choice always follows the account, not the device.
final selectedThemeProvider = FutureProvider<ThemeOption?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isSignedIn) return null;
  try {
    final me = await ref.watch(profileApiProvider).me();
    return me.profile?.theme;
  } catch (_) {
    return null;
  }
});
