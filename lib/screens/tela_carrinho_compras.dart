import 'package:flutter/material.dart';

import '../models/item_carrinho.dart';
import '../models/transacao_model.dart';
import '../services/transacao_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/responsive_utils.dart';

class TelaCarrinhoCompras extends StatefulWidget {
  const TelaCarrinhoCompras({
    super.key,
    required this.uid,
    required this.itens,
    required this.onDespesaRegistrada,
  });

  final String uid;
  final List<ItemCarrinho> itens;
  final Future<void> Function() onDespesaRegistrada;

  @override
  State<TelaCarrinhoCompras> createState() => _TelaCarrinhoComprasState();
}

class _TelaCarrinhoComprasState extends State<TelaCarrinhoCompras> {
  final _transacaoService = TransacaoService();
  final _controladorCupom = TextEditingController();
  bool _cupomTask10Aplicado = false;
  bool _registrandoDespesa = false;
  bool _carrinhoSaindo = false;
  bool _registroConcluido = false;

  double get _subtotal {
    return widget.itens.fold<double>(0, (total, item) => total + item.subtotal);
  }

  double get _desconto => _cupomTask10Aplicado ? _subtotal * 0.1 : 0;

  double get _total => _subtotal - _desconto;

  @override
  void dispose() {
    _controladorCupom.dispose();
    super.dispose();
  }

  void _incrementar(ItemCarrinho item) {
    setState(() {
      item.quantidade++;
    });
  }

  void _decrementar(ItemCarrinho item) {
    setState(() {
      item.quantidade--;
      if (item.quantidade <= 0) {
        widget.itens.remove(item);
      }
    });
  }

  void _remover(ItemCarrinho item) {
    setState(() {
      widget.itens.remove(item);
    });
  }

  void _limparTudo() {
    setState(() {
      widget.itens.clear();
      _cupomTask10Aplicado = false;
      _controladorCupom.clear();
    });
  }

  void _aplicarCupom() {
    final cupom = _controladorCupom.text.trim().toUpperCase();
    if (cupom == 'TASK10') {
      setState(() {
        _cupomTask10Aplicado = true;
      });
      _mostrarMensagem('Cupom TASK10 aplicado ao orçamento.');
      return;
    }

    _mostrarMensagem('Cupom inválido para este planejamento.', erro: true);
  }

