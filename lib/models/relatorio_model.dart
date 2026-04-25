class RelatorioResumoModel {
  const RelatorioResumoModel({
    required this.tarefasAtivas,
    required this.tarefasVencidas,
    required this.totalProjetos,
    required this.totalReceitas,
    required this.totalDespesas,
    required this.saldo,
    required this.ultimaAtualizacao,
    required this.tarefasPorStatus,
    required this.tarefasPorPrioridade,
    required this.planejamentosPorStatus,
    required this.planejamentosPorPrioridade,
    required this.totaisPorCategoria,
  });

  final int tarefasAtivas;
  final int tarefasVencidas;
  final int totalProjetos;
  final double totalReceitas;
  final double totalDespesas;
  final double saldo;
  final DateTime? ultimaAtualizacao;
  final List<RelatorioSerieItem> tarefasPorStatus;
  final List<RelatorioSerieItem> tarefasPorPrioridade;
  final List<RelatorioSerieItem> planejamentosPorStatus;
  final List<RelatorioSerieItem> planejamentosPorPrioridade;
  final List<RelatorioSerieItem> totaisPorCategoria;
}

class RelatorioSerieItem {
  const RelatorioSerieItem({required this.label, required this.valor});

  final String label;
  final double valor;
}
