/// App-wide configuration.
///
/// The API base URL is injected with `--dart-define=API_URL=...`.
/// Default targets the Android emulator's alias for the host machine
/// (the backend runs on the host at :5000).
class AppConfig {
  AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
}
