import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/firebase_config.dart';
import '../config/firebase_web_push_config.dart';
import '../models/notificacao_interna.dart';
import '../navigation/app_navigator.dart';
import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_browser.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await inicializarFirebaseTaskLedger();
  debugPrint(
    'FCM background TaskLedger: ${message.messageId ?? message.sentTime}',
  );
}

class NotificacaoService {
  NotificacaoService._();

  static final NotificacaoService instance = NotificacaoService._();

  static const String canalAndroidId = 'taskledger_alertas';
  static const String canalAndroidNome = 'Alertas TaskLedger';
  static const String canalAndroidDescricao =
      'Notificacoes de promocoes, atualizacoes e avisos internos do TaskLedger';
  static const String topicoPromocoes = 'promocoes';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;
  bool _listenersConfigurados = false;
  bool _inicializacaoConcluida = false;

  bool get inicializacaoConcluida => _inicializacaoConcluida;

  Future<void> inicializar() async {
    if (_inicializado) {
      return;
    }

    _inicializado = true;
    if (kIsWeb) {
      await inicializarWebNotifications();
    } else {
      await inicializarAndroidNotifications();
      await solicitarPermissao();
      await _registrarTokenFcm();
      await _inscreverTopicoPromocoes();
    }

    _configurarListeners();
    await _tratarMensagemInicial();
    await verificarNotificacoesInternasPendentes();
    _inicializacaoConcluida = true;
  }

  Future<void> inicializarWebNotifications() async {
    final permission = await WebNotificationBridge.requestPermission();
    debugPrint('Permissao de notificacao Web TaskLedger: $permission');

    await solicitarPermissao();
    await _registrarTokenFcm();
    await _inscreverTopicoPromocoes();
  }

