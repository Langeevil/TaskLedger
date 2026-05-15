import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/user_service.dart';
import '../utils/responsive_utils.dart';

import 'tela_compras_planejadas.dart';
import 'tela_configuracoes.dart';
import 'tela_financas.dart';
import 'tela_perfil.dart';
import 'tela_planejamento.dart';
import 'tela_relatorios.dart';
import 'tela_tarefas.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final _authService = AuthService();
  final _dashboardService = DashboardService();
  final _userService = UserService();

  int _indiceTelaAtual = 0;
  late User _usuarioAtual;

  Map<String, dynamic> _dadosUsuario = {};
  List<Map<String, dynamic>> _tarefas = [];
  List<Map<String, dynamic>> _transacoes = [];

  int _totalTarefas = 0;
  double _totalGastos = 0;
  double _totalReceitas = 0;
  double _saldo = 0;
  bool _carregando = true;
  String? _mensagemErro;
  final Set<String> _notificacoesVisualizadas = <String>{};

  @override
  void initState() {
    super.initState();
    _usuarioAtual = _authService.currentUser!;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final dashboardData = await _dashboardService.carregarDados(
        uid: _usuarioAtual.uid,
        email: _usuarioAtual.email ?? 'Não informado',
      );

      final dadosUsuario = dashboardData.usuario.toMap();
      final tarefas = dashboardData.tarefas
          .map((tarefa) => tarefa.toMap())
          .toList();
      final transacoes = dashboardData.transacoes
          .map((transacao) => transacao.toMap())
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _mensagemErro = null;
        _dadosUsuario = _normalizarDadosUsuario(dadosUsuario);
        _notificacoesVisualizadas
          ..clear()
          ..addAll(_extrairNotificacoesVisualizadas(dadosUsuario));
        _tarefas = tarefas;
        _transacoes = transacoes;
        _totalTarefas = dashboardData.totalTarefas;
        _totalReceitas = dashboardData.totalReceitas;
        _totalGastos = dashboardData.totalGastos;
        _saldo = dashboardData.saldo;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dadosUsuario = _normalizarDadosUsuario({
          'uid': _usuarioAtual.uid,
          'email': _usuarioAtual.email ?? 'Não informado',
        });
        _tarefas = [];
        _transacoes = [];
        _totalTarefas = 0;
        _totalReceitas = 0;
        _totalGastos = 0;
        _saldo = 0;
        _carregando = false;
        _mensagemErro = 'Não foi possível carregar seus dados agora.';
      });
    }
  }

  Map<String, dynamic> _normalizarDadosUsuario(Map<String, dynamic> dados) {
    final email = dados['email']?.toString().trim().isNotEmpty == true
        ? dados['email'].toString().trim()
        : (_usuarioAtual.email ?? 'Não informado');

    final nome = dados['nome']?.toString().trim().isNotEmpty == true
        ? dados['nome'].toString().trim()
        : _gerarNomeFallback(email);

    final telefone = dados['telefone']?.toString().trim().isNotEmpty == true
        ? dados['telefone'].toString().trim()
        : 'Não informado';

    return {
      ...dados,
      'uid': dados['uid'] ?? _usuarioAtual.uid,
      'email': email,
      'nome': nome,
      'telefone': telefone,
    };
  }

  List<String> _extrairNotificacoesVisualizadas(Map<String, dynamic> dados) {
    final visualizadas = dados['notificacoesVisualizadas'];
    if (visualizadas is! List) {
      return <String>[];
    }

    return visualizadas.map((item) => item.toString()).toList();
  }

  String _gerarNomeFallback(String email) {
    final parteLocal = email.split('@').first.trim();
    if (parteLocal.isEmpty) {
      return 'Usuário';
    }

    final nome = parteLocal.replaceAll('.', ' ');
    return nome[0].toUpperCase() + nome.substring(1);
  }

  String _obterPrimeiroNome(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.trim().isEmpty) {
      return 'Usuário';
    }

    return nomeCompleto.trim().split(RegExp(r'\s+')).first;
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

  double _converterParaDouble(dynamic valor) {
    if (valor is num) {
      return valor.toDouble();
    }
    if (valor is String) {
      return _parseMoedaBrasileira(valor);
    }
    return 0;
  }

  String _formatarMoeda(double valor) {
    final numero = _formatarNumeroReal(valor.abs());
    final sinal = valor < 0 ? '-' : '';
    return '${sinal}R\$ $numero';
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

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _obterMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return meses[mes - 1];
  }

  List<Map<String, dynamic>> _obterNotificacoes() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final notificacoes = <Map<String, dynamic>>[];

    for (final tarefa in _tarefas) {
      final status = tarefa['status']?.toString() ?? 'a_fazer';
      if (status == 'concluido') {
        continue;
      }

      final prazo = _converterParaDateTime(tarefa['prazo']);
      if (prazo == null) {
        continue;
      }

      final dataPrazo = DateTime(prazo.year, prazo.month, prazo.day);
      final titulo = tarefa['titulo']?.toString() ?? 'Tarefa';

      if (dataPrazo.isBefore(hoje)) {
        notificacoes.add({
          'tipo': 'tarefa',
          'titulo': 'Tarefa vencida',
          'mensagem': '$titulo ficou pendente após ${_formatarData(prazo)}.',
          'icone': Icons.warning_amber_rounded,
          'cor': const Color(0xFFEF4444),
          'ordem': 0,
        });
      } else if (dataPrazo == hoje) {
        notificacoes.add({
          'tipo': 'tarefa',
          'titulo': 'Prazo para hoje',
          'mensagem': '$titulo vence hoje.',
          'icone': Icons.event_available,
          'cor': const Color(0xFFF59E0B),
          'ordem': 1,
        });
      }
    }

    if (_saldo < 0) {
      notificacoes.add({
        'tipo': 'financas',
        'titulo': 'Saldo negativo',
        'mensagem': 'Seu saldo atual está em ${_formatarMoeda(_saldo)}.',
        'icone': Icons.account_balance_wallet_outlined,
        'cor': const Color(0xFFEF4444),
        'ordem': 2,
      });
    }

    final transacoesRecentes = _transacoes.take(5);
    for (final transacao in transacoesRecentes) {
      final tipo = transacao['tipo']?.toString() ?? 'despesa';
      final valor = _converterParaDouble(transacao['valor']);
      final titulo = transacao['titulo']?.toString() ?? 'Lançamento';
      final data = _converterParaDateTime(transacao['data']);

      if (tipo == 'despesa' && valor >= 300) {
        notificacoes.add({
          'tipo': 'financas',
          'titulo': 'Despesa relevante',
          'mensagem':
              '$titulo registrou ${_formatarMoeda(valor)}${data != null ? ' em ${_formatarData(data)}' : ''}.',
          'icone': Icons.trending_down,
          'cor': const Color(0xFFF97316),
          'ordem': 3,
        });
      }
    }

    notificacoes.sort(
      (a, b) => (a['ordem'] as int).compareTo(b['ordem'] as int),
    );
    return notificacoes;
  }

  String _identificadorNotificacao(Map<String, dynamic> notificacao) {
    return [
      notificacao['tipo']?.toString() ?? '',
      notificacao['titulo']?.toString() ?? '',
      notificacao['mensagem']?.toString() ?? '',
    ].join('|');
  }

  List<Map<String, dynamic>> _obterNotificacoesNaoVisualizadas() {
    return _obterNotificacoes().where((notificacao) {
      return !_notificacoesVisualizadas.contains(
        _identificadorNotificacao(notificacao),
      );
    }).toList();
  }

  void _abrirAssuntoDaNotificacao(Map<String, dynamic> notificacao) {
    Navigator.of(context).pop();

    final tipo = notificacao['tipo']?.toString() ?? '';
    final mensagem = notificacao['mensagem']?.toString() ?? '';

    setState(() {
      _indiceTelaAtual = tipo == 'tarefa' ? 1 : 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _abrirCentralNotificacoes() {
    final notificacoes = _obterNotificacoes();
    final idsVisualizados = notificacoes.map(_identificadorNotificacao);

    setState(() {
      _notificacoesVisualizadas.addAll(idsVisualizados);
    });
    _salvarNotificacoesVisualizadas();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1729),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notificações',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${notificacoes.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: notificacoes.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 56,
                                  color: Colors.white.withOpacity(0.26),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhuma notificação no momento',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Quando houver tarefas urgentes ou alertas financeiros, eles aparecerão aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          itemCount: notificacoes.length,
                          itemBuilder: (context, index) {
                            final notificacao = notificacoes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _construirItemNotificacao(
                                notificacao,
                                onTap: () =>
                                    _abrirAssuntoDaNotificacao(notificacao),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _salvarNotificacoesVisualizadas() async {
    try {
      await _userService.updateViewedNotifications(
        uid: _usuarioAtual.uid,
        notificacoesVisualizadas: _notificacoesVisualizadas.toList(),
      );
    } catch (_) {
      // A notificação continua marcada na sessão atual mesmo se a persistência falhar.
    }
  }

  void _atualizarDadosPerfil(Map<String, dynamic> novosDados) {
    setState(() {
      _dadosUsuario = _normalizarDadosUsuario({
        ..._dadosUsuario,
        ...novosDados,
      });
    });
  }

  Future<void> _sair() async {
    await _authService.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/');
  }

  Widget _construirTelaAtual() {
    switch (_indiceTelaAtual) {
      case 0:
        return _construirTelaInicio();
      case 1:
        return TelaTarefas(
          uid: _usuarioAtual.uid,
          tarefas: _tarefas,
          onDadosAtualizados: _carregarDados,
        );
      case 2:
        return TelaFinancas(
          uid: _usuarioAtual.uid,
          totalReceitas: _totalReceitas,
          totalGastos: _totalGastos,
          saldo: _saldo,
          transacoes: _transacoes,
          onDadosAtualizados: _carregarDados,
        );
      case 3:
        return TelaPlanejamento(uid: _usuarioAtual.uid);
      case 4:
        return TelaRelatorios(
          uid: _usuarioAtual.uid,
          tarefas: _tarefas,
          transacoes: _transacoes,
        );
      case 5:
        return TelaPerfil(
          dadosUsuario: _dadosUsuario,
          onPerfilAtualizado: _atualizarDadosPerfil,
        );
      case 6:
        return const TelaConfiguracoes();
      case 7:
        return TelaComprasPlanejadas(
          uid: _usuarioAtual.uid,
          onDespesaRegistrada: _carregarDados,
        );
      default:
        return _construirTelaInicio();
    }
  }

  Widget _construirTelaInicio() {
    final tarefasPendentes = _tarefas
        .where((tarefa) => tarefa['status']?.toString() != 'concluido')
        .take(3)
        .toList();
    final transacoesRecentes = _transacoes.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = AppResponsive.pagePadding(width);
        final contentWidth = AppResponsive.maxContentWidth(width);

        return RefreshIndicator(
          onRefresh: _carregarDados,
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
                      Text(
                        'Bem-vindo, ${_obterPrimeiroNome(_dadosUsuario['nome']?.toString())}!',
                        style: TextStyle(
                          fontSize: AppResponsive.headingSize(width),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${DateTime.now().day} de ${_obterMes(DateTime.now().month)} de ${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      if (_mensagemErro != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B1B1B).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFF6B6B)),
                          ),
                          child: Text(
                            _mensagemErro!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _construirCardsInfoGrid(
                        width: width,
                        children: [
                          _construirCardInfo(
                            titulo: 'Tarefas',
                            valor: '$_totalTarefas',
                            icone: Icons.task_alt,
                            cor: const Color(0xFF6366F1),
                          ),
                          _construirCardInfo(
                            titulo: 'Despesas',
                            valor: _formatarMoeda(_totalGastos),
                            icone: Icons.trending_down,
                            cor: const Color(0xFFF97316),
                          ),
                          _construirCardInfo(
                            titulo: 'Receitas',
                            valor: _formatarMoeda(_totalReceitas),
                            icone: Icons.trending_up,
                            cor: const Color(0xFF10B981),
                          ),
                          _construirCardInfo(
                            titulo: 'Saldo',
                            valor: _formatarMoeda(_saldo),
                            icone: Icons.account_balance_wallet_outlined,
                            cor: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _construirSecao(
                        titulo: 'Próximas tarefas',
                        acao: TextButton(
                          onPressed: () {
                            setState(() {
                              _indiceTelaAtual = 1;
                            });
                          },
                          child: const Text('Ver tudo'),
                        ),
                        child: tarefasPendentes.isEmpty
                            ? _construirEstadoVazio(
                                icone: Icons.task_alt,
                                texto: 'Você ainda não criou tarefas.',
                              )
                            : Column(
                                children: tarefasPendentes.map((tarefa) {
                                  final prazo = _converterParaDateTime(
                                    tarefa['prazo'],
                                  );
                                  final prioridade =
                                      tarefa['prioridade']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1A1F3A,
                                        ).withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.18),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: _corPrioridade(
                                                prioridade,
                                              ).withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.bolt,
                                              color: _corPrioridade(prioridade),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tarefa['titulo']
                                                          ?.toString() ??
                                                      'Sem título',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  prazo != null
                                                      ? 'Prazo: ${_formatarData(prazo)}'
                                                      : 'Sem prazo definido',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.65),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      _construirSecao(
                        titulo: 'Movimentações recentes',
                        acao: TextButton(
                          onPressed: () {
                            setState(() {
                              _indiceTelaAtual = 2;
                            });
                          },
                          child: const Text('Ver tudo'),
                        ),
                        child: transacoesRecentes.isEmpty
                            ? _construirEstadoVazio(
                                icone: Icons.receipt_long,
                                texto: 'Você ainda não registrou lançamentos.',
                              )
                            : Column(
                                children: transacoesRecentes.map((transacao) {
                                  final tipo =
                                      transacao['tipo']?.toString() ??
                                      'despesa';
                                  final cor = tipo == 'receita'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF97316);
                                  final data = _converterParaDateTime(
                                    transacao['data'],
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1A1F3A,
                                        ).withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.18),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: cor.withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              tipo == 'receita'
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              color: cor,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transacao['titulo']
                                                          ?.toString() ??
                                                      'Lançamento',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  data != null
                                                      ? _formatarData(data)
                                                      : 'Sem data',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.65),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatarMoeda(
                                              _converterParaDouble(
                                                transacao['valor'],
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: cor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
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
    );
  }

  Widget _construirCardsInfoGrid({
    required double width,
    required List<Widget> children,
  }) {
    final orientation = MediaQuery.of(context).orientation;
    final columns = AppResponsive.gridColumns(
      width,
      mobile: 2,
      tablet: 2,
      desktop: 4,
      landscape: orientation == Orientation.landscape,
    );
    final availableWidth =
        AppResponsive.maxContentWidth(width).clamp(0, width).toDouble() -
        AppResponsive.pagePadding(width).horizontal;
    final itemWidth = AppResponsive.itemWidth(
      availableWidth: availableWidth,
      columns: columns,
      spacing: 16,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: children
          .map((child) => SizedBox(width: itemWidth, child: child))
          .toList(),
    );
  }

  Widget _construirSecao({
    required String titulo,
    required Widget child,
    Widget? acao,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?acao,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _construirEstadoVazio({
    required IconData icone,
    required String texto,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icone, size: 48, color: Colors.white.withOpacity(0.28)),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.58)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCardInfo({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.65),
        border: Border.all(color: cor.withOpacity(0.28)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemNotificacao(
    Map<String, dynamic> notificacao, {
    required VoidCallback onTap,
  }) {
    final cor = notificacao['cor'] as Color? ?? const Color(0xFF6366F1);
    final icone = notificacao['icone'] as IconData? ?? Icons.notifications_none;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF11182E).withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cor.withOpacity(0.24)),
        ),
        child: Row(
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificacao['titulo']?.toString() ?? 'Notificação',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notificacao['mensagem']?.toString() ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _corPrioridade(String prioridade) {
    switch (prioridade.toLowerCase()) {
      case 'alta':
        return const Color(0xFFEF4444);
      case 'media':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = _obterNotificacoesNaoVisualizadas();

    if (_carregando) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0E27),
                const Color(0xFF1A1F3A).withOpacity(0.8),
                const Color(0xFF0F1729),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final headerPadding = AppResponsive.pagePadding(width);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E27),
                  const Color(0xFF1A1F3A).withOpacity(0.8),
                  const Color(0xFF0F1729),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: headerPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => GestureDetector(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'TaskLedger',
                          style: TextStyle(
                            fontSize: AppResponsive.isMobile(width) ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _abrirCentralNotificacoes,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                            if (notificacoes.isNotEmpty)
                              Positioned(
                                right: -4,
                                top: -6,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF0F1729),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    notificacoes.length > 9
                                        ? '9+'
                                        : '${notificacoes.length}',
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
                      ],
                    ),
                  ),
                  Expanded(child: _construirTelaAtual()),
                ],
              ),
            ),
          ),
          drawer: Drawer(
            backgroundColor: const Color(0xFF0A0E27),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0E27),
                    const Color(0xFF1A1F3A).withOpacity(0.8),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _obterPrimeiroNome(_dadosUsuario['nome']?.toString()),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dadosUsuario['email']?.toString() ??
                              'email@exemplo.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _construirItemDrawer(
                    indice: 0,
                    titulo: 'Início',
                    icone: Icons.home_outlined,
                  ),
                  _construirItemDrawer(
                    indice: 1,
                    titulo: 'Tarefas',
                    icone: Icons.task_alt,
                  ),
                  _construirItemDrawer(
                    indice: 2,
                    titulo: 'Finanças',
                    icone: Icons.attach_money,
                  ),
                  _construirItemDrawer(
                    indice: 3,
                    titulo: 'Planejamento',
                    icone: Icons.event_note_outlined,
                  ),
                  _construirItemDrawer(
                    indice: 7,
                    titulo: 'Compras Planejadas',
                    icone: Icons.shopping_bag_outlined,
                  ),
                  _construirItemDrawer(
                    indice: 4,
                    titulo: 'Relatórios',
                    icone: Icons.bar_chart_outlined,
                  ),
                  _construirItemDrawer(
                    indice: 5,
                    titulo: 'Perfil',
                    icone: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF6366F1), thickness: 0.5),
                  const SizedBox(height: 20),
                  _construirItemDrawer(
                    indice: 6,
                    titulo: 'Configurações',
                    icone: Icons.settings_outlined,
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sair',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sair();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirItemDrawer({
    required int indice,
    required String titulo,
    required IconData icone,
  }) {
    final ativo = _indiceTelaAtual == indice;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ativo
          ? BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.5),
              ),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icone,
          color: ativo
              ? const Color(0xFF6366F1)
              : Colors.white.withOpacity(0.6),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: ativo ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _indiceTelaAtual = indice;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}
