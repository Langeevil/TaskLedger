import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/planejamento_model.dart';
import '../services/imgbb_service.dart';
import '../services/planejamento_service.dart';
import '../utils/app_date_utils.dart';
import '../utils/responsive_utils.dart';

Widget _cabecalhoImagem(
  BuildContext context, {
  required VoidCallback onDownload,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Imagem anexada',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Baixar'),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    ),
  );
}

Future<void> _baixarImagemBytes(BuildContext context, Uint8List imagem) async {
  try {
    await FileSaver.instance.saveFile(
      name: 'planejamento_taskledger_${DateTime.now().millisecondsSinceEpoch}',
      bytes: imagem,
      fileExtension: 'jpg',
      mimeType: MimeType.jpeg,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagem baixada com sucesso.'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível baixar a imagem.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _baixarImagemUrl(BuildContext context, String url) async {
  try {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Erro ao baixar imagem: ${response.statusCode}');
    }

    if (!context.mounted) return;
    await _baixarImagemBytes(context, response.bodyBytes);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível baixar a imagem.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class TelaPlanejamento extends StatefulWidget {
  const TelaPlanejamento({super.key, required this.uid});

  final String uid;

  @override
  State<TelaPlanejamento> createState() => _TelaPlanejamentoState();
}

class _TelaPlanejamentoState extends State<TelaPlanejamento> {
  final _service = PlanejamentoService();
  var _planejamentos = <Map<String, dynamic>>[];
  var _status = 'todos';
  var _prioridade = 'todas';
  var _carregando = true;
  var _processando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  List<Map<String, dynamic>> get _filtrados {
    return _planejamentos.where((item) {
        final status = item['status']?.toString() ?? 'a_fazer';
        final prioridade = item['prioridade']?.toString() ?? 'media';
        return (_status == 'todos' || status == _status) &&
            (_prioridade == 'todas' || prioridade == _prioridade);
      }).toList()
      ..sort((a, b) => AppDateUtils.compareNullable(a['data'], b['data']));
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _service.listByUser(widget.uid);
      if (!mounted) return;
      setState(() {
        _planejamentos = dados.map((item) => item.toMap()).toList();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar: $e';
      });
    }
  }

  DateTime? _data(dynamic valor) => AppDateUtils.parse(valor);

  String _formatarData(DateTime data) => AppDateUtils.format(data);

  String _tituloStatus(String status) {
    switch (status) {
      case 'em_andamento':
        return 'Em andamento';
      case 'concluido':
        return 'Concluído';
      default:
        return 'Planejado';
    }
  }

  Color _corPrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return const Color(0xFFEF4444);
      case 'baixa':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  int _contar(String status) {
    return _planejamentos.where((item) => item['status'] == status).length;
  }

  Uint8List? _decodificarImagem(String? base64) {
    if (base64 == null || base64.trim().isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  void _visualizarImagem(String? base64) {
    final imagem = _decodificarImagem(base64);
    if (imagem == null) {
      _mensagem('Não foi possível abrir a imagem.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F1729),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cabecalhoImagem(
              context,
              onDownload: () => _baixarImagemBytes(context, imagem),
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
      ),
    );
  }

  void _visualizarImagemUrl(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F1729),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cabecalhoImagem(
              context,
              onDownload: () => _baixarImagemUrl(context, url),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarStatus(Map<String, dynamic> planejamento) async {
    final id = planejamento['id']?.toString();
    if (id == null || id.isEmpty || _processando) return;

    final atual = planejamento['status']?.toString() ?? 'a_fazer';
    final novo = atual == 'concluido' ? 'a_fazer' : 'concluido';

    setState(() => _processando = true);
    try {
      await _service.updateStatus(id: id, status: novo);
      await _carregar();
    } catch (e) {
      _mensagem('Não foi possível atualizar o status: $e');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _excluir(Map<String, dynamic> planejamento) async {
    final id = planejamento['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11182E),
        title: const Text(
          'Excluir planejamento',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esse planejamento será removido permanentemente.',
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
      ),
    );

    if (confirmou != true) return;

    try {
      await _service.delete(id);
      await _carregar();
    } catch (e) {
      _mensagem('Não foi possível excluir: $e');
    }
  }

  Future<void> _abrirModal({Map<String, dynamic>? planejamento}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalPlanejamento(
        uid: widget.uid,
        planejamento: planejamento,
        onSalvou: _carregar,
      ),
    );
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = AppResponsive.pagePadding(width);
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
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Planejamento',
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
                                colors: [Color(0xFF14B8A6), Color(0xFF6366F1)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              onPressed: () => _abrirModal(),
                              icon: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2B1B1B,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFF6B6B)),
                          ),
                          child: Text(
                            _erro!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _resumoGrid(
                        width: width,
                        children: [
                          _resumo(
                            'Planejados',
                            _contar('a_fazer').toString(),
                            const Color(0xFF6366F1),
                          ),
                          _resumo(
                            'Em andamento',
                            _contar('em_andamento').toString(),
                            const Color(0xFFF59E0B),
                          ),
                          _resumo(
                            'Concluídos',
                            _contar('concluido').toString(),
                            const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _filtrosStatus(),
                      const SizedBox(height: 12),
                      _filtrosPrioridade(),
                      const SizedBox(height: 24),
                      if (_filtrados.isEmpty)
                        _vazio()
                      else
                        Column(
                          children: _filtrados
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _card(item),
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
          ),
        );
      },
    );
  }

  Widget _resumoGrid({required double width, required List<Widget> children}) {
    final columns = AppResponsive.gridColumns(
      width,
      mobile: 1,
      tablet: 3,
      desktop: 3,
    );
    final availableWidth =
        (AppResponsive.maxContentWidth(width)).clamp(0, width) -
        AppResponsive.pagePadding(width).horizontal;
    final itemWidth = AppResponsive.itemWidth(
      availableWidth: availableWidth,
      columns: columns,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map((child) => SizedBox(width: itemWidth, child: child))
          .toList(),
    );
  }

  Widget _resumo(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
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
      ),
    );
  }

  Widget _filtrosStatus() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(
          'Todos',
          _status == 'todos',
          () => setState(() => _status = 'todos'),
        ),
        _chip(
          'Planejados',
          _status == 'a_fazer',
          () => setState(() => _status = 'a_fazer'),
        ),
        _chip(
          'Em andamento',
          _status == 'em_andamento',
          () => setState(() => _status = 'em_andamento'),
        ),
        _chip(
          'Concluídos',
          _status == 'concluido',
          () => setState(() => _status = 'concluido'),
        ),
      ],
    );
  }

  Widget _filtrosPrioridade() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(
          'Todas prioridades',
          _prioridade == 'todas',
          () => setState(() => _prioridade = 'todas'),
        ),
        _chip(
          'Alta',
          _prioridade == 'alta',
          () => setState(() => _prioridade = 'alta'),
        ),
        _chip(
          'Média',
          _prioridade == 'media',
          () => setState(() => _prioridade = 'media'),
        ),
        _chip(
          'Baixa',
          _prioridade == 'baixa',
          () => setState(() => _prioridade = 'baixa'),
        ),
      ],
    );
  }

  Widget _chip(String label, bool ativo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: ativo
              ? const Color(0xFF6366F1)
              : const Color(0xFF1A1F3A).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ativo
                ? const Color(0xFF6366F1)
                : const Color(0xFF6366F1).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final prioridade = item['prioridade']?.toString() ?? 'media';
    final status = item['status']?.toString() ?? 'a_fazer';
    final data = _data(item['data']);
    final imagemUrl = item['imagemUrl']?.toString();
    final imagemBase64 = item['imagemBase64']?.toString();
    final temImagemUrl = imagemUrl != null && imagemUrl.trim().isNotEmpty;
    final temImagemBase64 =
        imagemBase64 != null && imagemBase64.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: status == 'concluido',
            onChanged: (_) => _alternarStatus(item),
            fillColor: WidgetStateProperty.all(_corPrioridade(prioridade)),
            side: BorderSide(color: _corPrioridade(prioridade), width: 2),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['titulo']?.toString() ?? 'Sem título',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: status == 'concluido'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: const Color(0xFF1A1F3A),
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                      onSelected: (valor) {
                        if (valor == 'editar') {
                          _abrirModal(planejamento: item);
                        } else {
                          _excluir(item);
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
                if ((item['descricao']?.toString().trim().isNotEmpty ??
                    false)) ...[
                  const SizedBox(height: 6),
                  Text(
                    item['descricao'].toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _badge(
                      prioridade.toUpperCase(),
                      _corPrioridade(prioridade),
                    ),
                    _badge(_tituloStatus(status), const Color(0xFF6366F1)),
                    if (data != null)
                      _badge(_formatarData(data), const Color(0xFF38BDF8)),
                    if (temImagemUrl)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _visualizarImagemUrl(imagemUrl),
                          child: _badge('VER IMAGEM', const Color(0xFF14B8A6)),
                        ),
                      )
                    else if (temImagemBase64)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _visualizarImagem(imagemBase64),
                          child: _badge('VER IMAGEM', const Color(0xFF14B8A6)),
                        ),
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

  Widget _badge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _vazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 58,
            color: Colors.white.withValues(alpha: 0.26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum planejamento encontrado',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie seu primeiro planejamento ou ajuste os filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _abrirModal(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo planejamento'),
          ),
        ],
      ),
    );
  }
}

