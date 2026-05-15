class ProdutoCompra {
  const ProdutoCompra({
    this.id = '',
    required this.nome,
    required this.descricao,
    required this.categoria,
    required this.preco,
    this.imagem,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String descricao;
  final String categoria;
  final double preco;
  final String? imagem;
  final String? criadoEm;

  factory ProdutoCompra.fromJson(Map<String, dynamic> json) {
    return ProdutoCompra(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      preco: _converterPreco(json['preco']),
      imagem: _textoOpcional(json['imagem']),
      criadoEm: _textoOpcional(json['criadoEm']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'preco': preco,
      if (imagem?.trim().isNotEmpty ?? false) 'imagem': imagem,
      if (criadoEm?.trim().isNotEmpty ?? false) 'criadoEm': criadoEm,
    };
  }

  static double _converterPreco(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }

    if (valor is String) {
      final textoLimpo = valor.trim();
      if (textoLimpo.isEmpty) {
        return 0;
      }

      final somenteNumero = textoLimpo.replaceAll(RegExp(r'[^0-9,.-]'), '');
      if (somenteNumero.contains(',')) {
        final normalizado = somenteNumero
            .replaceAll('.', '')
            .replaceAll(',', '.');
        return double.tryParse(normalizado) ?? 0;
      }

      return double.tryParse(somenteNumero) ?? 0;
    }

    return 0;
  }

  static String? _textoOpcional(dynamic valor) {
    final texto = valor?.toString().trim();
    if (texto == null || texto.isEmpty) {
      return null;
    }
    return texto;
  }
}
