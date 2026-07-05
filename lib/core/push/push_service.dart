import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Optional Firebase push. There is no google-services.json / Firebase project
/// configured yet, so initialization is best-effort: when it fails the app
/// simply runs without push — the in-app notification center still works via
/// GET /notifications.
class PushService {
  PushService._();

  static bool _available = false;
  static bool get available => _available;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (err) {
      _available = false;
      debugPrint('Push disabled (no Firebase configured): $err');
    }
  }

  /// FCM device token, or null when Firebase isn't configured.
  static Future<String?> deviceToken() async {
    if (!_available) return null;
    try {
      await FirebaseMessaging.instance.requestPermission();
      return await FirebaseMessaging.instance.getToken();
    } catch (err) {
      debugPrint('Could not fetch FCM token: $err');
      return null;
    }
  }

  static String get platform {
    if (kIsWeb) return 'web';
    try {
      return Platform.isIOS ? 'ios' : 'android';
    } catch (_) {
      return 'android';
    }
  }
}
