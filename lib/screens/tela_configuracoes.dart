import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = AppResponsive.pagePadding(width);
        final contentWidth = AppResponsive.maxContentWidth(width);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações',
                      style: TextStyle(
                        fontSize: AppResponsive.headingSize(width),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _CabecalhoConfiguracoes(),
                    const SizedBox(height: 20),
                    _SecaoConfiguracao(
                      titulo: 'Preferências de exibição',
                      descricao:
                          'Defina futuramente como os resumos e registros serão organizados nas telas.',
                      children: const [
                        _BotaoConfiguracao(
                          icone: Icons.view_agenda_outlined,
                          titulo: 'Indicadores em linha',
                          descricao:
                              'Mantém os cartões de tarefas e finanças lado a lado, como no layout atual.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.grid_view_rounded,
                          titulo: 'Grade responsiva',
                          descricao:
                              'Permite que os indicadores se reorganizem em mais linhas quando necessário.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.view_list_outlined,
                          titulo: 'Lista compacta',
                          descricao:
                              'Exibe tarefas, lançamentos e planejamentos com menos espaçamento vertical.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.dashboard_customize_outlined,
                          titulo: 'Cards destacados',
                          descricao:
                              'Usa cartões maiores para dar mais destaque às informações principais.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SecaoConfiguracao(
                      titulo: 'Funcionalidades futuras',
                      descricao:
                          'Atalhos reservados para opções que ainda serão discutidas e implementadas.',
                      children: const [
                        _BotaoConfiguracao(
                          icone: Icons.notifications_none_rounded,
                          titulo: 'Notificações',
                          descricao:
                              'Centralizar alertas, lembretes e avisos importantes do aplicativo.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.palette_outlined,
                          titulo: 'Aparência',
                          descricao:
                              'Ajustar tema, contraste e densidade visual da interface.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.lock_outline_rounded,
                          titulo: 'Privacidade',
                          descricao:
                              'Reunir configurações de segurança e proteção da conta.',
                        ),
                        _BotaoConfiguracao(
                          icone: Icons.cloud_sync_outlined,
                          titulo: 'Dados e backup',
                          descricao:
                              'Preparar opções para exportação, sincronização e cópias de segurança.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CabecalhoConfiguracoes extends StatelessWidget {
  const _CabecalhoConfiguracoes();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central de preferências',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Esta área está preparada para receber os controles de personalização do TaskLedger.',
                      style: TextStyle(color: Color(0xFFE7E7FF), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Opções visuais, ainda sem ação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecaoConfiguracao extends StatelessWidget {
  const _SecaoConfiguracao({
    required this.titulo,
    required this.descricao,
    required this.children,
  });

  final String titulo;
  final String descricao;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11182F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;
              final spacing = isNarrow ? 10.0 : 12.0;
              final itemWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: children
                    .map((child) => SizedBox(width: itemWidth, child: child))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BotaoConfiguracao extends StatelessWidget {
  const _BotaoConfiguracao({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icone, color: const Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Em breve',
                        style: TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
