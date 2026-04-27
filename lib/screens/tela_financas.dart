import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/transacao_model.dart';
import '../services/transacao_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/app_date_utils.dart';
import '../utils/responsive_utils.dart';

class TelaFinancas extends StatefulWidget {
  const TelaFinancas({
    super.key,
    required this.uid,
    required this.totalReceitas,
    required this.totalGastos,
    required this.saldo,
    required this.transacoes,
    required this.onDadosAtualizados,
  });

  final String uid;
  final double totalReceitas;
  final double totalGastos;
  final double saldo;
  final List<Map<String, dynamic>> transacoes;
  final Future<void> Function() onDadosAtualizados;

  @override
  State<TelaFinancas> createState() => _TelaFinancasState();
}

class _TelaFinancasState extends State<TelaFinancas> {
  final _transacaoService = TransacaoService();
  String _filtroTipo = 'todos';
  String _filtroPeriodo = 'mes';

  List<Map<String, dynamic>> get _transacoesFiltradas {
    final agora = DateTime.now();
    return widget.transacoes.where((transacao) {
      final tipo = transacao['tipo']?.toString() ?? 'despesa';
      final data = _converterParaDateTime(transacao['data']);

      final correspondeTipo = _filtroTipo == 'todos' || tipo == _filtroTipo;

      bool correspondePeriodo = true;
      if (_filtroPeriodo == 'mes' && data != null) {
        correspondePeriodo =
            data.month == agora.month && data.year == agora.year;
      } else if (_filtroPeriodo == '90dias' && data != null) {
        correspondePeriodo = data.isAfter(
          agora.subtract(const Duration(days: 90)),
        );
      }

      return correspondeTipo && correspondePeriodo;
    }).toList()..sort((a, b) => _compararDatas(b['data'], a['data']));
  }

  DateTime? _converterParaDateTime(dynamic valor) {
    return AppDateUtils.parse(valor);
  }

  int _compararDatas(dynamic esquerda, dynamic direita) {
    return AppDateUtils.compareNullable(esquerda, direita);
  }

  double _converterParaDouble(dynamic valor) {
    return AppCurrencyUtils.parse(valor);
  }

  String _formatarMoeda(double valor) {
    return AppCurrencyUtils.format(valor);
  }

  String _formatarData(DateTime data) {
    return AppDateUtils.format(data);
  }

  List<_CategoriaDespesaItem> _despesasPorCategoria(
    List<Map<String, dynamic>> transacoes,
  ) {
    final totais = <String, double>{};

    for (final transacao in transacoes) {
      final tipo = transacao['tipo']?.toString() ?? 'despesa';
      if (tipo != 'despesa') {
        continue;
      }

      final categoria = transacao['categoria']?.toString().trim();
      final chave = categoria == null || categoria.isEmpty
          ? 'Outros'
          : categoria;
      totais[chave] =
          (totais[chave] ?? 0) + _converterParaDouble(transacao['valor']);
    }

    final cores = <Color>[
      const Color(0xFF6366F1),
      const Color(0xFFF97316),
      const Color(0xFF10B981),
      const Color(0xFF38BDF8),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
    ];

    final itens =
        totais.entries
            .map(
              (entry) => _CategoriaDespesaItem(
                categoria: entry.key,
                total: entry.value,
                cor:
                    cores[totais.keys.toList().indexOf(entry.key) %
                        cores.length],
              ),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));

