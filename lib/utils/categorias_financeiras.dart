import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriasFinanceiras {
  const CategoriasFinanceiras._();

  static const _storageKey = 'categorias_financeiras_customizadas';
  static final ValueNotifier<int> versao = ValueNotifier<int>(0);

  static const List<String> padrao = [
    'Salário',
    'Freela',
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Lazer',
    'Compras',
    'Outros',
  ];

  static Future<List<String>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final customizadas = prefs.getStringList(_storageKey) ?? const <String>[];
    return _ordenarUnicas([...padrao, ...customizadas]);
  }

  static Future<List<String>> adicionar(String categoria) async {
    final categoriaNormalizada = categoria.trim();
    if (categoriaNormalizada.isEmpty) {
      return carregar();
    }

    return sincronizar([categoriaNormalizada]);
  }

  static bool equivalente(String primeira, String segunda) {
    return _chaveComparacao(primeira) == _chaveComparacao(segunda);
  }

  static bool contem(List<String> categorias, String categoria) {
    return categorias.any((item) => equivalente(item, categoria));
  }

  static String resolver(List<String> categorias, String categoria) {
    return categorias.firstWhere(
      (item) => equivalente(item, categoria),
      orElse: () => categoria.trim(),
    );
  }

  static Future<List<String>> sincronizar(Iterable<String> categorias) async {
    final prefs = await SharedPreferences.getInstance();
    final atuais = prefs.getStringList(_storageKey) ?? const <String>[];
    final novas = categorias
        .map((categoria) => categoria.trim())
        .where((categoria) => categoria.isNotEmpty);
    final todas = _ordenarUnicas([...padrao, ...atuais, ...novas]);
    final customizadas = todas
        .where(
          (categoria) => !padrao.any(
            (padrao) => _chaveComparacao(padrao) == _chaveComparacao(categoria),
          ),
        )
        .toList();

    await prefs.setStringList(_storageKey, customizadas);
    versao.value++;
    return todas;
  }

  static List<String> _ordenarUnicas(List<String> categorias) {
    final mapa = <String, String>{};
    for (final categoria in categorias) {
      final texto = categoria.trim();
      if (texto.isEmpty) {
        continue;
      }
      mapa.putIfAbsent(_chaveComparacao(texto), () => texto);
    }

    final resultado = mapa.values.toList();
    resultado.sort((a, b) {
      if (a == 'Outros') return 1;
      if (b == 'Outros') return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return resultado;
  }

  static String _chaveComparacao(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàãâä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòõôö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
