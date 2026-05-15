import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/produto_compra.dart';
import '../services/produto_compra_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/categorias_financeiras.dart';
import '../utils/responsive_utils.dart';
import 'tela_cadastro_produto_compra.dart';
import 'tela_editar_produto_compra.dart';

class TelaCatalogoProdutos extends StatefulWidget {
  const TelaCatalogoProdutos({super.key});

  @override
  State<TelaCatalogoProdutos> createState() => _TelaCatalogoProdutosState();
}

class _TelaCatalogoProdutosState extends State<TelaCatalogoProdutos> {
  final _service = ProdutoCompraService();
  final _busca = TextEditingController();

  List<ProdutoCompra> _produtos = [];
  List<String> _categoriasCompartilhadas = [
    'Todas',
    ...CategoriasFinanceiras.padrao,
  ];
  String _categoria = 'Todas';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    CategoriasFinanceiras.versao.addListener(_aoCategoriasAtualizadas);
    _busca.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    CategoriasFinanceiras.versao.removeListener(_aoCategoriasAtualizadas);
    _busca.dispose();
    super.dispose();
  }

  void _aoCategoriasAtualizadas() {
    _carregarCategorias();
  }

  List<String> get _categorias {
    return _categoriasCompartilhadas;
  }

  List<ProdutoCompra> get _filtrados {
    final busca = _busca.text.trim().toLowerCase();
    return _produtos.where((produto) {
      final nomeOk =
          busca.isEmpty || produto.nome.toLowerCase().contains(busca);
      final categoriaOk =
          _categoria == 'Todas' || produto.categoria == _categoria;
      return nomeOk && categoriaOk;
    }).toList();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final produtos = await _service.listarProdutos();
      final categorias = await CategoriasFinanceiras.sincronizar(
        produtos.map((produto) => produto.categoria),
      );
      if (!mounted) return;
      setState(() {
        _produtos = produtos;
        _categoriasCompartilhadas = ['Todas', ...categorias];
        _carregando = false;
        if (!_categorias.contains(_categoria)) _categoria = 'Todas';
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _produtos = [];
        _carregando = false;
        _erro = '$erro';
      });
    }
  }

  Future<void> _carregarCategorias() async {
    final categorias = await CategoriasFinanceiras.carregar();
    if (!mounted) return;
    setState(() {
      _categoriasCompartilhadas = ['Todas', ...categorias];
      if (!_categorias.contains(_categoria)) _categoria = 'Todas';
    });
  }

  Future<void> _abrirCadastro() async {
    final salvou = await Navigator.of(
      context,
    ).push<bool>(_rotaSuave(const TelaCadastroProdutoCompra()));
    if (salvou == true) await _carregar();
  }

  Future<void> _abrirEdicao(ProdutoCompra produto) async {
    final salvou = await Navigator.of(
      context,
    ).push<bool>(_rotaSuave(TelaEditarProdutoCompra(produto: produto)));
    if (salvou == true) await _carregar();
  }

  PageRouteBuilder<T> _rotaSuave<T>(Widget tela) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => tela,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _confirmarExclusao(ProdutoCompra produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11182E),
        title: const Text(
          'Excluir produto',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'O produto "${produto.nome}" será removido do catálogo.',
          style: const TextStyle(color: Colors.white70),
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
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.excluirProduto(produto.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto excluído com sucesso.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$erro'), backgroundColor: Colors.red),
      );
    }
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
              final pagePadding = padding.add(
                EdgeInsets.only(top: AppResponsive.isMobile(width) ? 16 : 24),
              );
              final contentWidth = AppResponsive.maxContentWidth(width);

              return RefreshIndicator(
                onRefresh: _carregar,
                color: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1A1F3A),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Padding(
                        padding: pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cabecalho(width),
                            const SizedBox(height: 20),
                            _filtros(width),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _conteudo(width),
                            ),
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

  Widget _cabecalho(double width) {
    return Row(
      children: [
        _botaoVoltar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catálogo de Produtos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppResponsive.headingSize(width),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre e mantenha os produtos usados nos orçamentos.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _abrirCadastro,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              AppResponsive.isMobile(width) ? 'Novo' : 'Novo produto',
            ),
          ),
        ),
      ],
    );
  }

  Widget _botaoVoltar() {
    return InkWell(
      onTap: () => Navigator.pop(context),
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

  Widget _filtros(double width) {
    final busca = TextField(
      controller: _busca,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Buscar por nome', Icons.search),
    );
    final filtro = DropdownButtonFormField<String>(
      initialValue: _categoria,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Categoria', Icons.category_outlined),
      items: _categorias
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (valor) => setState(() => _categoria = valor ?? 'Todas'),
    );

    if (AppResponsive.isMobile(width)) {
      return Column(children: [busca, const SizedBox(height: 12), filtro]);
    }
    return Row(
      children: [
        Expanded(child: busca),
        const SizedBox(width: 12),
        Expanded(child: filtro),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      filled: true,
      fillColor: const Color(0xFF1A1F3A).withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6366F1).withValues(alpha: 0.22),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
    );
  }

  Widget _conteudo(double width) {
    if (_carregando) {
      return const Center(
        key: ValueKey('catalogo_loading'),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }
    if (_erro != null) {
      return _estado(
        Icons.cloud_off_outlined,
        'Não foi possível carregar o catálogo',
        _erro!,
        FilledButton.icon(
          onPressed: _carregar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
        key: const ValueKey('catalogo_erro'),
      );
    }
    final produtos = _filtrados;
    if (produtos.isEmpty) {
      return _estado(
        Icons.inventory_2_outlined,
        'Nenhum produto encontrado',
        'Cadastre produtos para montar orçamentos de compra.',
        FilledButton.icon(
          onPressed: _abrirCadastro,
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar produto'),
        ),
        key: const ValueKey('catalogo_vazio'),
      );
    }

    final columns = AppResponsive.gridColumns(
      width,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      landscape: MediaQuery.of(context).orientation == Orientation.landscape,
    );
    final itemWidth = AppResponsive.itemWidth(
      availableWidth: AppResponsive.maxContentWidth(
        width,
      ).clamp(0, width).toDouble(),
      columns: columns,
      spacing: 14,
    );
    return Wrap(
      key: ValueKey('catalogo_lista_${produtos.length}_$_categoria'),
      spacing: 14,
      runSpacing: 14,
      children: produtos
          .map((produto) => SizedBox(width: itemWidth, child: _card(produto)))
          .toList(),
    );
  }

  Widget _card(ProdutoCompra produto) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A).withValues(alpha: 0.94),
            const Color(0xFF11182E).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(produto),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _categoriaBadge(produto.categoria),
                const SizedBox(height: 10),
                Text(
                  produto.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  produto.descricao.isEmpty
                      ? 'Sem descrição informada.'
                      : produto.descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppCurrencyUtils.format(produto.preco),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirEdicao(produto),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _confirmarExclusao(produto),
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFFFA8A8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagem(ProdutoCompra produto) {
    final imagem = produto.imagem?.trim();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imagem == null || imagem.isEmpty
            ? _placeholder()
            : _imagemInformada(imagem),
      ),
    );
  }

  Widget _imagemInformada(String imagem) {
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      return Image.network(
        imagem,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    try {
      return Image.memory(
        base64Decode(imagem),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF11182E), Color(0xFF1A1F3A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 42,
          color: Colors.white.withValues(alpha: 0.32),
        ),
      ),
    );
  }

  Widget _categoriaBadge(String categoria) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        categoria.isEmpty ? 'Sem categoria' : categoria,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFC4B5FD),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _estado(
    IconData icone,
    String titulo,
    String mensagem,
    Widget? acao, {
    Key? key,
  }) {
    return Container(
      key: key,
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
          Icon(icone, size: 58, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
          if (acao != null) ...[const SizedBox(height: 20), acao],
        ],
      ),
    );
  }
}
