import '../utils/app_date_utils.dart';

class PlanejamentoModel {
  const PlanejamentoModel({
    this.id,
    required this.uid,
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.prioridade,
    required this.status,
    this.imagemUrl,
    this.imagemBase64,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String? id;
  final String uid;
  final String titulo;
  final String descricao;
  final DateTime? data;
  final String prioridade;
  final String status;
  final String? imagemUrl;
  final String? imagemBase64;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory PlanejamentoModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PlanejamentoModel(
      id: id ?? map['id']?.toString(),
      uid: map['uid']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      data: AppDateUtils.parse(map['data']),
      prioridade: map['prioridade']?.toString() ?? 'media',
      status: map['status']?.toString() ?? 'a_fazer',
      imagemUrl: map['imagemUrl']?.toString(),
      imagemBase64: map['imagemBase64']?.toString(),
      criadoEm: AppDateUtils.parse(map['criadoEm']),
      atualizadoEm: AppDateUtils.parse(map['atualizadoEm']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'titulo': titulo,
      'descricao': descricao,
      'data': data?.toIso8601String(),
      'prioridade': prioridade,
      'status': status,
      'imagemUrl': imagemUrl,
      'imagemBase64': imagemBase64,
      'criadoEm': criadoEm?.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
    };
  }
}
