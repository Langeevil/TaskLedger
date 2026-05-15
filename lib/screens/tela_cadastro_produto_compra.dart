import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/produto_compra.dart';
import '../services/imgbb_service.dart';
import '../services/produto_compra_service.dart';
import '../utils/categorias_financeiras.dart';
import '../utils/responsive_utils.dart';

class TelaCadastroProdutoCompra extends StatefulWidget {
  const TelaCadastroProdutoCompra({super.key, this.produto});

  final ProdutoCompra? produto;

  @override
  State<TelaCadastroProdutoCompra> createState() =>
      _TelaCadastroProdutoCompraState();
}

class _TelaCadastroProdutoCompraState extends State<TelaCadastroProdutoCompra> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProdutoCompraService();
  final _imgbbService = ImgbbService();
  final _imagePicker = ImagePicker();
  final _controladorNome = TextEditingController();
  final _controladorDescricao = TextEditingController();
  final _controladorCategoria = TextEditingController();
  final _controladorPreco = TextEditingController();
  final _controladorImagem = TextEditingController();

  String? _imagemBase64;
  List<String> _categorias = [...CategoriasFinanceiras.padrao];
  String _categoriaSelecionada = 'Outros';
  bool _salvando = false;
  bool _salvo = false;
  bool _categoriaAnimando = false;

  bool get _editando => widget.produto != null;

  String get _categoriaFinal => _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    CategoriasFinanceiras.versao.addListener(_aoCategoriasAtualizadas);
    final produto = widget.produto;
    if (produto != null) {
      _controladorNome.text = produto.nome;
      _controladorDescricao.text = produto.descricao;
      _controladorPreco.text = _formatarPrecoInicial(produto.preco);
      _controladorImagem.text = produto.imagem ?? '';
      _categoriaSelecionada = produto.categoria.isEmpty
          ? 'Outros'
          : produto.categoria;
    }
    _carregarCategorias();
  }

  @override
  void dispose() {
    CategoriasFinanceiras.versao.removeListener(_aoCategoriasAtualizadas);
    _controladorNome.dispose();
    _controladorDescricao.dispose();
    _controladorCategoria.dispose();
    _controladorPreco.dispose();
    _controladorImagem.dispose();
    super.dispose();
  }

  void _aoCategoriasAtualizadas() {
    _carregarCategorias();
  }

  String _formatarPrecoInicial(double preco) {
    if (preco <= 0) {
      return '';
    }
    return preco.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _parsePreco() {
    final texto = _controladorPreco.text.trim();
    final somenteNumero = texto.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (somenteNumero.isEmpty) {
      return 0;
    }

    if (somenteNumero.contains(',')) {
      final normalizado = somenteNumero
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.tryParse(normalizado) ?? 0;
    }

    return double.tryParse(somenteNumero) ?? 0;
  }

  Future<void> _carregarCategorias() async {
    var categorias = await CategoriasFinanceiras.carregar();
    if (_categoriaSelecionada.trim().isNotEmpty &&
        !CategoriasFinanceiras.contem(categorias, _categoriaSelecionada)) {
      categorias = await CategoriasFinanceiras.sincronizar([
        _categoriaSelecionada,
      ]);
    }
    if (_categoriaSelecionada.trim().isNotEmpty) {
      _categoriaSelecionada = CategoriasFinanceiras.resolver(
        categorias,
        _categoriaSelecionada,
      );
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _categorias = categorias;
      if (!CategoriasFinanceiras.contem(_categorias, _categoriaSelecionada)) {
        if (_categoriaSelecionada.trim().isNotEmpty) {
          _categorias = [..._categorias, _categoriaSelecionada]..sort();
        } else {
          _categoriaSelecionada = _categorias.isNotEmpty
              ? _categorias.first
              : 'Outros';
        }
      }
    });
  }

  Future<void> _abrirDialogNovaCategoria() async {
    _controladorCategoria.clear();

    final categoria = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11182E),
          title: const Text(
            'Nova categoria',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _controladorCategoria,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nome da categoria',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              filled: true,
              fillColor: const Color(0xFF1A1F3A).withValues(alpha: 0.75),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                ),
              ),
            ),
            onSubmitted: (_) {
              Navigator.pop(context, _controladorCategoria.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, _controladorCategoria.text.trim());
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (categoria == null || categoria.trim().isEmpty) {
      return;
    }

    final categorias = await CategoriasFinanceiras.adicionar(categoria);
    if (!mounted) {
      return;
    }

    final categoriaSalva = categorias.firstWhere(
      (item) => CategoriasFinanceiras.equivalente(item, categoria),
      orElse: () => categoria.trim(),
    );

    setState(() {
      _categorias = categorias;
      _categoriaSelecionada = categoriaSalva;
      _categoriaAnimando = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _categoriaAnimando = false);
    }
  }

  Uint8List? _imagemSelecionadaBytes() {
    final imagemBase64 = _imagemBase64;
    if (imagemBase64 == null || imagemBase64.isEmpty) {
      return null;
    }

    try {
      return base64Decode(imagemBase64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final imagem = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (imagem == null) {
        return;
      }

      final bytes = await imagem.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _imagemBase64 = base64Encode(bytes);
        _controladorImagem.clear();
      });
    } catch (_) {
      _mostrarMensagem('Não foi possível selecionar a imagem.');
    }
  }

  void _removerImagemSelecionada() {
    setState(() {
      _imagemBase64 = null;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final imagemUrl = _imagemBase64 != null && _imagemBase64!.isNotEmpty
          ? await _imgbbService.uploadBase64(_imagemBase64!)
          : _controladorImagem.text.trim();

      final produto = ProdutoCompra(
        id: widget.produto?.id ?? '',
        nome: _controladorNome.text.trim(),
        descricao: _controladorDescricao.text.trim(),
        categoria: _categoriaFinal,
        preco: _parsePreco(),
        imagem: imagemUrl.isEmpty ? null : imagemUrl,
        criadoEm: widget.produto?.criadoEm ?? DateTime.now().toIso8601String(),
      );

      if (_editando) {
        await _service.editarProduto(produto);
      } else {
        await _service.cadastrarProduto(produto);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
        _salvo = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (erro) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$erro'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
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
              final pagePadding = padding.add(
                EdgeInsets.only(top: AppResponsive.isMobile(width) ? 16 : 24),
              );
              final contentWidth = AppResponsive.modalMaxWidth(width);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: pagePadding,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.03),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _salvo
                            ? _construirSucesso()
                            : Form(
                                key: _formKey,
                                child: Column(
                                  key: const ValueKey('formulario_produto'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _construirCabecalho(),
                                    const SizedBox(height: 24),
                                    _construirCardFormulario(),
                                  ],
                                ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editando ? 'Editar produto' : 'Cadastrar produto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _editando
                    ? 'Atualize os dados do produto do catálogo.'
                    : 'Cadastre produtos para montar orçamentos de compra.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botaoVoltar() {
    return InkWell(
      onTap: () => Navigator.of(context).pop(false),
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

  Widget _construirCardFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F3A).withValues(alpha: 0.96),
            const Color(0xFF11182E).withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          _construirCampoTexto(
            controlador: _controladorNome,
            label: 'Nome do produto',
            icone: Icons.shopping_bag_outlined,
            textInputAction: TextInputAction.next,
            validador: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o nome do item.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _construirCampoTexto(
            controlador: _controladorDescricao,
            label: 'Descrição',
            icone: Icons.notes_outlined,
            teclado: TextInputType.multiline,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            validador: (_) => null,
          ),
          const SizedBox(height: 16),
          _construirCampoCategoria(),
          _construirCampoTexto(
            controlador: _controladorPreco,
            label: 'Preço previsto',
            icone: Icons.payments_outlined,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validador: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o preço previsto.';
              }
              if (_parsePreco() <= 0) {
                return 'Informe um preço maior que zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _construirCampoImagem(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_salvando ? 'Salvando...' : 'Salvar produto'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String label,
    required IconData icone,
    required String? Function(String?) validador,
    TextInputType teclado = TextInputType.text,
    TextInputAction? textInputAction,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: teclado,
      textInputAction: textInputAction,
      maxLines: maxLines,
      validator: validador,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icone, color: Colors.white70),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFF0F1729).withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  Widget _construirCampoCategoria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_categoriaSelecionada),
          initialValue:
              CategoriasFinanceiras.contem(_categorias, _categoriaSelecionada)
              ? CategoriasFinanceiras.resolver(
                  _categorias,
                  _categoriaSelecionada,
                )
              : null,
          dropdownColor: const Color(0xFF1A1F3A),
          style: const TextStyle(color: Colors.white),
          validator: (valor) {
            if (valor == null || valor.trim().isEmpty) {
              return 'Informe a categoria.';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: Colors.white70,
            ),
            labelText: 'Categoria',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            filled: true,
            fillColor: const Color(0xFF0F1729).withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          items: _categorias
              .map(
                (categoria) => DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                ),
              )
              .toList(),
          onChanged: _salvando
              ? null
              : (valor) {
                  if (valor == null) {
                    return;
                  }

                  setState(() {
                    _categoriaSelecionada = valor;
                  });
                },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: AnimatedScale(
            scale: _categoriaAnimando ? 1.04 : 1,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: _categoriaAnimando
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _categoriaAnimando
                        ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                        : [const Color(0xFF312E81), const Color(0xFF4338CA)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: _salvando ? null : _abrirDialogNovaCategoria,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: Icon(
                    _categoriaAnimando ? Icons.check_rounded : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    _categoriaAnimando
                        ? 'Categoria adicionada'
                        : 'Nova categoria',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _construirCampoImagem() {
    final imagemBytes = _imagemSelecionadaBytes();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1729).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: Colors.white70),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Imagem opcional',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _salvando ? null : _selecionarImagem,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(imagemBytes == null ? 'Selecionar' : 'Trocar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione uma imagem do dispositivo. Ela será enviada ao ImgBB e o MockAPI receberá apenas a URL.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          if (imagemBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  imagemBytes,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salvando ? null : _removerImagemSelecionada,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFA8A8),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.45)),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remover imagem'),
            ),
          ] else ...[
            TextFormField(
              controller: _controladorImagem,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ou informe uma URL manualmente',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1F3A).withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF6366F1),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirSucesso() {
    return SizedBox(
      key: const ValueKey('sucesso_produto'),
      height: MediaQuery.of(context).size.height * 0.72,
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
            Text(
              _editando ? 'Produto atualizado' : 'Produto cadastrado',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O catálogo foi atualizado com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
