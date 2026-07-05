import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import '../core/push/push_service.dart';
import 'providers.dart';

enum AuthStatus { restoring, guest, signedIn }

@immutable
class AuthState {
  final AuthStatus status;
  final AuthUser? user;

  const AuthState(this.status, this.user);

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState(AuthStatus.restoring, null)) {
    _ref.read(apiClientProvider).onSessionExpired = () {
      if (mounted) state = const AuthState(AuthStatus.guest, null);
    };
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final tokens = _ref.read(tokenStoreProvider);
    if (!tokens.hasSession) {
      state = const AuthState(AuthStatus.guest, null);
      return;
    }
    try {
      final user = await _ref.read(authApiProvider).me();
      state = AuthState(AuthStatus.signedIn, user);
      _afterSignIn();
    } catch (_) {
      // api client already tried a refresh; session is dead
      await tokens.clear();
      state = const AuthState(AuthStatus.guest, null);
    }
  }

  Future<AuthUser> login(String email, String password) async {
    final session = await _ref.read(authApiProvider).login(email, password);
    await _ref
        .read(tokenStoreProvider)
        .save(access: session.accessToken, refresh: session.refreshToken);
    state = AuthState(AuthStatus.signedIn, session.user);
    _afterSignIn();
    return session.user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String userType,
  }) async {
    final session = await _ref.read(authApiProvider).register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        userType: userType);
    await _ref
        .read(tokenStoreProvider)
        .save(access: session.accessToken, refresh: session.refreshToken);
    state = AuthState(AuthStatus.signedIn, session.user);
    _afterSignIn();
    return session.user;
  }

  Future<void> refreshUser() async {
    try {
      final user = await _ref.read(authApiProvider).me();
      state = AuthState(AuthStatus.signedIn, user);
    } catch (_) {
      // keep current state
    }
  }

  Future<void> logout() async {
    await _ref.read(tokenStoreProvider).clear();
    state = const AuthState(AuthStatus.guest, null);
  }

  /// Best-effort post-login hooks: FCM device registration.
  void _afterSignIn() {
    Future(() async {
      final token = await PushService.deviceToken();
      if (token != null) {
        try {
          await _ref
              .read(notificationsApiProvider)
              .registerDevice(token, PushService.platform);
        } catch (_) {
          // push registration must never block sign-in
        }
      }
    });
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(AuthController.new);
