// ignore_for_file: deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class WebNotificationBridge {
  static Future<String> requestPermission() async {
    if (!html.Notification.supported) {
      return 'unsupported';
    }

    return html.Notification.requestPermission();
  }

  static bool get isPermissionGranted {
    return html.Notification.supported &&
        html.Notification.permission == 'granted';
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!html.Notification.supported) {
      debugPrint('Notification API nao suportada neste navegador.');
      return;
    }

    var permission = html.Notification.permission;
    if (permission == 'default') {
      permission = await html.Notification.requestPermission();
    }

    if (permission != 'granted') {
      debugPrint('Permissao de notificacao Web nao concedida: $permission');
      return;
    }

    html.Notification(title, body: body, icon: 'icons/Icon-192.png');
  }
}