class _ModalPlanejamento extends StatefulWidget {
  const _ModalPlanejamento({
    required this.uid,
    required this.onSalvou,
    this.planejamento,
  });

  final String uid;
  final Future<void> Function() onSalvou;
  final Map<String, dynamic>? planejamento;

  @override
  State<_ModalPlanejamento> createState() => _ModalPlanejamentoState();
}

class _ModalPlanejamentoState extends State<_ModalPlanejamento> {
  final _formKey = GlobalKey<FormState>();
  final _service = PlanejamentoService();
  final _imgbbService = ImgbbService();
  final _picker = ImagePicker();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();

  var _status = 'a_fazer';
  var _prioridade = 'media';
  String? _imagemUrl;
  String? _imagemBase64;
  DateTime? _data;
  var _salvando = false;
  var _salvo = false;

  bool get _editando => widget.planejamento != null;

  @override
  void initState() {
    super.initState();
    _titulo.text = widget.planejamento?['titulo']?.toString() ?? '';
    _descricao.text = widget.planejamento?['descricao']?.toString() ?? '';
    _status = widget.planejamento?['status']?.toString() ?? 'a_fazer';
    _prioridade = widget.planejamento?['prioridade']?.toString() ?? 'media';
    _imagemUrl = widget.planejamento?['imagemUrl']?.toString();
    _imagemBase64 = widget.planejamento?['imagemBase64']?.toString();
    _data = AppDateUtils.parse(widget.planejamento?['data']);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Uint8List? _imagem() {
    if (_imagemBase64 == null || _imagemBase64!.trim().isEmpty) return null;
    try {
      return base64Decode(_imagemBase64!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final imagem = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      final base64 = base64Encode(bytes);

      if (!mounted) return;
      setState(() {
        _imagemBase64 = base64;
        _imagemUrl = null;
      });
    } catch (_) {
      _mensagem('Não foi possível selecionar a imagem.');
    }
  }

  void _visualizarImagem() {
    final imagem = _imagem();
    if (_imagemUrl != null && _imagemUrl!.trim().isNotEmpty) {
      _visualizarImagemUrl(_imagemUrl!);
      return;
    }
    if (imagem == null) {
      _mensagem('Não foi possível abrir a imagem.');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F1729),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cabecalhoImagem(
              context,
              onDownload: () => _baixarImagemBytes(context, imagem),
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
      ),
    );
  }

  void _visualizarImagemUrl(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F1729),
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cabecalhoImagem(
              context,
              onDownload: () => _baixarImagemUrl(context, url),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data ?? agora,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            surface: Color(0xFF11182E),
          ),
        ),
        child: child!,
      ),
    );

    if (selecionada != null) setState(() => _data = selecionada);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _data == null) {
      _mensagem('Preencha todos os campos obrigatórios.');
      return;
    }

    setState(() => _salvando = true);

    try {
      final imagemUrl = _imagemBase64 != null && _imagemBase64!.isNotEmpty
          ? await _imgbbService.uploadBase64(_imagemBase64!)
          : _imagemUrl;

      final planejamento = PlanejamentoModel(
        id: widget.planejamento?['id']?.toString(),
        uid: widget.uid,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        data: _data,
        prioridade: _prioridade,
        status: _status,
        imagemUrl: imagemUrl,
        imagemBase64: null,
      );

      if (_editando) {
        await _service.update(planejamento);
      } else {
        await _service.create(planejamento);
      }

      await widget.onSalvou();
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _salvo = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mensagem('Não foi possível salvar o planejamento: $e');
    }
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).size.height * 0.78,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final altura = size.height * AppResponsive.modalMaxHeightFactor(size.width);
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
              maxHeight: altura,
              maxWidth: larguraMaxima,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1729),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _salvo ? _sucesso() : _formulario(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return SingleChildScrollView(
      key: const ValueKey('formulario_planejamento'),
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _editando ? 'Editar planejamento' : 'Novo planejamento',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize objetivos com data, prioridade, status e imagem.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 24),
            _campoTexto(_titulo, 'Título', 1, (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Digite um título';
              }
              return null;
            }, TextInputAction.next),
            const SizedBox(height: 16),
            _campoTexto(
              _descricao,
              'Descrição',
              4,
              (_) => null,
              TextInputAction.newline,
            ),
            const SizedBox(height: 16),
            _campoData(),
            const SizedBox(height: 16),
            _dropdown(
              'Prioridade',
              _prioridade,
              const {'alta': 'Alta', 'media': 'Média', 'baixa': 'Baixa'},
              (valor) {
                setState(() => _prioridade = valor!);
              },
            ),
            const SizedBox(height: 16),
            _dropdown(
              'Status',
              _status,
              const {
                'a_fazer': 'Planejado',
                'em_andamento': 'Em andamento',
                'concluido': 'Concluído',
              },
              (valor) {
                setState(() => _status = valor!);
              },
            ),
            const SizedBox(height: 16),
            _campoImagem(),
            const SizedBox(height: 28),
            _botaoSalvar(),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(
    TextEditingController controlador,
    String label,
    int maxLines,
    String? Function(String?) validador,
    TextInputAction action,
  ) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      maxLines: maxLines,
      textInputAction: action,
      onFieldSubmitted: (_) =>
          maxLines == 1 ? FocusScope.of(context).nextFocus() : null,
      style: const TextStyle(color: Colors.white),
      decoration: _decoracao(label),
    );
  }

  InputDecoration _decoracao(String label) {
    return InputDecoration(
      labelText: label,
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
    );
  }

  Widget _campoData() {
    return InkWell(
      onTap: _selecionarData,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _data == null
                    ? 'Selecionar data'
                    : 'Data: ${AppDateUtils.format(_data!)}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String valor,
    Map<String, String> itens,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: valor,
      dropdownColor: const Color(0xFF1A1F3A),
      style: const TextStyle(color: Colors.white),
      decoration: _decoracao(label),
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

  Widget _campoImagem() {
    final imagem = _imagem();
    final temImagemUrl = _imagemUrl != null && _imagemUrl!.trim().isNotEmpty;
    final temImagem = imagem != null || temImagemUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: Colors.white.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Imagem',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selecionarImagem,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(temImagem ? 'Trocar' : 'Anexar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anexe uma imagem de referência para esse planejamento.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
          if (temImagem) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: temImagemUrl
                    ? Image.network(
                        _imagemUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Image.memory(
                        imagem!,
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
                    onPressed: _visualizarImagem,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Visualizar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _imagemBase64 = null;
                        _imagemUrl = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA8A8),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.45),
                      ),
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

  Widget _botaoSalvar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF14B8A6), Color(0xFF6366F1)],
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_editando ? 'Salvar alterações' : 'Criar planejamento'),
        ),
      ),
    );
  }

  Widget _sucesso() {
    return SizedBox(
      key: const ValueKey('sucesso_planejamento'),
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
              _editando ? 'Planejamento atualizado' : 'Planejamento criado',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As informações foram salvas no JSONBin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
