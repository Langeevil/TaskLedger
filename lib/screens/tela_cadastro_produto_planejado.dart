import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/produto_planejado.dart';
import '../services/imgbb_service.dart';
import '../services/produto_planejado_service.dart';
import '../utils/categorias_financeiras.dart';
import '../utils/responsive_utils.dart';

class TelaCadastroProdutoPlanejado extends StatefulWidget {
  const TelaCadastroProdutoPlanejado({super.key});

  @override
  State<TelaCadastroProdutoPlanejado> createState() =>
      _TelaCadastroProdutoPlanejadoState();
}

class _TelaCadastroProdutoPlanejadoState
    extends State<TelaCadastroProdutoPlanejado> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProdutoPlanejadoService();
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

  String get _categoriaFinal => _categoriaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorDescricao.dispose();
    _controladorCategoria.dispose();
    _controladorPreco.dispose();
    _controladorImagem.dispose();
    super.dispose();
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
    final categorias = await CategoriasFinanceiras.carregar();
    if (!mounted) {
      return;
    }

    setState(() {
      _categorias = categorias;
      if (!_categorias.contains(_categoriaSelecionada)) {
        _categoriaSelecionada = _categorias.isNotEmpty
            ? _categorias.first
            : 'Outros';
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
      (item) => item.toLowerCase() == categoria.trim().toLowerCase(),
      orElse: () => categoria.trim(),
    );

    setState(() {
      _categorias = categorias;
      _categoriaSelecionada = categoriaSalva;
    });
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

      final produto = ProdutoPlanejado(
        nome: _controladorNome.text.trim(),
        descricao: _controladorDescricao.text.trim(),
        categoria: _categoriaFinal,
        preco: _parsePreco(),
        imagem: imagemUrl.isEmpty ? null : imagemUrl,
        criadoEm: DateTime.now().toIso8601String(),
      );

      await _service.cadastrarProduto(produto);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Previsão de compra cadastrada com sucesso.'),
          backgroundColor: Color(0xFF6366F1),
        ),
      );
      Navigator.of(context).pop(true);
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
              final contentWidth = AppResponsive.modalMaxWidth(width);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Padding(
                      padding: padding,
                      child: Form(
                        key: _formKey,
                        child: Column(
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
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1A1F3A),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar previsão de compra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cadastre itens para planejar gastos futuros.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirCardFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _construirCampoTexto(
            controlador: _controladorNome,
            label: 'Nome do item',
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
          const SizedBox(height: 16),
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
                label: Text(_salvando ? 'Salvando...' : 'Salvar previsão'),
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
          initialValue: _categorias.contains(_categoriaSelecionada)
              ? _categoriaSelecionada
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
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _salvando ? null : _abrirDialogNovaCategoria,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: const Color(0xFF6366F1).withValues(alpha: 0.45),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nova categoria'),
          ),
        ),
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
}
