import '../utils/app_date_utils.dart';
import '../utils/app_currency_utils.dart';

class TransacaoModel {
  const TransacaoModel({
    this.id,
    required this.uid,
    required this.titulo,
    required this.tipo,
    required this.categoria,
    required this.valor,
    required this.data,
    required this.observacao,
    this.comprovanteBase64,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String? id;
  final String uid;
  final String titulo;
  final String tipo;
  final String categoria;
  final double valor;
  final DateTime? data;
  final String observacao;
  final String? comprovanteBase64;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory TransacaoModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawValue = map['valor'];

    return TransacaoModel(
      id: id ?? map['id']?.toString(),
      uid: map['uid']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'despesa',
      categoria: map['categoria']?.toString() ?? 'Outros',
      valor: AppCurrencyUtils.parse(rawValue),
      data: AppDateUtils.parse(map['data']),
      observacao: map['observacao']?.toString() ?? '',
      comprovanteBase64: map['comprovanteBase64']?.toString(),
      criadoEm: AppDateUtils.parse(map['criadoEm']),
      atualizadoEm: AppDateUtils.parse(map['atualizadoEm']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'titulo': titulo,
      'tipo': tipo,
      'categoria': categoria,
      'valor': valor,
      'data': data,
      'observacao': observacao,
      'comprovanteBase64': comprovanteBase64,
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
    };
  }
}
