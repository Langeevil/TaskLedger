import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({
    super.key,
    required this.uid,
    required this.tarefas,
    required this.onDadosAtualizados,
  });

  final String uid;
  final List<Map<String, dynamic>> tarefas;
  final Future<void> Function() onDadosAtualizados;

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  final _firestore = FirebaseFirestore.instance;
  String _filtroStatus = 'todos';
  String _filtroPrioridade = 'todas';
  bool _processando = false;

  List<Map<String, dynamic>> get _tarefasFiltradas {
    return widget.tarefas.where((tarefa) {
      final status = tarefa['status']?.toString() ?? 'a_fazer';
      final prioridade = tarefa['prioridade']?.toString() ?? 'media';

      final correspondeStatus =
          _filtroStatus == 'todos' || status == _filtroStatus;
      final correspondePrioridade =
          _filtroPrioridade == 'todas' || prioridade == _filtroPrioridade;

      return correspondeStatus && correspondePrioridade;
    }).toList()..sort((a, b) => _compararDatas(a['prazo'], b['prazo']));
  }

  int _compararDatas(dynamic esquerda, dynamic direita) {
    final dataEsquerda = _converterParaDateTime(esquerda);
    final dataDireita = _converterParaDateTime(direita);

    if (dataEsquerda == null && dataDireita == null) {
      return 0;
    }
    if (dataEsquerda == null) {
      return 1;
    }
    if (dataDireita == null) {
      return -1;
    }

    return dataEsquerda.compareTo(dataDireita);
  }

  DateTime? _converterParaDateTime(dynamic valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }
    if (valor is DateTime) {
      return valor;
    }
    if (valor is String && valor.trim().isNotEmpty) {
      return DateTime.tryParse(valor);
    }
    return null;
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _tituloStatus(String status) {
    switch (status) {
      case 'fazendo':
        return 'Fazendo';
      case 'concluido':
        return 'Concluido';
      default:
        return 'A Fazer';
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

  int _contarPorStatus(String status) {
    return widget.tarefas.where((tarefa) => tarefa['status'] == status).length;
  }

  Future<void> _atualizarStatusRapido(Map<String, dynamic> tarefa) async {
    final id = tarefa['id']?.toString();
    if (id == null || id.isEmpty || _processando) {
      return;
    }

    final statusAtual = tarefa['status']?.toString() ?? 'a_fazer';
    final novoStatus = statusAtual == 'concluido' ? 'a_fazer' : 'concluido';

    setState(() {
      _processando = true;
    });

    try {
      await _firestore.collection('tarefas').doc(id).update({
        'status': novoStatus,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      await widget.onDadosAtualizados();
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> tarefa) async {
    final id = tarefa['id']?.toString();
    if (id == null || id.isEmpty) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11182E),
          title: const Text(
            'Excluir tarefa',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Essa tarefa sera removida permanentemente.',
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

    await _firestore.collection('tarefas').doc(id).delete();
    await widget.onDadosAtualizados();
  }

  Future<void> _abrirModalTarefa({Map<String, dynamic>? tarefa}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModalTarefa(
          uid: widget.uid,
          tarefa: tarefa,
          onSalvou: widget.onDadosAtualizados,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tarefasFiltradas = _tarefasFiltradas;
    const secoes = ['a_fazer', 'fazendo', 'concluido'];

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
                    'Minhas Tarefas',
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
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => _abrirModalTarefa(),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _construirResumo(
                    titulo: 'A Fazer',
                    valor: _contarPorStatus('a_fazer').toString(),
                    cor: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirResumo(
                    titulo: 'Fazendo',
                    valor: _contarPorStatus('fazendo').toString(),
                    cor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _construirResumo(
                    titulo: 'Concluido',
                    valor: _contarPorStatus('concluido').toString(),
                    cor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _construirChipFiltro(
                    label: 'Todas',
                    ativo: _filtroStatus == 'todos',
                    onTap: () => setState(() => _filtroStatus = 'todos'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'A Fazer',
                    ativo: _filtroStatus == 'a_fazer',
                    onTap: () => setState(() => _filtroStatus = 'a_fazer'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Fazendo',
                    ativo: _filtroStatus == 'fazendo',
                    onTap: () => setState(() => _filtroStatus = 'fazendo'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Concluido',
                    ativo: _filtroStatus == 'concluido',
                    onTap: () => setState(() => _filtroStatus = 'concluido'),
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
                    label: 'Todas prioridades',
                    ativo: _filtroPrioridade == 'todas',
                    onTap: () => setState(() => _filtroPrioridade = 'todas'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Alta',
                    ativo: _filtroPrioridade == 'alta',
                    onTap: () => setState(() => _filtroPrioridade = 'alta'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Media',
                    ativo: _filtroPrioridade == 'media',
                    onTap: () => setState(() => _filtroPrioridade = 'media'),
                  ),
                  const SizedBox(width: 10),
                  _construirChipFiltro(
                    label: 'Baixa',
                    ativo: _filtroPrioridade == 'baixa',
                    onTap: () => setState(() => _filtroPrioridade = 'baixa'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (tarefasFiltradas.isEmpty)
              _construirVazio()
            else
              Column(
                children: secoes.map((status) {
                  final itens = tarefasFiltradas
                      .where((tarefa) => tarefa['status'] == status)
                      .toList();
                  if (itens.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _construirSecaoStatus(status, itens),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _construirResumo({
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
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

  Widget _construirSecaoStatus(
    String status,
    List<Map<String, dynamic>> tarefas,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withOpacity(0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tituloStatus(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...tarefas.map(
            (tarefa) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirCardTarefa(tarefa),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCardTarefa(Map<String, dynamic> tarefa) {
    final prioridade = tarefa['prioridade']?.toString() ?? 'media';
    final prazo = _converterParaDateTime(tarefa['prazo']);
    final status = tarefa['status']?.toString() ?? 'a_fazer';
    final vencida =
        prazo != null &&
        prazo.isBefore(DateTime.now()) &&
        status != 'concluido';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vencida
            ? const Color(0xFF2D1720).withOpacity(0.9)
            : const Color(0xFF1A1F3A).withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vencida
              ? const Color(0xFFEF4444).withOpacity(0.35)
              : const Color(0xFF6366F1).withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: status == 'concluido',
            onChanged: (_) => _atualizarStatusRapido(tarefa),
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
                        tarefa['titulo']?.toString() ?? 'Sem titulo',
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
                          _abrirModalTarefa(tarefa: tarefa);
                        } else {
                          _confirmarExclusao(tarefa);
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
                if ((tarefa['descricao']?.toString().trim().isNotEmpty ??
                    false)) ...[
                  const SizedBox(height: 6),
                  Text(
                    tarefa['descricao'].toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _construirBadge(
                      texto: prioridade.toUpperCase(),
                      cor: _corPrioridade(prioridade),
                    ),
                    _construirBadge(
                      texto: _tituloStatus(status),
                      cor: const Color(0xFF6366F1),
                    ),
                    if (prazo != null)
                      _construirBadge(
                        texto: vencida
                            ? 'Vencida em ${_formatarData(prazo)}'
                            : 'Prazo ${_formatarData(prazo)}',
                        cor: vencida
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF38BDF8),
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

  Widget _construirBadge({required String texto, required Color cor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700),
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
          Icon(Icons.task_alt, size: 58, color: Colors.white.withOpacity(0.26)),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma tarefa encontrada',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira tarefa ou ajuste os filtros para ver outros itens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _abrirModalTarefa(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nova tarefa'),
          ),
        ],
      ),
    );
  }
}

class _ModalTarefa extends StatefulWidget {
  const _ModalTarefa({required this.uid, required this.onSalvou, this.tarefa});

  final String uid;
  final Map<String, dynamic>? tarefa;
  final Future<void> Function() onSalvou;

  @override
  State<_ModalTarefa> createState() => _ModalTarefaState();
}

class _ModalTarefaState extends State<_ModalTarefa> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _controladorTitulo = TextEditingController();
  final _controladorDescricao = TextEditingController();

  String _status = 'a_fazer';
  String _prioridade = 'media';
  DateTime? _prazo;
  bool _salvando = false;
  bool _salvo = false;

  bool get _editando => widget.tarefa != null;

  @override
  void initState() {
    super.initState();
    _controladorTitulo.text = widget.tarefa?['titulo']?.toString() ?? '';
    _controladorDescricao.text = widget.tarefa?['descricao']?.toString() ?? '';
    _status = widget.tarefa?['status']?.toString() ?? 'a_fazer';
    _prioridade = widget.tarefa?['prioridade']?.toString() ?? 'media';

    final prazo = widget.tarefa?['prazo'];
    if (prazo is Timestamp) {
      _prazo = prazo.toDate();
    } else if (prazo is DateTime) {
      _prazo = prazo;
    }
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescricao.dispose();
    super.dispose();
  }

  Future<void> _selecionarPrazo() async {
    final agora = DateTime.now();
    final selecionado = await showDatePicker(
      context: context,
      initialDate: _prazo ?? agora,
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

    if (selecionado != null) {
      setState(() {
        _prazo = selecionado;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _prazo == null) {
      _mostrarMensagem('Defina um prazo para a tarefa.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    final dados = <String, dynamic>{
      'uid': widget.uid,
      'titulo': _controladorTitulo.text.trim(),
      'descricao': _controladorDescricao.text.trim(),
      'status': _status,
      'prioridade': _prioridade,
      'prazo': Timestamp.fromDate(_prazo!),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    try {
      if (_editando) {
        await _firestore
            .collection('tarefas')
            .doc(widget.tarefa!['id'])
            .update(dados);
      } else {
        await _firestore.collection('tarefas').add({
          ...dados,
          'criadoEm': FieldValue.serverTimestamp(),
        });
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
      _mostrarMensagem('Nao foi possivel salvar a tarefa.');
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
    final alturaMaxima = MediaQuery.of(context).size.height * 0.72;
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
      key: const ValueKey('formulario_tarefa'),
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
              _editando ? 'Editar tarefa' : 'Nova tarefa',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Organize seu fluxo com prazo, prioridade e status.',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
            ),
            const SizedBox(height: 24),
            _construirCampoTexto(
              controlador: _controladorTitulo,
              label: 'Titulo',
              maxLines: 1,
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
            _construirCampoTexto(
              controlador: _controladorDescricao,
              label: 'Descricao',
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              validador: (_) => null,
            ),
            const SizedBox(height: 16),
            _construirDropdown(
              label: 'Status',
              valor: _status,
              itens: const {
                'a_fazer': 'A Fazer',
                'fazendo': 'Fazendo',
                'concluido': 'Concluido',
              },
              onChanged: (valor) => setState(() => _status = valor!),
            ),
            const SizedBox(height: 16),
            _construirDropdown(
              label: 'Prioridade',
              valor: _prioridade,
              itens: const {'alta': 'Alta', 'media': 'Media', 'baixa': 'Baixa'},
              onChanged: (valor) => setState(() => _prioridade = valor!),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selecionarPrazo,
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
                        _prazo == null
                            ? 'Selecionar prazo'
                            : 'Prazo: ${_formatarData(_prazo!)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                      : Text(_editando ? 'Salvar alteracoes' : 'Criar tarefa'),
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
    required int maxLines,
    required String? Function(String?) validador,
    TextInputAction? textInputAction,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      maxLines: maxLines,
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
      key: const ValueKey('sucesso_tarefa'),
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
              _editando ? 'Tarefa atualizada' : 'Tarefa criada',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As informacoes da tarefa foram salvas com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
