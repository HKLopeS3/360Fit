import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../feed/feed_screen.dart';
import 'form_aluno_screen.dart';
import 'perfil_personal_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            _Avatar(nome: sessao?.nome ?? ''),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessao?.primeiroNome ?? 'Personal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Profissional de Ed. Física',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _NotificacoesBadge(),
          IconButton(
            tooltip: 'Feed da academia',
            icon: const Icon(Icons.dynamic_feed_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const FeedScreen(comoPersonal: true)),
            ),
          ),
          const LogoutButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: AsyncView(
        value: alunosAsync,
        builder: (alunos) {
          final primeirosPassos = _PrimeirosPassos(
            temAlunos: alunos.isNotEmpty,
            temCref: sessao?.cref != null && (sessao!.cref!.isNotEmpty),
            onPerfil: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const PerfilPersonalScreen()),
            ),
            onNovoAluno: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FormAlunoScreen()),
            ),
            onPrescricao: () => context.go('/personal/prescricao'),
            onFeed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const FeedScreen(comoPersonal: true)),
            ),
          );
          final banner = _BannerPerfil(onTap: () => context.go('/personal/mais'));
          final feedback = _FeedbackTreinos(alunos: alunos);
          final prescricoes = _CardPrescricoes(totalAlunos: alunos.length);
          final alertas = Consumer(builder: (context, ref, _) {
            final alertasAsync = ref.watch(alertasProvider);
            return alertasAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (alertas) {
                if (alertas.isEmpty) return const SizedBox.shrink();
                return _SecaoAlertas(alertas: alertas);
              },
            );
          });
          final emRisco = _AlunosEmRisco(alunos: alunos);

          return LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              // ── Layout desktop: duas colunas ──────────────────────────────
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna principal (60%)
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              primeirosPassos,
                              const SizedBox(height: 16),
                              feedback,
                              const SizedBox(height: 16),
                              emRisco,
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Coluna lateral (40%)
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              banner,
                              const SizedBox(height: 16),
                              prescricoes,
                              const SizedBox(height: 16),
                              alertas,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // ── Layout mobile: coluna única ───────────────────────────────
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                primeirosPassos,
                const SizedBox(height: 4),
                banner,
                const SizedBox(height: 4),
                feedback,
                const SizedBox(height: 4),
                prescricoes,
                const SizedBox(height: 4),
                alertas,
                emRisco,
                const SizedBox(height: 24),
              ],
            );
          });
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────── Avatar no AppBar

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome});
  final String nome;

  String get _iniciais {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nome.isNotEmpty ? nome[0].toUpperCase() : 'P';
  }

  @override
  Widget build(BuildContext context) {
    final cor = context.brand.primaria;
    return CircleAvatar(
      radius: 20,
      backgroundColor: cor.withValues(alpha: 0.15),
      child: Text(
        _iniciais,
        style: TextStyle(
          color: cor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Primeiros Passos

class _PrimeirosPassos extends StatelessWidget {
  const _PrimeirosPassos({
    required this.temAlunos,
    required this.temCref,
    required this.onPerfil,
    required this.onNovoAluno,
    required this.onPrescricao,
    required this.onFeed,
  });
  final bool temAlunos;
  final bool temCref;
  final VoidCallback onPerfil;
  final VoidCallback onNovoAluno;
  final VoidCallback onPrescricao;
  final VoidCallback onFeed;

  @override
  Widget build(BuildContext context) {
    final passos = [
      _Passo(
        titulo: 'Complete seu perfil',
        icone: Icons.person_outlined,
        cor: const Color(0xFF00897B),
        concluido: temCref,
        aoTocar: onPerfil,
      ),
      _Passo(
        titulo: 'Cadastre um Aluno',
        icone: Icons.group_add_outlined,
        cor: const Color(0xFF00ACC1),
        concluido: temAlunos,
        aoTocar: onNovoAluno,
      ),
      _Passo(
        titulo: 'Prescreva um treino',
        icone: Icons.assignment_outlined,
        cor: const Color(0xFF43A047),
        concluido: false,
        aoTocar: onPrescricao,
      ),
      _Passo(
        titulo: 'Publique no feed',
        icone: Icons.campaign_outlined,
        cor: const Color(0xFF7CB342),
        concluido: false,
        aoTocar: onFeed,
      ),
    ];
    final concluidos = passos.where((p) => p.concluido).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Primeiros passos',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$concluidos de ${passos.length}',
                        style: TextStyle(
                          color: context.brand.primaria,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(
                        text: ' concluído',
                        style: TextStyle(
                            color: Color(0xFF777777), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: passos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _CardPasso(passo: passos[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Passo {
  const _Passo({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.concluido,
    this.aoTocar,
  });
  final String titulo;
  final IconData icone;
  final Color cor;
  final bool concluido;
  final VoidCallback? aoTocar;
}

class _CardPasso extends StatelessWidget {
  const _CardPasso({required this.passo});
  final _Passo passo;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            passo.cor,
            passo.cor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Ícone de fundo decorativo
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              passo.icone,
              size: 80,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(passo.icone, size: 18, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  passo.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (passo.concluido)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 12, color: passo.cor),
                            const SizedBox(width: 4),
                            Text(
                              'Feito',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: passo.cor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Fazer agora  ›',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    if (passo.aoTocar == null || passo.concluido) return card;
    return GestureDetector(
      onTap: passo.aoTocar,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────── Banner Perfil

class _BannerPerfil extends StatelessWidget {
  const _BannerPerfil({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E22), Color(0xFF0D3B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Padrão decorativo
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18)),
              child: Opacity(
                opacity: 0.12,
                child: Container(
                  width: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFF00BFA5)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Opacity(
              opacity: 0.2,
              child: const Icon(Icons.fitness_center,
                  size: 60, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Divulgue seu trabalho\ne conquiste mais alunos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF00BFA5), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Acessar meu perfil',
                          style: TextStyle(
                            color: Color(0xFF00BFA5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.play_arrow_rounded,
                            color: Color(0xFF00BFA5), size: 16),
                      ],
                    ),
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

// ─────────────────────────────────────────────── Feedback dos Treinos

class _FeedbackTreinos extends ConsumerWidget {
  const _FeedbackTreinos({required this.alunos});
  final List<dynamic> alunos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semanaAsync = ref.watch(treinosSemanaProvider);
    final brand = context.brand;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: brand.gradientePrimario,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Feedback dos Treinos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/personal/alunos'),
                  child: const Text(
                    'Ver Mais',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Resultado dos últimos 7 dias',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Divider(color: Colors.white24, height: 20),
            semanaAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              error: (_, __) => const SizedBox.shrink(),
              data: (semana) {
                final total = semana.fold(0, (a, b) => a + b);
                final esperado = alunos.length * 3;
                final pct =
                    esperado == 0 ? 0.0 : (total / esperado).clamp(0.0, 1.0);
                final satisfacao = 4.2; // TODO: média real dos PSEs
                return Row(
                  children: [
                    // Gauge circular
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _GaugePainter(pct: pct),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Executados',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Divisor vertical
                    Container(
                        width: 1,
                        height: 80,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 20)),
                    // Satisfação
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            satisfacao.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (i) {
                              final full = i < satisfacao.floor();
                              final half = !full &&
                                  i == satisfacao.floor() &&
                                  (satisfacao % 1) >= 0.4;
                              return Icon(
                                full
                                    ? Icons.star_rounded
                                    : half
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nível de Satisfação',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.pct});
  final double pct;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) - 8;
    const startAngle = math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepTotal * pct,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.pct != pct;
}

// ─────────────────────────────────────────────── Card Prescrições

class _CardPrescricoes extends ConsumerWidget {
  const _CardPrescricoes({required this.totalAlunos});
  final int totalAlunos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Prescrições',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPrescricao(
                icone: Icons.edit_note_outlined,
                valor: '$totalAlunos',
                rotulo: 'Total a fazer',
              ),
              _Divisor(),
              _StatPrescricao(
                icone: Icons.autorenew_rounded,
                valor: '${(totalAlunos * 0.8).round()}',
                rotulo: 'Renovações',
              ),
              _Divisor(),
              _StatPrescricao(
                icone: Icons.flag_outlined,
                valor: '${(totalAlunos * 0.2).round()}',
                rotulo: 'Sem treino',
                destaque: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPrescricao extends StatelessWidget {
  const _StatPrescricao({
    required this.icone,
    required this.valor,
    required this.rotulo,
    this.destaque = false,
  });
  final IconData icone;
  final String valor;
  final String rotulo;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cor = destaque
        ? const Color(0xFFE53935)
        : const Color(0xFF1A1A2E);
    return Expanded(
      child: Column(
        children: [
          Icon(icone, size: 22, color: cor.withValues(alpha: 0.7)),
          const SizedBox(height: 6),
          Text(
            valor.padLeft(2, '0'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 52,
        color: const Color(0xFFEEEEEE),
      );
}

// ─────────────────────────────────────────────── Seção Alertas

class _SecaoAlertas extends StatelessWidget {
  const _SecaoAlertas({required this.alertas});
  final List<dynamic> alertas;

  static const _icones = {
    'dor': (Icons.favorite_border, Color(0xFFE53935)),
    'sumido': (Icons.hourglass_bottom, Color(0xFFFF6F00)),
    'programa': (Icons.event_repeat, Color(0xFFF9A825)),
    'aniversario': (Icons.cake_outlined, Color(0xFFE91E63)),
    'financeiro': (Icons.attach_money, Color(0xFF7B1FA2)),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: context.brand.primaria,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Alertas',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final alerta in alertas.take(5)) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              dense: true,
              leading: () {
                final (icone, cor) = _icones[alerta.tipo] ??
                    (Icons.info_outline, const Color(0xFF888888));
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: cor.withValues(alpha: 0.1),
                  child: Icon(icone, size: 16, color: cor),
                );
              }(),
              title: Text(alerta.titulo,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(alerta.detalhe,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
              trailing: alerta.alunoId == null
                  ? null
                  : const Icon(Icons.chevron_right, size: 18),
              onTap: alerta.alunoId == null
                  ? null
                  : () => context.go('/personal/alunos/${alerta.alunoId}'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Alunos em Risco

class _AlunosEmRisco extends StatelessWidget {
  const _AlunosEmRisco({required this.alunos});
  final List<dynamic> alunos;

  @override
  Widget build(BuildContext context) {
    final emRisco = alunos.where((a) => a.riscoEvasao).toList();
    if (emRisco.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Alunos em risco de evasão',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/personal/alunos'),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 30)),
                  child: const Text('Ver todos',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          for (final aluno in emRisco.take(4)) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: IniciaisAvatar(aluno.iniciais),
              title: Text(aluno.nome,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                  '${aluno.frequenciaSemanal}x/sem · ${aluno.objetivo}',
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/personal/alunos/${aluno.id}'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Badge notificações

class _NotificacoesBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(alertasProvider).valueOrNull?.length ?? 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notificações',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            final container = ProviderScope.containerOf(context);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => UncontrolledProviderScope(
                container: container,
                child: const _PainelNotificacoes(),
              ),
            );
          },
        ),
        if (total > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  total > 99 ? '99+' : '$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PainelNotificacoes extends ConsumerWidget {
  const _PainelNotificacoes();

  static const _icones = {
    'dor': (Icons.favorite_border, Colors.red),
    'sumido': (Icons.directions_run, Colors.orange),
    'programa': (Icons.event_outlined, Colors.amber),
    'financeiro': (Icons.attach_money, Colors.purple),
    'aniversario': (Icons.cake_outlined, Colors.pink),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertasAsync = ref.watch(alertasProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              const Icon(Icons.notifications_outlined),
              const SizedBox(width: 8),
              Text('Notificações',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: alertasAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (alertas) {
                if (alertas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 48, color: Colors.green),
                        SizedBox(height: 8),
                        Text('Tudo em dia!'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: alertas.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (_, i) {
                    final a = alertas[i];
                    final (icone, cor) = _icones[a.tipo] ??
                        (Icons.info_outline, Colors.grey);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cor.withValues(alpha: 0.12),
                        child: Icon(icone, color: cor, size: 20),
                      ),
                      title: Text(a.titulo,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(a.detalhe,
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
