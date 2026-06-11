class WebNotificationBridge {
  static Future<String> requestPermission() async => 'unsupported';

  static bool get isPermissionGranted => false;

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {}
}
