import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the JWT pair. The backend rotates refresh tokens,
/// so both values are replaced together on every refresh.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'gh.access';
  static const _refreshKey = 'gh.refresh';

  String? _access;
  String? _refresh;

  String? get access => _access;
  String? get refresh => _refresh;
  bool get hasSession => _refresh != null;

  Future<void> load() async {
    _access = await _storage.read(key: _accessKey);
    _refresh = await _storage.read(key: _refreshKey);
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
