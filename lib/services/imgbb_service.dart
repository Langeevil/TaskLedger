import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/imgbb_config.dart';

class ImgbbService {
  ImgbbService({http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 30);

  final http.Client _client;

  Future<String> uploadBase64(String imageBase64) async {
    _validateConfig();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ImgbbConfig.uploadUrl}?key=${ImgbbConfig.apiKey}'),
    );
    request.fields['image'] = imageBase64;

    final streamedResponse = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_buildErrorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Resposta invalida do ImgBB.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Resposta sem dados de imagem do ImgBB.');
    }

    final url = data['url']?.toString();
    final displayUrl = data['display_url']?.toString();
    final imageUrl = displayUrl?.isNotEmpty == true ? displayUrl : url;

    if (imageUrl == null || imageUrl.isEmpty) {
      throw StateError('ImgBB não retornou a URL da imagem.');
    }

    return imageUrl;
  }

  String _buildErrorMessage(http.Response response) {
    var detalhe = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        detalhe = decoded['error']['message']?.toString() ?? detalhe;
      }
    } catch (_) {
      // Mantém o corpo original quando a resposta não for JSON.
    }

    return 'Erro ao enviar imagem para ImgBB: ${response.statusCode} - $detalhe';
  }

  void _validateConfig() {
    if (ImgbbConfig.apiKey == 'SUA_API_KEY_IMGBB_AQUI') {
      throw StateError('Configure a API key do ImgBB.');
    }
  }
}
