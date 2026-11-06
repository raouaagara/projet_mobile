/// Build-time configuration.
///
/// Every backend call goes through the API Gateway (port 8085).
///
/// The default `localhost:8085` works on a USB phone AND on the emulator once
/// the device's port 8085 is forwarded to your PC (redo it after each reconnect):
///   adb reverse tcp:8085 tcp:8085
/// It doesn't depend on Wi-Fi or on your PC's IP. To use another server:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8085
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8085',
  );

  /// SockJS endpoints (chat + support) are also served through the gateway.
  static const chatSocketUrl = '$apiBaseUrl/ws';
  static const supportSocketUrl = '$apiBaseUrl/ws-support';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);
}
