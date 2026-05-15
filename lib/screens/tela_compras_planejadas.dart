import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/item_carrinho.dart';
import '../models/produto_planejado.dart';
import '../services/produto_planejado_service.dart';
import '../utils/app_currency_utils.dart';
import '../utils/responsive_utils.dart';
import 'tela_cadastro_produto_planejado.dart';
import 'tela_carrinho_compras.dart';

class TelaComprasPlanejadas extends StatefulWidget {
  const TelaComprasPlanejadas({
    super.key,
    required this.uid,
    required this.onDespesaRegistrada,
  });

  final String uid;
  final Future<void> Function() onDespesaRegistrada;

  @override
  State<TelaComprasPlanejadas> createState() => _TelaComprasPlanejadasState();
}

class _TelaComprasPlanejadasState extends State<TelaComprasPlanejadas> {
  final _service = ProdutoPlanejadoService();
  final _controladorBusca = TextEditingController();
  final List<ItemCarrinho> _itensCarrinho = [];

  List<ProdutoPlanejado> _produtos = [];
  String _categoriaSelecionada = 'Todas';
  bool _carregando = true;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _controladorBusca.addListener(() => setState(() {}));
    _carregarProdutos();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  List<String> get _categorias {
    final categorias =
        _produtos
            .map((produto) => produto.categoria.trim())
            .where((categoria) => categoria.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['Todas', ...categorias];
  }

  List<ProdutoPlanejado> get _produtosFiltrados {
    final busca = _controladorBusca.text.trim().toLowerCase();

    return _produtos.where((produto) {
      final correspondeNome =
          busca.isEmpty || produto.nome.toLowerCase().contains(busca);
      final correspondeCategoria =
          _categoriaSelecionada == 'Todas' ||
          produto.categoria == _categoriaSelecionada;
      return correspondeNome && correspondeCategoria;
    }).toList();
  }

  int get _quantidadeCarrinho {
    return _itensCarrinho.fold<int>(
      0,
      (total, item) => total + item.quantidade,
    );
  }

  Future<void> _carregarProdutos() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final produtos = await _service.listarProdutos();
      if (!mounted) {
        return;
      }

      setState(() {
        _produtos = produtos;
        _carregando = false;
        if (!_categorias.contains(_categoriaSelecionada)) {
          _categoriaSelecionada = 'Todas';
        }
      });
    } catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _produtos = [];
        _carregando = false;
        _mensagemErro = '$erro';
      });
    }
  }

  Future<void> _abrirCadastroProduto() async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TelaCadastroProdutoPlanejado(),
      ),
    );

    if (salvo == true) {
      await _carregarProdutos();
    }
  }

  Future<void> _abrirCarrinho() async {
    await Navigator.of(context).push<List<ItemCarrinho>>(
      MaterialPageRoute(
        builder: (context) => TelaCarrinhoCompras(
          uid: widget.uid,
          itens: _itensCarrinho,
          onDespesaRegistrada: widget.onDespesaRegistrada,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _adicionarAoCarrinho(ProdutoPlanejado produto) {
    final itemExistente = _buscarItemCarrinho(produto);

    setState(() {
      if (itemExistente == null) {
        _itensCarrinho.add(ItemCarrinho(produto: produto));
      } else {
        itemExistente.quantidade++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produto.nome} adicionado ao planejamento.'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  bool _mesmoProduto(ProdutoPlanejado atual, ProdutoPlanejado novo) {
    if (atual.id.isNotEmpty && novo.id.isNotEmpty) {
      return atual.id == novo.id;
    }
    return atual.nome == novo.nome && atual.categoria == novo.categoria;
  }

  ItemCarrinho? _buscarItemCarrinho(ProdutoPlanejado produto) {
    for (final item in _itensCarrinho) {
      if (_mesmoProduto(item.produto, produto)) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = AppResponsive.pagePadding(width);
        final contentWidth = AppResponsive.maxContentWidth(width);

        return RefreshIndicator(
          onRefresh: _carregarProdutos,
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
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _construirCabecalho(width),
                      const SizedBox(height: 22),
                      _construirResumoPlanejamento(),
                      const SizedBox(height: 20),
                      _construirFiltros(width),
                      const SizedBox(height: 20),
                      _construirConteudo(width),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirCabecalho(double width) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compras Planejadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppResponsive.headingSize(width),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Organize itens futuros e estime o impacto no seu orçamento.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _construirBotaoIcone(
          icone: Icons.add,
          onTap: _abrirCadastroProduto,
          tooltip: 'Registrar previsão de compra',
        ),
        const SizedBox(width: 10),
        _construirBotaoCarrinho(),
      ],
    );
  }

  Widget _construirBotaoIcone({
    required IconData icone,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icone, color: Colors.white),
        ),
      ),
    );
  }

  Widget _construirBotaoCarrinho() {
    return Tooltip(
      message: 'Abrir carrinho de planejamento',
      child: InkWell(
        onTap: _abrirCarrinho,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.32),
                ),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF8B5CF6),
              ),
            ),
            if (_quantidadeCarrinho > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF0A0E27)),
                  ),
                  child: Text(
                    _quantidadeCarrinho > 9 ? '9+' : '$_quantidadeCarrinho',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirResumoPlanejamento() {
    final totalPrevisto = _itensCarrinho.fold<double>(
      0,
      (total, item) => total + item.subtotal,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _construirResumoItem(
              titulo: 'Itens planejados',
              valor: '$_quantidadeCarrinho',
            ),
          ),
          Container(
            width: 2,
            height: 46,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _construirResumoItem(
              titulo: 'Total previsto',
              valor: AppCurrencyUtils.format(totalPrevisto),
              alinhadoDireita: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumoItem({
    required String titulo,
    required String valor,
    bool alinhadoDireita = false,
  }) {
    return Column(
      crossAxisAlignment: alinhadoDireita
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _construirFiltros(double width) {
    if (AppResponsive.isMobile(width)) {
      return Column(
        children: [
          _construirCampoBusca(),
          const SizedBox(height: 12),
          _construirFiltroCategoria(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _construirCampoBusca()),
        const SizedBox(width: 12),
        Expanded(child: _construirFiltroCategoria()),
      ],
    );
  }

  Widget _construirCampoBusca() {
    return TextField(
      controller: _controladorBusca,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        hintText: 'Buscar por nome',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
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
      ),
    );
  }

  Widget _construirFiltroCategoria() {
    final categorias = _categorias;

    return DropdownButtonFormField<String>(
      initialValue: _categoriaSelecionada,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.category_outlined, color: Colors.white70),
        labelText: 'Categoria',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          ),
        ),
      ),
      items: categorias
          .map(
            (categoria) => DropdownMenuItem<String>(
              value: categoria,
              child: Text(categoria),
            ),
          )
          .toList(),
      onChanged: (valor) {
        if (valor == null) {
          return;
        }
        setState(() {
          _categoriaSelecionada = valor;
        });
      },
    );
  }

  Widget _construirConteudo(double width) {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

    if (_mensagemErro != null) {
      return _construirEstadoInformativo(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível carregar as compras planejadas',
        mensagem: _mensagemErro!,
        acao: FilledButton.icon(
          onPressed: _carregarProdutos,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    final produtos = _produtosFiltrados;
    if (produtos.isEmpty) {
      return _construirEstadoInformativo(
        icone: Icons.shopping_bag_outlined,
        titulo: 'Nenhum produto planejado encontrado',
        mensagem:
            'Cadastre itens que pretende comprar para prever despesas futuras.',
        acao: FilledButton.icon(
          onPressed: _abrirCadastroProduto,
          icon: const Icon(Icons.add),
          label: const Text('Registrar previsão'),
        ),
      );
    }

    final columns = AppResponsive.gridColumns(
      width,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      landscape: MediaQuery.of(context).orientation == Orientation.landscape,
    );
    final availableWidth = AppResponsive.maxContentWidth(
      width,
    ).clamp(0, width).toDouble();
    final itemWidth = AppResponsive.itemWidth(
      availableWidth: availableWidth,
      columns: columns,
      spacing: 14,
    );

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: produtos
          .map(
            (produto) => SizedBox(
              width: itemWidth,
              child: _construirCardProduto(produto),
            ),
          )
          .toList(),
    );
  }

  Widget _construirCardProduto(ProdutoPlanejado produto) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirImagemProduto(produto),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _construirCategoria(produto.categoria),
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _adicionarAoCarrinho(produto),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Adicionar ao planejamento'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirImagemProduto(ProdutoPlanejado produto) {
    final imagem = produto.imagem?.trim();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: imagem == null || imagem.isEmpty
            ? _construirPlaceholderImagem()
            : _construirImagemInformada(imagem),
      ),
    );
  }

  Widget _construirImagemInformada(String imagem) {
    if (imagem.startsWith('http://') || imagem.startsWith('https://')) {
      return Image.network(
        imagem,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _construirPlaceholderImagem(),
      );
    }

    final bytes = _decodificarBase64(imagem);
    if (bytes == null) {
      return _construirPlaceholderImagem();
    }

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _construirPlaceholderImagem(),
    );
  }

  Uint8List? _decodificarBase64(String valor) {
    try {
      return base64Decode(valor);
    } catch (_) {
      return null;
    }
  }

  Widget _construirPlaceholderImagem() {
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

  Widget _construirCategoria(String categoria) {
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

  Widget _construirEstadoInformativo({
    required IconData icone,
    required String titulo,
    required String mensagem,
    Widget? acao,
  }) {
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