  Future<NotificationSettings?> solicitarPermissao() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }

      return settings;
    } catch (erro) {
      debugPrint('Erro ao solicitar permissao de notificacao: $erro');
      return null;
    }
  }

  Future<void> _registrarTokenFcm() async {
    try {
      if (kIsWeb && !FirebaseWebPushConfig.configurada) {
        debugPrint(
          'VAPID Key Web nao configurada. Preencha '
          'FirebaseWebPushConfig.publicVapidKey em lib/config/firebase_web_push_config.dart '
          'ou rode com --dart-define=TASKLEDGER_FIREBASE_WEB_VAPID_KEY=SUA_CHAVE.',
        );
        return;
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? FirebaseWebPushConfig.vapidKey : null,
      );
      debugPrint(
        kIsWeb
            ? 'Token FCM Web TaskLedger: $token'
            : 'Token FCM TaskLedger: $token',
      );
    } catch (erro) {
      debugPrint('Nao foi possivel obter o token FCM: $erro');
    }
  }

  Future<void> _inscreverTopicoPromocoes() async {
    if (kIsWeb) {
      debugPrint(
        'Topicos FCM nao sao suportados diretamente no client Web. '
        'Para Web, associe o token ao topico "$topicoPromocoes" via backend ou Cloud Functions.',
      );
      return;
    }

    try {
      await _messaging.subscribeToTopic(topicoPromocoes);
      debugPrint('Inscrito no topico FCM: $topicoPromocoes');
    } catch (erro) {
      debugPrint(
        'Nao foi possivel inscrever no topico $topicoPromocoes: $erro',
      );
    }
  }

  Future<void> inicializarAndroidNotifications() async {
    if (kIsWeb) {
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _abrirDestinoDaNotificacao(payload: response.payload);
      },
    );

    const canal = AndroidNotificationChannel(
      canalAndroidId,
      canalAndroidNome,
      description: canalAndroidDescricao,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(canal);

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _abrirDestinoDaNotificacao(
        payload: launchDetails?.notificationResponse?.payload,
      );
    }
  }

  void _configurarListeners() {
    if (_listenersConfigurados) {
      return;
    }

    _listenersConfigurados = true;

    FirebaseMessaging.onMessage.listen((message) async {
      await _salvarRemoteMessageComoInterna(message);
      await mostrarNotificacaoLocal(
        titulo: _tituloDaMensagem(message),
        mensagem: _corpoDaMensagem(message),
        payload: _payloadDaMensagem(message),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _salvarRemoteMessageComoInterna(message);
      _abrirDestinoDaNotificacao(remoteMessage: message);
    });
  }

  Future<void> _tratarMensagemInicial() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) {
        return;
      }

      await _salvarRemoteMessageComoInterna(message);
      _abrirDestinoDaNotificacao(remoteMessage: message);
    } catch (erro) {
      debugPrint('Erro ao tratar mensagem inicial FCM: $erro');
    }
  }

  CollectionReference<Map<String, dynamic>>? _colecaoUsuario([String? uid]) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificacoes');
  }

  Stream<List<NotificacaoInterna>> observarNotificacoes({String? uid}) {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return const Stream<List<NotificacaoInterna>>.empty();
    }

    return colecao
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificacaoInterna.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<NotificacaoInterna>> observarNaoVisualizadas({String? uid}) {
    return observarNotificacoes(uid: uid).map(
      (notificacoes) => notificacoes
          .where((notificacao) => !notificacao.visualizada)
          .toList(),
    );
  }

  Future<List<NotificacaoInterna>> buscarNaoVisualizadas({String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return <NotificacaoInterna>[];
    }

    final snapshot = await colecao.orderBy('criadoEm', descending: true).get();

    return snapshot.docs
        .map(NotificacaoInterna.fromFirestore)
        .where((notificacao) => !notificacao.visualizada)
        .toList();
  }

  Future<List<NotificacaoInterna>> buscarNotificacoes({String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return <NotificacaoInterna>[];
    }

    final snapshot = await colecao.orderBy('criadoEm', descending: true).get();

    return snapshot.docs.map(NotificacaoInterna.fromFirestore).toList();
  }

  Future<void> marcarComoVisualizada(String id, {String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    await colecao.doc(id).update({'visualizada': true});
  }

  Future<void> marcarTodasComoVisualizadas({String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    final snapshot = await colecao.where('visualizada', isEqualTo: false).get();
    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {'visualizada': true});
    }

    await batch.commit();
  }

  Future<void> excluirNotificacao(String id, {String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    await colecao.doc(id).delete();
  }

  Future<void> excluirTodasNotificacoes({String? uid}) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    final snapshot = await colecao.get();
    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  Future<void> marcarNotificacaoLocalComoEnviada(
    String id, {
    String? uid,
  }) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    await colecao.doc(id).update({'notificacaoLocalEnviada': true});
  }

  Future<void> salvarNotificacaoInterna({
    String? id,
    required String titulo,
    required String mensagem,
    String? rota,
    Map<String, dynamic>? dados,
    bool? visualizada,
    String? uid,
  }) async {
    final colecao = _colecaoUsuario(uid);
    if (colecao == null) {
      return;
    }

    final dadosLimpos = dados == null ? null : Map<String, dynamic>.from(dados);
    final payload = <String, dynamic>{
      'titulo': titulo,
      'mensagem': mensagem,
      'rota': rota,
      'dados': dadosLimpos,
    };

    if (id == null || id.trim().isEmpty) {
      await colecao.add({
        ...payload,
        'visualizada': visualizada ?? false,
        'criadoEm': FieldValue.serverTimestamp(),
        'notificacaoLocalEnviada': false,
      });
      return;
    }

    final referencia = colecao.doc(id);
    final document = await referencia.get();

    if (!document.exists) {
      await referencia.set({
        ...payload,
        'visualizada': visualizada ?? false,
        'criadoEm': FieldValue.serverTimestamp(),
        'notificacaoLocalEnviada': false,
      });
      return;
    }

    if (visualizada == true) {
      payload['visualizada'] = true;
    }

    await referencia.set(payload, SetOptions(merge: true));
  }

  Future<void> criarNotificacaoExemplo({String? uid}) {
    return salvarNotificacaoInterna(
      titulo: 'Cupom disponivel',
      mensagem: 'Use TASK10 no Orcamento de Compras.',
      rota: '/orcamento-compras',
      dados: const {'tela': 'orcamento_compras', 'cupom': 'TASK10'},
      uid: uid,
    );
  }

  Future<void> verificarNotificacoesInternasPendentes() async {
    try {
      final notificacoes = await buscarNaoVisualizadas();
      final pendentes = notificacoes
          .where((notificacao) => !notificacao.notificacaoLocalEnviada)
          .toList();

      if (pendentes.isEmpty) {
        return;
      }

      if (pendentes.length == 1) {
        final notificacao = pendentes.first;
        await mostrarNotificacaoLocal(
          titulo: 'Voce tem uma nova notificacao',
          mensagem: notificacao.titulo.isNotEmpty
              ? notificacao.titulo
              : notificacao.mensagem,
          payload: jsonEncode({'rota': '/notificacoes'}),
        );
      } else {
        await mostrarNotificacaoLocal(
          titulo: 'Voce tem notificacoes nao visualizadas',
          mensagem:
              'Existem ${pendentes.length} notificacoes pendentes no TaskLedger.',
          payload: jsonEncode({'rota': '/notificacoes'}),
        );
      }

      for (final notificacao in pendentes) {
        await marcarNotificacaoLocalComoEnviada(notificacao.id);
      }
    } catch (erro) {
      debugPrint('Erro ao verificar notificacoes internas pendentes: $erro');
    }
  }

  Future<void> mostrarNotificacaoLocal({
    required String titulo,
    required String mensagem,
    String? payload,
  }) async {
    if (titulo.trim().isEmpty && mensagem.trim().isEmpty) {
      return;
    }

    if (kIsWeb) {
      await mostrarNotificacaoWeb(titulo: titulo, mensagem: mensagem);
      return;
    }

    const android = AndroidNotificationDetails(
      canalAndroidId,
      canalAndroidNome,
      channelDescription: canalAndroidDescricao,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: darwin);

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _localNotifications.show(
      id: id,
      title: titulo,
      body: mensagem,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> mostrarNotificacaoWeb({
    required String titulo,
    required String mensagem,
  }) async {
    if (!kIsWeb) {
      return;
    }

    await WebNotificationBridge.showNotification(title: titulo, body: mensagem);
  }

  Future<void> exibirNotificacaoLocal({
    required String titulo,
    required String mensagem,
    String? payload,
  }) {
    return mostrarNotificacaoLocal(
      titulo: titulo,
      mensagem: mensagem,
      payload: payload,
    );
  }

  Future<void> _salvarRemoteMessageComoInterna(RemoteMessage message) async {
    final titulo = _tituloDaMensagem(message);
    final corpo = _corpoDaMensagem(message);

    if (titulo.trim().isEmpty && corpo.trim().isEmpty) {
      return;
    }

    final id = message.messageId?.isNotEmpty == true
        ? 'fcm_${message.messageId}'
        : null;

    await salvarNotificacaoInterna(
      id: id,
      titulo: titulo.isNotEmpty ? titulo : 'Atualizacao TaskLedger',
      mensagem: corpo,
      rota: _rotaDaMensagem(message),
      dados: message.data,
    );
  }

  String _tituloDaMensagem(RemoteMessage message) {
    return message.notification?.title ??
        message.data['titulo']?.toString() ??
        message.data['title']?.toString() ??
        'TaskLedger';
  }

  String _corpoDaMensagem(RemoteMessage message) {
    return message.notification?.body ??
        message.data['mensagem']?.toString() ??
        message.data['body']?.toString() ??
        '';
  }

  String? _rotaDaMensagem(RemoteMessage message) {
    return message.data['rota']?.toString() ??
        message.data['route']?.toString() ??
        (message.data['tela'] == 'orcamento_compras'
            ? '/orcamento-compras'
            : null);
  }

  String _payloadDaMensagem(RemoteMessage message) {
    return jsonEncode({
      'rota': _rotaDaMensagem(message) ?? '/notificacoes',
      'dados': message.data,
    });
  }

  void _abrirDestinoDaNotificacao({
    String? payload,
    RemoteMessage? remoteMessage,
  }) {
    debugPrint(
      'Abrindo notificacao TaskLedger: ${payload ?? remoteMessage?.data}',
    );
    abrirCentralNotificacoesGlobal();
  }
}
