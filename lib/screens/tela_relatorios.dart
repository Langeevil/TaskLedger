import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/relatorio_model.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/relatorio_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/app_date_utils.dart';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({
    super.key,
    required this.uid,
    required this.tarefas,
    required this.transacoes,
  });

  final String uid;
  final List<Map<String, dynamic>> tarefas;
  final List<Map<String, dynamic>> transacoes;

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final _relatorioService = RelatorioService();
  final _relatorioPdfService = RelatorioPdfService();

  int _secaoSelecionada = 0;
  bool _carregandoResumo = true;
  bool _gerandoPdf = false;
  RelatorioResumoModel? _resumo;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() {
      _carregandoResumo = true;
    });

    try {
      final resumo = await _relatorioService.carregarResumo(
        uid: widget.uid,
        tarefas: widget.tarefas,
        transacoes: widget.transacoes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _resumo = resumo;
        _carregandoResumo = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resumo = null;
        _carregandoResumo = false;
      });
    }
  }

  String _formatarMoeda(double valor) {
    return AppCurrencyUtils.format(valor);
  }

  Future<void> _gerarPdf() async {
    final resumo = _resumo;
    if (resumo == null || _gerandoPdf) {
      return;
    }

    setState(() {
      _gerandoPdf = true;
    });

    try {
      final destino = await _relatorioPdfService.gerarESalvarPdf(
        resumo: resumo,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF gerado com sucesso em: $destino'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar o PDF do relatório.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gerandoPdf = false;
        });
      }
    }
  }

  Widget _construirGraficoPizza(List<_ChartSlice> dados) {
    if (dados.isEmpty) {
      return _construirEstadoVazio(
        'Sem dados suficientes para este relatório.',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 56,
              sections: dados.map((item) {
                return PieChartSectionData(
                  value: item.value,
                  color: item.color,
                  radius: 52,
                  title: item.value.toInt().toString(),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: dados.map((item) => _LegendaCor(item: item)).toList(),
        ),
      ],
    );
  }

  Widget _construirGraficoBarras(
    List<_ChartBar> dados, {
    bool monetario = false,
  }) {
    if (dados.isEmpty || dados.every((item) => item.value <= 0)) {
      return _construirEstadoVazio(
        'Sem dados suficientes para este relatório.',
      );
    }

    final maiorValor = dados
        .map((item) => item.value)
        .reduce((esquerda, direita) => esquerda > direita ? esquerda : direita);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          maxY: maiorValor == 0 ? 1 : maiorValor * 1.25,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.08),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: monetario ? 56 : 34,
                interval: maiorValor <= 5 ? 1 : maiorValor / 4,
                getTitlesWidget: (value, meta) {
                  final texto = monetario
                      ? _formatarMoeda(value).replaceAll('R\$ ', '')
                      : value.toInt().toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      texto,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final indice = value.toInt();
                  if (indice < 0 || indice >= dados.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      dados[indice].label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(dados.length, (indice) {
            final item = dados[indice];
            return BarChartGroupData(
              x: indice,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  color: item.color,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _construirEstadoVazio(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11182F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        mensagem,
        style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
      ),
    );
  }

  Widget _construirCardResumo({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11182F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(height: 18),
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBlocoRelatorio({
    required String titulo,
    required String subtitulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1729),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.64),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  List<_ChartSlice> _mapearSlices(
    List<RelatorioSerieItem> itens,
    Map<String, Color> cores,
  ) {
    return itens
        .map(
          (item) => _ChartSlice(
            label: item.label,
            value: item.valor,
            color: cores[item.label] ?? const Color(0xFF6366F1),
          ),
        )
        .toList();
  }

  List<_ChartBar> _mapearBarras(
    List<RelatorioSerieItem> itens,
    Map<String, Color> cores,
  ) {
    return itens
        .map(
          (item) => _ChartBar(
            label: item.label,
            value: item.valor,
            color: cores[item.label] ?? const Color(0xFF6366F1),
          ),
        )
        .toList();
  }

  List<_ChartBar> _resumoFinanceiro(RelatorioResumoModel resumo) {
    return <_ChartBar>[
      _ChartBar(
        label: 'Receitas',
        value: resumo.totalReceitas,
        color: const Color(0xFF10B981),
      ),
      _ChartBar(
        label: 'Despesas',
        value: resumo.totalDespesas,
        color: const Color(0xFFEF4444),
      ),
      _ChartBar(
        label: 'Saldo',
        value: resumo.saldo < 0 ? resumo.saldo.abs() : resumo.saldo,
        color: const Color(0xFF6366F1),
      ),
    ];
  }

  Widget _construirSecoes(RelatorioResumoModel resumo) {
    const coresTarefaStatus = <String, Color>{
      'A fazer': Color(0xFF6366F1),
      'Em andamento': Color(0xFFF59E0B),
      'Concluidas': Color(0xFF10B981),
    };
    const coresPrioridade = <String, Color>{
      'Alta': Color(0xFFEF4444),
      'Média': Color(0xFFF59E0B),
      'Baixa': Color(0xFF10B981),
    };
    const coresProjetosStatus = <String, Color>{
      'Planejados': Color(0xFF38BDF8),
      'Em andamento': Color(0xFFF97316),
      'Concluídos': Color(0xFF22C55E),
    };
    const coresCategoria = <String, Color>{};

    final tarefasPorStatus = _mapearSlices(
      resumo.tarefasPorStatus,
      coresTarefaStatus,
    );
    final tarefasPorPrioridade = _mapearBarras(
      resumo.tarefasPorPrioridade,
      coresPrioridade,
    );
    final planejamentosPorStatus = _mapearSlices(
      resumo.planejamentosPorStatus,
      coresProjetosStatus,
    );
    final planejamentosPorPrioridade = _mapearBarras(
      resumo.planejamentosPorPrioridade,
      coresPrioridade,
    );
    final categorias = _mapearBarras(resumo.totaisPorCategoria, coresCategoria);
    final resumoFinanceiro = _resumoFinanceiro(resumo);

    final secoes = <Widget>[
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _construirCardResumo(
                  titulo: 'Tarefas ativas',
                  valor: '${resumo.tarefasAtivas}',
                  icone: Icons.task_alt,
                  cor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _construirCardResumo(
                  titulo: 'Saldo atual',
                  valor: _formatarMoeda(resumo.saldo),
                  icone: Icons.account_balance_wallet_outlined,
                  cor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _construirCardResumo(
                  titulo: 'Projetos',
                  valor: '${resumo.totalProjetos}',
                  icone: Icons.event_note_outlined,
                  cor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _construirCardResumo(
                  titulo: 'Tarefas vencidas',
                  valor: '${resumo.tarefasVencidas}',
                  icone: Icons.warning_amber_rounded,
                  cor: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _construirBlocoRelatorio(
            titulo: 'Panorama de tarefas',
            subtitulo:
                'Distribuição por status para leitura rapida do backlog.',
            child: _construirGraficoPizza(tarefasPorStatus),
          ),
          _construirBlocoRelatorio(
            titulo: 'Resumo financeiro',
            subtitulo:
                'Comparativo entre entradas, saidas e saldo consolidado.',
            child: _construirGraficoBarras(resumoFinanceiro, monetario: true),
          ),
          _construirBlocoRelatorio(
            titulo: 'Projetos em andamento',
            subtitulo: 'Visão da carteira de planejamento por status.',
            child: _construirGraficoPizza(planejamentosPorStatus),
          ),
        ],
      ),
      Column(
        children: [
          _construirBlocoRelatorio(
            titulo: 'Relatório de tarefas',
            subtitulo:
                'Acompanhe o progresso geral e as prioridades mais frequentes.',
            child: Column(
              children: [
                _construirGraficoPizza(tarefasPorStatus),
                const SizedBox(height: 24),
                _construirGraficoBarras(tarefasPorPrioridade),
              ],
            ),
          ),
        ],
      ),
      Column(
        children: [
          _construirBlocoRelatorio(
            titulo: 'Relatório financeiro',
            subtitulo: 'Totais acumulados e principais categorias registradas.',
            child: Column(
              children: [
                _construirGraficoBarras(resumoFinanceiro, monetario: true),
                const SizedBox(height: 24),
                _construirGraficoBarras(categorias, monetario: true),
              ],
            ),
          ),
        ],
      ),
      Column(
        children: [
          _construirBlocoRelatorio(
            titulo: 'Relatório de projetos',
            subtitulo:
                'Status e prioridade dos itens cadastrados em planejamento.',
            child: Column(
              children: [
                _construirGraficoPizza(planejamentosPorStatus),
                const SizedBox(height: 24),
                _construirGraficoBarras(planejamentosPorPrioridade),
              ],
            ),
          ),
        ],
      ),
    ];

    return secoes[_secaoSelecionada];
  }

  @override
  Widget build(BuildContext context) {
    const secoes = <String>['Visão geral', 'Tarefas', 'Finanças', 'Projetos'];

    return RefreshIndicator(
      onRefresh: _carregarResumo,
      color: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFF1A1F3A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relatórios',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _resumo?.ultimaAtualizacao == null
                            ? 'Leitura consolidada das informações já registradas no app.'
                            : 'Atualizado com base nos dados registrados ate ${AppDateUtils.format(_resumo!.ultimaAtualizacao!)}.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF11182F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _carregandoResumo ? null : _gerarPdf,
                        icon: _gerandoPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1),
                                  ),
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        color: const Color(0xFF6366F1),
                        tooltip: 'Gerar PDF',
                      ),
                      IconButton(
                        onPressed: _carregarResumo,
                        icon: const Icon(Icons.auto_graph_rounded),
                        color: const Color(0xFF6366F1),
                        tooltip: 'Atualizar relatórios',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(secoes.length, (indice) {
                  final ativo = _secaoSelecionada == indice;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: indice == secoes.length - 1 ? 0 : 10,
                    ),
                    child: ChoiceChip(
                      selected: ativo,
                      label: Text(secoes[indice]),
                      onSelected: (_) {
                        setState(() {
                          _secaoSelecionada = indice;
                        });
                      },
                      backgroundColor: const Color(0xFF11182F),
                      selectedColor: const Color(0xFF6366F1).withOpacity(0.28),
                      side: BorderSide(
                        color: ativo
                            ? const Color(0xFF6366F1).withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                      ),
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(ativo ? 1 : 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            if (_carregandoResumo)
              const Center(child: CircularProgressIndicator())
            else if (_resumo == null)
              _construirEstadoVazio(
                'Não foi possível consolidar os dados dos relatórios agora.',
              )
            else
              _construirSecoes(_resumo!),
          ],
        ),
      ),
    );
  }
}

class _LegendaCor extends StatelessWidget {
  const _LegendaCor({required this.item});

  final _ChartSlice item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF11182F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.label} (${item.value.toInt()})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSlice {
  const _ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}
