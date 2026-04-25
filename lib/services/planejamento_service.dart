import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/jsonbin_config.dart';
import '../models/planejamento_model.dart';
import '../utils/app_date_utils.dart';

class PlanejamentoService {
  PlanejamentoService({http.Client? client})
    : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 20);

  final http.Client _client;

  Uri get _binUri => Uri.parse(
    '${JsonBinConfig.baseUrl}/b/${JsonBinConfig.planejamentoBinId}',
  );

  Uri get _latestBinUri => Uri.parse(
    '${JsonBinConfig.baseUrl}/b/${JsonBinConfig.planejamentoBinId}/latest',
  );

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    JsonBinConfig.apiKeyHeader: JsonBinConfig.apiKey,
  };

  Future<List<PlanejamentoModel>> listByUser(String uid) async {
    final record = await _readRecord();
    final planejamentos = _extractPlanejamentos(
      record,
    ).where((planejamento) => planejamento.uid == uid).toList();

    planejamentos.sort((a, b) => AppDateUtils.compareNullable(a.data, b.data));
    return planejamentos;
  }

  Future<void> create(PlanejamentoModel planejamento) async {
    final record = await _readRecord();
    final planejamentos = _extractPlanejamentos(record);
    final agora = DateTime.now();
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    planejamentos.add(
      PlanejamentoModel(
        id: id,
        uid: planejamento.uid,
        titulo: planejamento.titulo,
        descricao: planejamento.descricao,
        data: planejamento.data,
        prioridade: planejamento.prioridade,
        status: planejamento.status,
        imagemUrl: planejamento.imagemUrl,
        imagemBase64: planejamento.imagemBase64,
        criadoEm: agora,
        atualizadoEm: agora,
      ),
    );

    await _writePlanejamentos(record, planejamentos);
  }

  Future<void> update(PlanejamentoModel planejamento) async {
    final id = planejamento.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Planejamento sem id para atualização.');
    }

    final record = await _readRecord();
    final planejamentos = _extractPlanejamentos(record);
    final index = planejamentos.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw StateError('Planejamento não encontrado.');
    }

    planejamentos[index] = PlanejamentoModel(
      id: id,
      uid: planejamento.uid,
      titulo: planejamento.titulo,
      descricao: planejamento.descricao,
      data: planejamento.data,
      prioridade: planejamento.prioridade,
      status: planejamento.status,
      imagemUrl: planejamento.imagemUrl,
      imagemBase64: planejamento.imagemBase64,
      criadoEm: planejamentos[index].criadoEm,
      atualizadoEm: DateTime.now(),
    );

    await _writePlanejamentos(record, planejamentos);
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    final record = await _readRecord();
    final planejamentos = _extractPlanejamentos(record);
    final index = planejamentos.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw StateError('Planejamento não encontrado.');
    }

    final atual = planejamentos[index];
    planejamentos[index] = PlanejamentoModel(
      id: atual.id,
      uid: atual.uid,
      titulo: atual.titulo,
      descricao: atual.descricao,
      data: atual.data,
      prioridade: atual.prioridade,
      status: status,
      imagemUrl: atual.imagemUrl,
      imagemBase64: atual.imagemBase64,
      criadoEm: atual.criadoEm,
      atualizadoEm: DateTime.now(),
    );

    await _writePlanejamentos(record, planejamentos);
  }

  Future<void> delete(String id) async {
    final record = await _readRecord();
    final planejamentos = _extractPlanejamentos(
      record,
    ).where((planejamento) => planejamento.id != id).toList();

    await _writePlanejamentos(record, planejamentos);
  }

  Future<Map<String, dynamic>> _readRecord() async {
    _validateConfig();

    final response = await _client
        .get(_latestBinUri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 404) {
      return {'planejamentos': <Map<String, dynamic>>[]};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_buildErrorMessage('ler', response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final record = decoded['record'];
      if (record is Map<String, dynamic>) {
        return Map<String, dynamic>.from(record);
      }
      return Map<String, dynamic>.from(decoded);
    }

    return {'planejamentos': <Map<String, dynamic>>[]};
  }

  Future<void> _writePlanejamentos(
    Map<String, dynamic> record,
    List<PlanejamentoModel> planejamentos,
  ) async {
    _validateConfig();

    final nextRecord = Map<String, dynamic>.from(record);
    nextRecord['planejamentos'] = planejamentos
        .map((planejamento) => planejamento.toMap())
        .toList();

    final response = await _client
        .put(_binUri, headers: _headers, body: jsonEncode(nextRecord))
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_buildErrorMessage('gravar', response));
    }
  }

  String _buildErrorMessage(String operacao, http.Response response) {
    var detalhe = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        detalhe = decoded['message'].toString();
      }
    } catch (_) {
      // Mantém o corpo original quando a resposta não for JSON.
    }

    return 'Erro ao $operacao JSONBin: ${response.statusCode} - $detalhe';
  }

  List<PlanejamentoModel> _extractPlanejamentos(Map<String, dynamic> record) {
    final rawList = record['planejamentos'];
    if (rawList is! List) {
      return <PlanejamentoModel>[];
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) => PlanejamentoModel.fromMap(
            Map<String, dynamic>.from(item),
            id: item['id']?.toString(),
          ),
        )
        .toList();
  }

  void _validateConfig() {
    if (JsonBinConfig.planejamentoBinId == 'SEU_BIN_ID_AQUI' ||
        JsonBinConfig.apiKey == 'SUA_CHAVE_JSONBIN_AQUI') {
      throw StateError('Configure o binId e a chave do JSONBin.');
    }
  }
}
