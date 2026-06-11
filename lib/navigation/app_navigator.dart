import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void abrirCentralNotificacoesGlobal() {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    Future<void>.delayed(
      const Duration(milliseconds: 350),
      abrirCentralNotificacoesGlobal,
    );
    return;
  }

  navigator.pushNamed('/notificacoes');
}
