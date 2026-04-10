import '../utils/app_date_utils.dart';

class TarefaModel {
  const TarefaModel({
    this.id,
    required this.uid,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.prioridade,
    required this.prazo,
    this.criadoEm,
    this.atualizadoEm,
  });

  final String? id;
  final String uid;
  final String titulo;
  final String descricao;
  final String status;
  final String prioridade;
  final DateTime? prazo;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory TarefaModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return TarefaModel(
      id: id ?? map['id']?.toString(),
      uid: map['uid']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      status: map['status']?.toString() ?? 'a_fazer',
      prioridade: map['prioridade']?.toString() ?? 'media',
      prazo: AppDateUtils.parse(map['prazo']),
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
      'status': status,
      'prioridade': prioridade,
      'prazo': prazo,
      'criadoEm': criadoEm,
      'atualizadoEm': atualizadoEm,
    };
  }
}