    return itens;
  }

  Widget _construirGraficoDespesasPorCategoria(
    List<Map<String, dynamic>> transacoes,
  ) {
    final categorias = _despesasPorCategoria(transacoes);
    final totalDespesas = categorias.fold<double>(
      0,
      (total, item) => total + item.total,
    );

    if (categorias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF11182E).withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
        ),
        child: Text(
          'Ainda não há despesas suficientes nesse recorte para montar a distribuição por categoria.',
          style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.45),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = AppResponsive.isMobile(constraints.maxWidth);
        final chart = SizedBox(
          height: compact ? 220 : 230,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 58,
              sectionsSpace: 3,
              sections: categorias.map((item) {
                final percentual = totalDespesas == 0
                    ? 0
                    : (item.total / totalDespesas) * 100;
                return PieChartSectionData(
                  color: item.cor,
                  value: item.total,
                  radius: 52,
                  title: percentual >= 8
                      ? '${percentual.toStringAsFixed(0)}%'
                      : '',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        );
        final legend = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total em despesas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatarMoeda(totalDespesas),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ...categorias.map(
              (item) => _construirLegendaCategoria(
                item: item,
                totalGeral: totalDespesas,
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF11182E).withOpacity(0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribuição de despesas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mostra quais categorias estão consumindo mais do seu caixa no período filtrado.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (compact)
                Column(children: [chart, const SizedBox(height: 18), legend])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 18),
                    Expanded(child: legend),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirLegendaCategoria({
    required _CategoriaDespesaItem item,
    required double totalGeral,
  }) {
    final percentual = totalGeral == 0 ? 0 : (item.total / totalGeral) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: item.cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.categoria,
              style: TextStyle(
                color: Colors.white.withOpacity(0.84),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatarMoeda(item.total),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentual.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uint8List? _decodificarComprovante(String? comprovanteBase64) {
    if (comprovanteBase64 == null || comprovanteBase64.trim().isEmpty) {
      return null;
    }

    try {
      return base64Decode(comprovanteBase64);
    } catch (_) {
      return null;
    }
  }

  void _visualizarComprovante(String? comprovanteBase64) {
    final imagem = _decodificarComprovante(comprovanteBase64);
    if (imagem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o comprovante.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F1729),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comprovante',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _baixarComprovante(imagem),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Baixar'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.memory(imagem, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _baixarComprovante(Uint8List imagem) async {
    try {
      await FileSaver.instance.saveFile(
        name: 'comprovante_taskledger_${DateTime.now().millisecondsSinceEpoch}',
        bytes: imagem,
        fileExtension: 'jpg',
        mimeType: MimeType.jpeg,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprovante baixado com sucesso.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível baixar o comprovante.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirModalLancamento({Map<String, dynamic>? transacao}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModalLancamento(
          uid: widget.uid,
          transacao: transacao,
          onSalvou: widget.onDadosAtualizados,
        );
      },
    );
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> transacao) async {
    final id = transacao['id']?.toString();
    if (id == null || id.isEmpty) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11182E),
          title: const Text(
            'Excluir lançamento',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Esse registro financeiro será removido permanentemente.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await _transacaoService.delete(id);
    await widget.onDadosAtualizados();
  }

  @override
  Widget build(BuildContext context) {
    final transacoesFiltradas = _transacoesFiltradas;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = AppResponsive.pagePadding(width);
        final contentWidth = AppResponsive.maxContentWidth(width);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Finanças',
                            style: TextStyle(
                              fontSize: AppResponsive.headingSize(width),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () => _abrirModalLancamento(),
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo do mês atual',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _construirLinhaResumo(
                                  titulo: 'Receitas',
                                  valor: _formatarMoeda(widget.totalReceitas),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _construirLinhaResumo(
                                  titulo: 'Despesas',
                                  valor: _formatarMoeda(widget.totalGastos),
                                  alinhamento: CrossAxisAlignment.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saldo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _formatarMoeda(widget.saldo),
                                style: TextStyle(
                                  color: widget.saldo >= 0
                                      ? Colors.white
                                      : Colors.red.shade100,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _construirChipFiltro(
                          label: 'Todos',
                          ativo: _filtroTipo == 'todos',
                          onTap: () => setState(() => _filtroTipo = 'todos'),
                        ),
                        _construirChipFiltro(
                          label: 'Receitas',
                          ativo: _filtroTipo == 'receita',
                          onTap: () => setState(() => _filtroTipo = 'receita'),
                        ),
                        _construirChipFiltro(
                          label: 'Despesas',
                          ativo: _filtroTipo == 'despesa',
                          onTap: () => setState(() => _filtroTipo = 'despesa'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _construirChipFiltro(
                          label: 'Mês atual',
                          ativo: _filtroPeriodo == 'mes',
                          onTap: () => setState(() => _filtroPeriodo = 'mes'),
                        ),
                        _construirChipFiltro(
                          label: 'Ultimos 90 dias',
                          ativo: _filtroPeriodo == '90dias',
                          onTap: () =>
                              setState(() => _filtroPeriodo = '90dias'),
                        ),
                        _construirChipFiltro(
                          label: 'Tudo',
                          ativo: _filtroPeriodo == 'tudo',
                          onTap: () => setState(() => _filtroPeriodo = 'tudo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _construirGraficoDespesasPorCategoria(transacoesFiltradas),
                    const SizedBox(height: 24),
                    const Text(
                      'Lançamentos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (transacoesFiltradas.isEmpty)
                      _construirVazio()
                    else
                      Column(
                        children: transacoesFiltradas
                            .map(
                              (transacao) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _construirCardTransacao(transacao),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirLinhaResumo({
    required String titulo,
    required String valor,
    CrossAxisAlignment alinhamento = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alinhamento,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _construirChipFiltro({
    required String label,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: ativo
              ? const Color(0xFF6366F1)
              : const Color(0xFF1A1F3A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ativo
                ? const Color(0xFF6366F1)
                : const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _construirCardTransacao(Map<String, dynamic> transacao) {
    final tipo = transacao['tipo']?.toString() ?? 'despesa';
    final cor = tipo == 'receita'
        ? const Color(0xFF10B981)
        : const Color(0xFFF97316);
    final data = _converterParaDateTime(transacao['data']);
    final categoria = transacao['categoria']?.toString() ?? 'Sem categoria';
    final observacao = transacao['observacao']?.toString() ?? '';
    final comprovanteBase64 = transacao['comprovanteBase64']?.toString();
    final temComprovante =
        comprovanteBase64 != null && comprovanteBase64.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tipo == 'receita'
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: cor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transacao['titulo']?.toString() ?? 'Lançamento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoria,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                if (observacao.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    observacao,
                    style: TextStyle(color: Colors.white.withOpacity(0.55)),
                  ),
                ],
                if (temComprovante) ...[
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _visualizarComprovante(comprovanteBase64),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 14,
                              color: Color(0xFF93C5FD),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Ver comprovante',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatarMoeda(_converterParaDouble(transacao['valor'])),
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data != null ? _formatarData(data) : 'Sem data',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1A1F3A),
                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                onSelected: (valor) {
                  if (valor == 'editar') {
                    _abrirModalLancamento(transacao: transacao);
                  } else {
                    _confirmarExclusao(transacao);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Text(
                      'Editar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Text(
                      'Excluir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 58,
            color: Colors.white.withOpacity(0.26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum lançamento encontrado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre uma receita ou despesa para começar a acompanhar sua vida financeira.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _abrirModalLancamento(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo lançamento'),
          ),
        ],
      ),
    );
  }
}

class _ModalLancamento extends StatefulWidget {
  const _ModalLancamento({
    required this.uid,
    required this.onSalvou,
    this.transacao,
  });

  final String uid;
  final Future<void> Function() onSalvou;
  final Map<String, dynamic>? transacao;

  @override
  State<_ModalLancamento> createState() => _ModalLancamentoState();
}

class _ModalLancamentoState extends State<_ModalLancamento> {
  final _formKey = GlobalKey<FormState>();
  final _transacaoService = TransacaoService();
  final _imagePicker = ImagePicker();
  final _controladorTitulo = TextEditingController();
  final _controladorValor = TextEditingController();
  final _controladorObservacao = TextEditingController();

  final List<String> _categorias = const [
    'Salario',
    'Freela',
    'Alimentacao',
    'Transporte',
    'Moradia',
    'Saude',
    'Lazer',
    'Outros',
  ];

  String _tipo = 'despesa';
  String _categoria = 'Outros';
  String? _comprovanteBase64;
  DateTime? _data;
  bool _salvando = false;
  bool _salvo = false;

  bool get _editando => widget.transacao != null;

  @override
  void initState() {
    super.initState();
    _controladorTitulo.text = widget.transacao?['titulo']?.toString() ?? '';
    _controladorObservacao.text =
        widget.transacao?['observacao']?.toString() ?? '';
    _tipo = widget.transacao?['tipo']?.toString() ?? 'despesa';
    _categoria = widget.transacao?['categoria']?.toString() ?? 'Outros';
    _comprovanteBase64 = widget.transacao?['comprovanteBase64']?.toString();
    _controladorValor.text = _formatarValorInicial(widget.transacao?['valor']);

    final data = widget.transacao?['data'];
    if (data is Timestamp) {
      _data = data.toDate();
    } else if (data is DateTime) {
      _data = data;
    }
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorValor.dispose();
    _controladorObservacao.dispose();
    super.dispose();
  }

  String _formatarValorInicial(dynamic valor) {
    if (valor is num) {
      return _formatarNumeroReal(valor.toDouble());
    }
    return '';
  }

  double _parseValor() {
    return _parseMoedaBrasileira(_controladorValor.text.trim());
  }

  double _parseMoedaBrasileira(String valor) {
    final textoLimpo = valor.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (textoLimpo.isEmpty) {
      return 0;
    }

    final normalizado = textoLimpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  String _formatarNumeroReal(double valor) {
    return _CurrencyBrInputFormatter.formatar(valor);
  }

  Uint8List? _decodificarComprovante() {
    if (_comprovanteBase64 == null || _comprovanteBase64!.trim().isEmpty) {
      return null;
    }

    try {
      return base64Decode(_comprovanteBase64!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarComprovante() async {
    try {
      final imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1280,
      );

      if (imagem == null) {
        return;
      }

      final bytes = await imagem.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _comprovanteBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _mostrarMensagem('Não foi possível selecionar a imagem.');
    }
  }

  void _removerComprovante() {
    setState(() {
      _comprovanteBase64 = null;
    });
  }

  void _visualizarComprovante() {
    final imagem = _decodificarComprovante();
    if (imagem == null) {
      _mostrarMensagem('Não foi possível abrir o comprovante.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F1729),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comprovante',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _baixarComprovante(imagem),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Baixar'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: Image.memory(imagem, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _baixarComprovante(Uint8List imagem) async {
    try {
      await FileSaver.instance.saveFile(
        name: 'comprovante_taskledger_${DateTime.now().millisecondsSinceEpoch}',
        bytes: imagem,
        fileExtension: 'jpg',
        mimeType: MimeType.jpeg,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprovante baixado com sucesso.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível baixar o comprovante.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data ?? agora,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF11182E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selecionada != null) {
      setState(() {
        _data = selecionada;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _data == null) {
      _mostrarMensagem('Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    final transacao = TransacaoModel(
      id: widget.transacao?['id']?.toString(),
      uid: widget.uid,
      titulo: _controladorTitulo.text.trim(),
      tipo: _tipo,
      categoria: _categoria,
      valor: _parseValor(),
      data: _data,
      observacao: _controladorObservacao.text.trim(),
      comprovanteBase64: _comprovanteBase64,
    );

    try {
      if (_editando) {
        await _transacaoService.update(transacao);
      } else {
        await _transacaoService.create(transacao);
      }

      await widget.onSalvou();

      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
        _salvo = true;
      });

      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _salvando = false;
      });
      _mostrarMensagem('Não foi possível salvar o lançamento.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final alturaMaxima =
        size.height * AppResponsive.modalMaxHeightFactor(size.width);
    final larguraMaxima = AppResponsive.modalMaxWidth(size.width);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: alturaMaxima,
              maxWidth: larguraMaxima,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1729),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _salvo ? _construirSucesso() : _construirFormulario(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirFormulario() {
    return SingleChildScrollView(
      key: const ValueKey('formulario_lancamento'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _editando ? 'Editar lançamento' : 'Novo lançamento',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registre receitas e despesas com contexto suficiente para acompanhar seu dinheiro.',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
            ),
            const SizedBox(height: 24),
            _construirCampoTexto(
              controlador: _controladorTitulo,
              label: 'Título',
              teclado: TextInputType.text,
              textInputAction: TextInputAction.next,
              aoEnviar: (_) => FocusScope.of(context).nextFocus(),
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Digite um título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _construirDropdown(
              label: 'Tipo',
              valor: _tipo,
              itens: const {'receita': 'Receita', 'despesa': 'Despesa'},
              onChanged: (valor) => setState(() => _tipo = valor!),
            ),
            const SizedBox(height: 16),
            _construirDropdown(
              label: 'Categoria',
              valor: _categoria,
              itens: {
                for (final categoria in _categorias) categoria: categoria,
              },
              onChanged: (valor) => setState(() => _categoria = valor!),
            ),
            const SizedBox(height: 16),
            _construirCampoTexto(
              controlador: _controladorValor,
              label: 'Valor',
              teclado: const TextInputType.numberWithOptions(decimal: true),
              formatadores: const [_CurrencyBrInputFormatter()],
              textInputAction: TextInputAction.next,
              aoEnviar: (_) => FocusScope.of(context).nextFocus(),
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Digite um valor';
                }
                if (_parseValor() <= 0) {
                  return 'Digite um valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selecionarData,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F3A).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _data == null
                            ? 'Selecionar data'
                            : 'Data: ${_formatarData(_data!)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _construirCampoTexto(
              controlador: _controladorObservacao,
              label: 'Observação',
              teclado: TextInputType.multiline,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              validador: (_) => null,
            ),
            const SizedBox(height: 16),
            _construirCampoComprovante(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF6366F1)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _editando
                              ? 'Salvar alterações'
                              : 'Adicionar lançamento',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String label,
    required TextInputType teclado,
    int maxLines = 1,
    required String? Function(String?) validador,
    List<TextInputFormatter>? formatadores,
    TextInputAction? textInputAction,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: teclado,
      maxLines: maxLines,
      validator: validador,
      inputFormatters: formatadores,
      textInputAction: textInputAction,
      onFieldSubmitted: aoEnviar,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withOpacity(0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Widget _construirDropdown({
    required String label,
    required String valor,
    required Map<String, String> itens,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: valor,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withOpacity(0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.25),
          ),
        ),
      ),
      items: itens.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _construirCampoComprovante() {
    final imagem = _decodificarComprovante();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.white.withOpacity(0.72),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Comprovante',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selecionarComprovante,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(imagem == null ? 'Adicionar' : 'Trocar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anexe uma foto do comprovante para ter mais controle sobre suas despesas e receitas.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              height: 1.35,
            ),
          ),
          if (imagem != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  imagem,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _visualizarComprovante,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: const Color(0xFF6366F1).withOpacity(0.45),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Visualizar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removerComprovante,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA8A8),
                      side: BorderSide(color: Colors.red.withOpacity(0.45)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remover'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirSucesso() {
    return SizedBox(
      key: const ValueKey('sucesso_lancamento'),
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _editando ? 'Lançamento atualizado' : 'Lançamento registrado',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus dados financeiros foram salvos com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyBrInputFormatter extends TextInputFormatter {
  const _CurrencyBrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final valor = double.parse(digitos) / 100;
    final textoFormatado = formatar(valor);

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }

  static String formatar(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final decimal = partes[1];
    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      final indiceRestante = inteiro.length - i;
      buffer.write(inteiro[i]);
      if (indiceRestante > 1 && indiceRestante % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()},$decimal';
  }
}

class _CategoriaDespesaItem {
  const _CategoriaDespesaItem({
    required this.categoria,
    required this.total,
    required this.cor,
  });

  final String categoria;
  final double total;
  final Color cor;
}
