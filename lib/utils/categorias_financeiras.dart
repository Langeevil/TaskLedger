import 'package:shared_preferences/shared_preferences.dart';

class CategoriasFinanceiras {
  const CategoriasFinanceiras._();

  static const _storageKey = 'categorias_financeiras_customizadas';

  static const List<String> padrao = [
    'Salario',
    'Freela',
    'Alimentacao',
    'Transporte',
    'Moradia',
    'Saude',
    'Lazer',
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

    final prefs = await SharedPreferences.getInstance();
    final atuais = prefs.getStringList(_storageKey) ?? const <String>[];
    final todas = _ordenarUnicas([...padrao, ...atuais, categoriaNormalizada]);
    final customizadas = todas
        .where(
          (categoria) => !padrao.any(
            (padrao) => padrao.toLowerCase() == categoria.toLowerCase(),
          ),
        )
        .toList();

    await prefs.setStringList(_storageKey, customizadas);
    return todas;
  }

  static List<String> _ordenarUnicas(List<String> categorias) {
    final mapa = <String, String>{};
    for (final categoria in categorias) {
      final texto = categoria.trim();
      if (texto.isEmpty) {
        continue;
      }
      mapa.putIfAbsent(texto.toLowerCase(), () => texto);
    }

    final resultado = mapa.values.toList();
    resultado.sort((a, b) {
      if (a == 'Outros') return 1;
      if (b == 'Outros') return -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return resultado;
  }
}
