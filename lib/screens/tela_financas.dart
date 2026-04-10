import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transacao_model.dart';
import '../services/transacao_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/app_date_utils.dart';

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
            'Excluir lancamento',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Esse registro financeiro sera removido permanentemente.',
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Financas',
                    style: TextStyle(
                      fontSize: 28,
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
                    'Resumo do mes atual',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _construirLinhaResumo(
                          titulo: 'Receitas',
                          valor: _formatarMoeda(widget.totalReceitas),
                        ),
                      ),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirChipFiltro(
                    label: 'Todos',
                    ativo: _filtroTipo == 'todos',
                    onTap: () => setState(() => _filtroTipo = 'todos'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Receitas',
                    ativo: _filtroTipo == 'receita',
                    onTap: () => setState(() => _filtroTipo = 'receita'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Despesas',
                    ativo: _filtroTipo == 'despesa',
                    onTap: () => setState(() => _filtroTipo = 'despesa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirChipFiltro(
                    label: 'Mes atual',
                    ativo: _filtroPeriodo == 'mes',
                    onTap: () => setState(() => _filtroPeriodo = 'mes'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Ultimos 90 dias',
                    ativo: _filtroPeriodo == '90dias',
                    onTap: () => setState(() => _filtroPeriodo = '90dias'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Tudo',
                    ativo: _filtroPeriodo == 'tudo',
                    onTap: () => setState(() => _filtroPeriodo = 'tudo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Lancamentos',
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
                  transacao['titulo']?.toString() ?? 'Lancamento',
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
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text(
                      'Editar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem(
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
            'Nenhum lancamento encontrado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registre uma receita ou despesa para comecar a acompanhar sua vida financeira.',
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
            label: const Text('Novo lancamento'),
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
      _mostrarMensagem('Preencha todos os campos obrigatorios.');
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
      _mostrarMensagem('Nao foi possivel salvar o lancamento.');
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
    final alturaMaxima = MediaQuery.of(context).size.height * 0.76;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: alturaMaxima),
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
              _editando ? 'Editar lancamento' : 'Novo lancamento',
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
              label: 'Titulo',
              teclado: TextInputType.text,
              textInputAction: TextInputAction.next,
              aoEnviar: (_) => FocusScope.of(context).nextFocus(),
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Digite um titulo';
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
                  return 'Digite um valor valido';
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
              label: 'Observacao',
              teclado: TextInputType.multiline,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              validador: (_) => null,
            ),
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
                              ? 'Salvar alteracoes'
                              : 'Adicionar lancamento',
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
              _editando ? 'Lancamento atualizado' : 'Lancamento registrado',
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
