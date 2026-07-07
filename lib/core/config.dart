/// App-wide configuration.
///
/// The API base URL is injected with `--dart-define=API_URL=...`.
/// Default targets the deployed Backend (Render) so a plain
/// `flutter build apk` works out of the box on a real device. For local
/// emulator testing against a backend running on your own machine, pass
/// `--dart-define=API_URL=http://10.0.2.2:5000/api` instead (10.0.2.2 is
/// the Android emulator's alias for the host machine).
class AppConfig {
  AppConfig._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://gh-backend-piba.onrender.com/api',
  );
}
