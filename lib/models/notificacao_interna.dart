import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacaoInterna {
  const NotificacaoInterna({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.visualizada,
    required this.criadoEm,
    this.rota,
    this.dados,
    this.notificacaoLocalEnviada = false,
  });

  final String id;
  final String titulo;
  final String mensagem;
  final bool visualizada;
  final DateTime criadoEm;
  final String? rota;
  final Map<String, dynamic>? dados;
  final bool notificacaoLocalEnviada;

  factory NotificacaoInterna.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return NotificacaoInterna.fromMap(
      document.data() ?? <String, dynamic>{},
      id: document.id,
    );
  }

  factory NotificacaoInterna.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return NotificacaoInterna(
      id: id,
      titulo: map['titulo']?.toString() ?? 'Notificacao',
      mensagem: map['mensagem']?.toString() ?? '',
      visualizada: map['visualizada'] == true,
      criadoEm: _converterData(map['criadoEm']) ?? DateTime.now(),
      rota: map['rota']?.toString(),
      dados: map['dados'] is Map
          ? Map<String, dynamic>.from(map['dados'] as Map)
          : null,
      notificacaoLocalEnviada: map['notificacaoLocalEnviada'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'mensagem': mensagem,
      'visualizada': visualizada,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'rota': rota,
      'dados': dados,
      'notificacaoLocalEnviada': notificacaoLocalEnviada,
    };
  }

  NotificacaoInterna copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    bool? visualizada,
    DateTime? criadoEm,
    String? rota,
    Map<String, dynamic>? dados,
    bool? notificacaoLocalEnviada,
  }) {
    return NotificacaoInterna(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      visualizada: visualizada ?? this.visualizada,
      criadoEm: criadoEm ?? this.criadoEm,
      rota: rota ?? this.rota,
      dados: dados ?? this.dados,
      notificacaoLocalEnviada:
          notificacaoLocalEnviada ?? this.notificacaoLocalEnviada,
    );
  }

  static DateTime? _converterData(dynamic valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }
    if (valor is DateTime) {
      return valor;
    }
    if (valor is String) {
      return DateTime.tryParse(valor);
    }
    return null;
  }
}
