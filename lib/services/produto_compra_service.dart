import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/mockapi_config.dart';
import '../models/produto_compra.dart';

class ProdutoCompraService {
  ProdutoCompraService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<ProdutoCompra>> listarProdutos() async {
    final response = await _client.get(_baseUri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(ProdutoCompra.fromJson)
            .toList();
      }
      throw const ProdutoCompraServiceException(
        'A resposta da API não está no formato esperado.',
      );
    }

    throw ProdutoCompraServiceException(
      'Não foi possível carregar os produtos.',
      statusCode: response.statusCode,
    );
  }

  Future<ProdutoCompra> cadastrarProduto(ProdutoCompra produto) async {
    final response = await _client.post(
      _baseUri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(produto.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ProdutoCompra.fromJson(decoded);
      }
      throw const ProdutoCompraServiceException(
        'A resposta da API não está no formato esperado.',
      );
    }

    throw ProdutoCompraServiceException(
      'Não foi possível cadastrar o produto.',
      statusCode: response.statusCode,
    );
  }

  Future<ProdutoCompra> editarProduto(ProdutoCompra produto) async {
    if (produto.id.isEmpty) {
      throw const ProdutoCompraServiceException(
        'Produto sem identificador para atualização.',
      );
    }

    final response = await _client.put(
      _uriComId(produto.id),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(produto.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ProdutoCompra.fromJson(decoded);
      }
      throw const ProdutoCompraServiceException(
        'A resposta da API não está no formato esperado.',
      );
    }

    throw ProdutoCompraServiceException(
      'Não foi possível atualizar o produto.',
      statusCode: response.statusCode,
    );
  }

  Future<void> excluirProduto(String id) async {
    if (id.trim().isEmpty) {
      throw const ProdutoCompraServiceException(
        'Produto sem identificador para exclusão.',
      );
    }

    final response = await _client.delete(_uriComId(id));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProdutoCompraServiceException(
        'Não foi possível excluir o produto.',
        statusCode: response.statusCode,
      );
    }
  }

  Uri get _baseUri {
    final rawUrl = MockApiConfig.baseUrl.trim();
    final uri = Uri.tryParse(rawUrl);

    if (rawUrl.isEmpty ||
        rawUrl == 'COLE_AQUI_SEU_ENDPOINT_DO_MOCKAPI' ||
        uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      throw const ProdutoCompraServiceException(
        'Configure o endpoint do MockAPI.io em lib/config/mockapi_config.dart.',
      );
    }

    return uri;
  }

  Uri _uriComId(String id) {
    final base = MockApiConfig.baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/${Uri.encodeComponent(id)}');
  }
}

class ProdutoCompraServiceException implements Exception {
  const ProdutoCompraServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '$message Código: $statusCode';
  }
}
