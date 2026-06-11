import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/notificacao_interna.dart';
import '../services/notificacao_service.dart';

typedef NotificacaoDestinoCallback =
    void Function(NotificacaoInterna notificacao);

class TelaNotificacoes extends StatefulWidget {
  const TelaNotificacoes({super.key, this.onAbrirDestino});

  final NotificacaoDestinoCallback? onAbrirDestino;

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  final _service = NotificacaoService.instance;
  final _auth = FirebaseAuth.instance;

  User? get _usuario => _auth.currentUser;

  Future<void> _marcarTodasComoVisualizadas() async {
    await _service.marcarTodasComoVisualizadas();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Todas as notificacoes foram marcadas como visualizadas.',
        ),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  Future<void> _abrirNotificacao(NotificacaoInterna notificacao) async {
    await _service.marcarComoVisualizada(notificacao.id);

    if (!mounted) {
      return;
    }

    if (widget.onAbrirDestino != null) {
      widget.onAbrirDestino!(notificacao);
      Navigator.of(context).pop();
      return;
    }

    final rota = notificacao.rota;
    if (rota == null || rota.isEmpty || rota == '/notificacoes') {
      return;
    }

    try {
      await Navigator.of(context).pushNamed(rota);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notificacao marcada como visualizada: ${notificacao.titulo}',
          ),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
    }
  }

  Future<void> _criarExemplo() async {
    await _service.criarNotificacaoExemplo();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificacao interna de exemplo criada.'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      floatingActionButton: kDebugMode && usuario != null
          ? FloatingActionButton.extended(
              onPressed: _criarExemplo,
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Teste'),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0F1729)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    _BotaoCircular(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Notificacoes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: usuario == null
                          ? null
                          : _marcarTodasComoVisualizadas,
                      child: const Text('Marcar todas'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: usuario == null
                    ? _EstadoVazio(
                        icone: Icons.lock_outline,
                        titulo: 'Entre na sua conta',
                        mensagem:
                            'As notificacoes internas ficam vinculadas ao seu usuario.',
                      )
                    : StreamBuilder<List<NotificacaoInterna>>(
                        stream: _service.observarNotificacoes(uid: usuario.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366F1),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return _EstadoVazio(
                              icone: Icons.error_outline,
                              titulo: 'Nao foi possivel carregar',
                              mensagem:
                                  'Verifique sua conexao e tente novamente.',
                            );
                          }

                          final notificacoes =
                              snapshot.data ?? <NotificacaoInterna>[];

                          if (notificacoes.isEmpty) {
                            return _EstadoVazio(
                              icone: Icons.notifications_none,
                              titulo: 'Nenhuma notificacao',
                              mensagem:
                                  'Promocoes, atualizacoes e avisos internos aparecerao aqui.',
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                            itemCount: notificacoes.length,
                            itemBuilder: (context, index) {
                              final notificacao = notificacoes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _CardNotificacao(
                                  notificacao: notificacao,
                                  data: _formatarData(notificacao.criadoEm),
                                  onTap: () => _abrirNotificacao(notificacao),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoCircular extends StatelessWidget {
  const _BotaoCircular({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1)),
      ),
    );
  }
}

class _CardNotificacao extends StatelessWidget {
  const _CardNotificacao({
    required this.notificacao,
    required this.data,
    required this.onTap,
  });

  final NotificacaoInterna notificacao;
  final String data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final destaque = !notificacao.visualizada;
    final cor = destaque ? const Color(0xFF8B5CF6) : Colors.white24;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withOpacity(destaque ? 0.86 : 0.62),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cor.withOpacity(destaque ? 0.55 : 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                destaque
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notificacao.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (destaque)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Nova',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificacao.mensagem,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
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
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icone,
    required this.titulo,
    required this.mensagem,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 58, color: Colors.white.withOpacity(0.28)),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
