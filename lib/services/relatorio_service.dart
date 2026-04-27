import '../models/relatorio_model.dart';
import '../services/planejamento_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/app_date_utils.dart';

class RelatorioService {
  RelatorioService({PlanejamentoService? planejamentoService})
    : _planejamentoService = planejamentoService ?? PlanejamentoService();

  final PlanejamentoService _planejamentoService;

  Future<RelatorioResumoModel> carregarResumo({
    required String uid,
    required List<Map<String, dynamic>> tarefas,
    required List<Map<String, dynamic>> transacoes,
  }) async {
    final planejamentos = await _planejamentoService.listByUser(uid);
    final planejamentosMap = planejamentos.map((item) => item.toMap()).toList();

    final totalReceitas = transacoes
        .where((item) => item['tipo']?.toString() == 'receita')
        .fold<double>(0, (total, item) => total + _paraValor(item['valor']));

    final totalDespesas = transacoes
        .where((item) => item['tipo']?.toString() != 'receita')
        .fold<double>(0, (total, item) => total + _paraValor(item['valor']));

    final saldo = totalReceitas - totalDespesas;
    final tarefasAtivas = tarefas
        .where((item) => item['status']?.toString() != 'concluido')
        .length;
    final tarefasVencidas = _calcularTarefasVencidas(tarefas);
    final ultimaAtualizacao = _calcularUltimaAtualizacao(planejamentosMap);

    return RelatorioResumoModel(
      tarefasAtivas: tarefasAtivas,
      tarefasVencidas: tarefasVencidas,
      totalProjetos: planejamentosMap.length,
      totalReceitas: totalReceitas,
      totalDespesas: totalDespesas,
      saldo: saldo,
      ultimaAtualizacao: ultimaAtualizacao,
      tarefasPorStatus: _seriePorValores(<String, double>{
        'A fazer': _contarPorCampo(tarefas, 'status', 'a_fazer').toDouble(),
        'Em andamento': _contarPorCampo(
          tarefas,
          'status',
          'em_andamento',
        ).toDouble(),
        'Concluídas': _contarPorCampo(
          tarefas,
          'status',
          'concluido',
        ).toDouble(),
      }),
      tarefasPorPrioridade: _seriePorValores(<String, double>{
        'Alta': _contarPorCampo(tarefas, 'prioridade', 'alta').toDouble(),
        'Média': _contarPorCampo(tarefas, 'prioridade', 'media').toDouble(),
        'Baixa': _contarPorCampo(tarefas, 'prioridade', 'baixa').toDouble(),
      }),
      planejamentosPorStatus: _seriePorValores(<String, double>{
        'Planejados': _contarPorCampo(
          planejamentosMap,
          'status',
          'a_fazer',
        ).toDouble(),
        'Em andamento': _contarPorCampo(
          planejamentosMap,
          'status',
          'em_andamento',
        ).toDouble(),
        'Concluídos': _contarPorCampo(
          planejamentosMap,
          'status',
          'concluido',
        ).toDouble(),
      }),
      planejamentosPorPrioridade: _seriePorValores(<String, double>{
        'Alta': _contarPorCampo(
          planejamentosMap,
          'prioridade',
          'alta',
        ).toDouble(),
        'Média': _contarPorCampo(
          planejamentosMap,
          'prioridade',
          'media',
        ).toDouble(),
        'Baixa': _contarPorCampo(
          planejamentosMap,
          'prioridade',
          'baixa',
        ).toDouble(),
      }),
      totaisPorCategoria: _totaisPorCategoria(transacoes),
    );
  }

  int _contarPorCampo(
    List<Map<String, dynamic>> itens,
    String campo,
    String valorEsperado,
  ) {
    return itens
        .where((item) => item[campo]?.toString() == valorEsperado)
        .length;
  }

  int _calcularTarefasVencidas(List<Map<String, dynamic>> tarefas) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    return tarefas.where((item) {
      final prazo = AppDateUtils.parse(item['prazo']);
      final status = item['status']?.toString() ?? 'a_fazer';
      return prazo != null && prazo.isBefore(hoje) && status != 'concluido';
    }).length;
  }

  DateTime? _calcularUltimaAtualizacao(
    List<Map<String, dynamic>> planejamentos,
  ) {
    return planejamentos
        .map(
          (item) =>
              AppDateUtils.parse(item['atualizadoEm']) ??
              AppDateUtils.parse(item['criadoEm']),
        )
        .whereType<DateTime>()
        .fold<DateTime?>(null, (atual, item) {
          if (atual == null || item.isAfter(atual)) {
            return item;
          }
          return atual;
        });
  }

  List<RelatorioSerieItem> _seriePorValores(Map<String, double> valores) {
    return valores.entries
        .map((item) => RelatorioSerieItem(label: item.key, valor: item.value))
        .where((item) => item.valor > 0)
        .toList();
  }

  List<RelatorioSerieItem> _totaisPorCategoria(
    List<Map<String, dynamic>> transacoes,
  ) {
    final totais = <String, double>{};

    for (final transacao in transacoes) {
      final categoria = transacao['categoria']?.toString().trim();
      final chave = categoria == null || categoria.isEmpty
          ? 'Outros'
          : categoria;
      totais[chave] = (totais[chave] ?? 0) + _paraValor(transacao['valor']);
    }

    final itens =
        totais.entries
            .map(
              (item) => RelatorioSerieItem(label: item.key, valor: item.value),
            )
            .toList()
          ..sort((a, b) => b.valor.compareTo(a.valor));

    return itens.take(5).toList();
  }

  double _paraValor(dynamic valor) {
    return AppCurrencyUtils.parse(valor);
  }
}
