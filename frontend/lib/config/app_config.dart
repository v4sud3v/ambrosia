class AppConfig {
  static const backendBaseUrl = String.fromEnvironment(
    'AMBROSIA_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