  Future<void> _registrarComoDespesa() async {
    if (widget.itens.isEmpty || _registrandoDespesa) {
      return;
    }

    setState(() {
      _registrandoDespesa = true;
    });

    final transacao = TransacaoModel(
      uid: widget.uid,
      titulo: 'Orçamento de compras',
      tipo: 'despesa',
      categoria: 'Compras',
      valor: _total,
      data: DateTime.now(),
      observacao: _observacaoDaDespesa(),
    );

    try {
      await _transacaoService.create(transacao);
      await widget.onDespesaRegistrada();

      if (!mounted) {
        return;
      }

      setState(() {
        _registrandoDespesa = false;
        _carrinhoSaindo = true;
      });

      await Future.delayed(const Duration(milliseconds: 720));
      if (!mounted) {
        return;
      }

      setState(() {
        widget.itens.clear();
        _cupomTask10Aplicado = false;
        _controladorCupom.clear();
        _carrinhoSaindo = false;
        _registroConcluido = true;
      });

      await Future.delayed(const Duration(milliseconds: 1300));
      if (mounted) {
        Navigator.of(context).pop(widget.itens);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _registrandoDespesa = false;
      });
      _mostrarMensagem('Não foi possível registrar a despesa.', erro: true);
    }
  }

  String _observacaoDaDespesa() {
    final linhas = widget.itens
        .map((item) {
          return '${item.quantidade}x ${item.produto.nome} - ${AppCurrencyUtils.format(item.subtotal)}';
        })
        .join('\n');

    final desconto = _desconto > 0
        ? '\nDesconto aplicado: ${AppCurrencyUtils.format(_desconto)}'
        : '';

    return 'Registrado a partir do carrinho de orçamento.\n$linhas$desconto';
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red : const Color(0xFF6366F1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF11182E)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final padding = AppResponsive.pagePadding(width);
              final contentWidth = AppResponsive.maxContentWidth(width);

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _carrinhoSaindo || _registroConcluido
                    ? _construirAnimacaoFinalizacao()
                    : SingleChildScrollView(
                        key: const ValueKey('carrinho_conteudo'),
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: Padding(
                              padding: padding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _construirCabecalho(),
                                  const SizedBox(height: 24),
                                  if (widget.itens.isEmpty)
                                    _construirVazio()
                                  else ...[
                                    _construirListaItens(),
                                    const SizedBox(height: 18),
                                    _construirCupom(),
                                    const SizedBox(height: 18),
                                    _construirResumo(),
                                  ],
                                  const SizedBox(height: 28),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _construirCabecalho() {
    return Row(
      children: [
        _botaoVoltar(),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Carrinho de Orçamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Revise quantidades e o total previsto.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (widget.itens.isNotEmpty)
          TextButton.icon(
            onPressed: _limparTudo,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Limpar Tudo'),
          ),
      ],
    );
  }

  Widget _botaoVoltar() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(widget.itens),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _construirListaItens() {
    return Column(
      children: widget.itens
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirItemCarrinho(item),
            ),
          )
          .toList(),
    );
  }

  Widget _construirItemCarrinho(ItemCarrinho item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produto.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Preço unitário: ${AppCurrencyUtils.format(item.produto.preco)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _remover(item),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _construirBotaoQuantidade(
                icone: Icons.remove,
                onTap: () => _decrementar(item),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${item.quantidade}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _construirBotaoQuantidade(
                icone: Icons.add,
                onTap: () => _incrementar(item),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    AppCurrencyUtils.format(item.subtotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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

  Widget _construirBotaoQuantidade({
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1729),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.28),
          ),
        ),
        child: Icon(icone, color: Colors.white),
      ),
    );
  }

  Widget _construirCupom() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controladorCupom,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cupom',
                hintText: 'TASK10',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _aplicarCupom,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Widget _construirResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _construirLinhaResumo(
            'Subtotal geral',
            AppCurrencyUtils.format(_subtotal),
          ),
          if (_cupomTask10Aplicado)
            _construirLinhaResumo(
              'Desconto TASK10',
              '- ${AppCurrencyUtils.format(_desconto)}',
            ),
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          _construirLinhaResumo(
            'Total previsto',
            AppCurrencyUtils.format(_total),
            destaque: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _registrandoDespesa ? null : _registrarComoDespesa,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
              ),
              icon: _registrandoDespesa
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4F46E5),
                        ),
                      ),
                    )
                  : const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                _registrandoDespesa
                    ? 'Registrando...'
                    : 'Registrar como despesa',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAnimacaoFinalizacao() {
    return SizedBox(
      key: ValueKey(_carrinhoSaindo ? 'carrinho_saindo' : 'registro_sucesso'),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _carrinhoSaindo
              ? _construirCarrinhoSaindo()
              : _construirCheckSucesso(),
        ),
      ),
    );
  }

  Widget _construirCarrinhoSaindo() {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('animacao_carrinho_saida'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        final deslocamento = value * 170;
        final opacidade = (1 - value * 0.55).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacidade,
          child: Transform.translate(
            offset: Offset(deslocamento, 0),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_cart_checkout_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Registrando orçamento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enviando o total previsto para o financeiro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _construirCheckSucesso() {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('animacao_check_sucesso'),
      tween: Tween<double>(begin: 0.82, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
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
          const Text(
            'Despesa registrada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'O orçamento foi enviado para o controle financeiro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _construirLinhaResumo(
    String titulo,
    String valor, {
    bool destaque = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: destaque ? 1 : 0.78),
                fontSize: destaque ? 18 : 14,
                fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: Colors.white,
              fontSize: destaque ? 22 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 58,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum item no carrinho',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione produtos ao carrinho para calcular o total previsto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}
