import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets.dart';
import '../feed/feed_screen.dart';
import 'execucao_treino_screen.dart';
import 'notificacoes.dart';

class HojeScreen extends ConsumerWidget {
  const HojeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final treinoAsync = ref.watch(treinoDoDiaProvider);
    final treinosAsync = ref.watch(treinosDoAlunoProvider(alunoLogadoId));
    final avaliacoesAsync = ref.watch(avaliacoesProvider(alunoLogadoId));
    final personalAsync = ref.watch(personalDoAlunoProvider);
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    // Banner do personal — sempre visível, independente do dia/treino
    final bannerPersonal = personalAsync.when(
      data: (info) =>
          info != null ? _BannerPersonal(info: info) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${sessao?.primeiroNome ?? 'Aluno'} 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              capitalizar(fmtDataCompleta.format(DateTime.now())),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          IconButton(
            tooltip: 'Feed da academia',
            icon: const Icon(Icons.dynamic_feed_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const FeedScreen(comoPersonal: false)),
            ),
          ),
          const SinoNotificacoes(),
          const LogoutButton(),
        ],
      ),
      body: desktop
          ? _BodyDesktop(
              bannerPersonal: bannerPersonal,
              dashboardMetricas: _DashboardAluno(avaliacoesAsync: avaliacoesAsync),
              treinoAsync: treinoAsync,
              treinosAsync: treinosAsync,
            )
          : _BodyMobile(
              bannerPersonal: bannerPersonal,
              dashboardMetricas: _DashboardAluno(avaliacoesAsync: avaliacoesAsync),
              treinoAsync: treinoAsync,
              treinosAsync: treinosAsync,
            ),
    );
  }
}

// ─────────────────────────────────────────────── Layout Desktop

class _BodyDesktop extends StatelessWidget {
  const _BodyDesktop({
    required this.bannerPersonal,
    required this.dashboardMetricas,
    required this.treinoAsync,
    required this.treinosAsync,
  });

  final Widget bannerPersonal;
  final Widget dashboardMetricas;
  final AsyncValue<Treino?> treinoAsync;
  final AsyncValue<List<Treino>> treinosAsync;

  @override
  Widget build(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bannerPersonal,
                    const SizedBox(height: 16),
                    AsyncView(
                      value: treinoAsync,
                      builder: (treino) => treino != null
                          ? _TreinoDoDiaCard(treino: treino)
                          : _DiaDeDescansoCard(),
                    ),
                    const SizedBox(height: 16),
                    AsyncView(
                      value: treinoAsync,
                      builder: (treino) => treino != null
                          ? Column(children: [
                              const _CardAgua(),
                              const SizedBox(height: 16),
                              _ExerciciosDoDia(treino: treino),
                            ])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Coluna lateral (40%)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dashboardMetricas,
                    const SizedBox(height: 16),
                    AsyncView(
                      value: treinoAsync,
                      builder: (treino) => _ListaTreinosSemana(
                        treinosAsync: treinosAsync,
                        treinoHoje: treino,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Layout Mobile

class _BodyMobile extends StatelessWidget {
  const _BodyMobile({
    required this.bannerPersonal,
    required this.dashboardMetricas,
    required this.treinoAsync,
    required this.treinosAsync,
  });

  final Widget bannerPersonal;
  final Widget dashboardMetricas;
  final AsyncValue<Treino?> treinoAsync;
  final AsyncValue<List<Treino>> treinosAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Banner sempre no topo — independente do dia de treino
        bannerPersonal,
        dashboardMetricas,
        AsyncView(
          value: treinoAsync,
          builder: (treino) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (treino != null) ...[
                _TreinoDoDiaCard(treino: treino),
                const SizedBox(height: 12),
                const _CardAgua(),
                const SizedBox(height: 4),
                _ExerciciosDoDia(treino: treino),
              ] else ...[
                _DiaDeDescansoCard(),
                const SizedBox(height: 12),
              ],
              _ListaTreinosSemana(
                treinosAsync: treinosAsync,
                treinoHoje: treino,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── Card treino do dia

class _TreinoDoDiaCard extends ConsumerWidget {
  const _TreinoDoDiaCard({required this.treino});
  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = context.brand;
    final theme = Theme.of(context);
    final execucao = ref.watch(execucaoTreinoProvider);
    final concluidos = execucao[treino.id] ?? const <int>{};
    final progresso =
        treino.itens.isEmpty ? 0.0 : concluidos.length / treino.itens.length;

    final historicoAsync = ref.watch(historicoConcluidosProvider(alunoLogadoId));
    final hoje = DateTime.now();
    final concluidoHoje = historicoAsync.valueOrNull?.any((c) =>
            c.data.year == hoje.year &&
            c.data.month == hoje.month &&
            c.data.day == hoje.day) ??
        false;

    final programaVigente = ref
        .watch(programasProvider(alunoLogadoId))
        .valueOrNull
        ?.where((p) => p.vigente)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (programaVigente != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${programaVigente.nome} · semana '
                    '${programaVigente.semanaAtual} de '
                    '${programaVigente.semanasTotais}'
                    '${programaVigente.mesociclo.isNotEmpty ? ' · ${programaVigente.mesociclo}' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Card(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: brand.gradientePrimario,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${treino.nome} — ${treino.foco}',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${treino.itens.length} exercícios',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                if (concluidoHoje)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Treino concluído hoje! 🎉',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(execucaoSessaoProvider.notifier).iniciar(treino);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExecucaoTreinoScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Iniciar treino'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                if (!concluidoHoje && concluidos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progresso,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${concluidos.length} de ${treino.itens.length} marcados',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── Exercícios do dia

class _ExerciciosDoDia extends ConsumerWidget {
  const _ExerciciosDoDia({required this.treino});
  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execucao = ref.watch(execucaoTreinoProvider);
    final concluidos = execucao[treino.id] ?? const <int>{};
    final exercicios = ref.read(exercicioRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Exercícios de hoje'),
        for (final (i, item) in treino.itens.indexed)
          _ExercicioTile(
            item: item,
            exercicio: exercicios.porId(item.exercicioId),
            concluido: concluidos.contains(i),
            aoMarcar: () =>
                ref.read(execucaoTreinoProvider.notifier).alternar(treino.id, i),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── Dia de descanso

class _DiaDeDescansoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kShadowCard,
      ),
      child: Row(
        children: [
          Icon(Icons.self_improvement, size: 44, color: brand.primaria),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoje é dia de descanso!',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Aproveite para se recuperar e hidratar.',
                  style: TextStyle(color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Lista de treinos da semana

class _ListaTreinosSemana extends StatelessWidget {
  const _ListaTreinosSemana({
    required this.treinosAsync,
    required this.treinoHoje,
  });

  final AsyncValue<List<Treino>> treinosAsync;
  final Treino? treinoHoje;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Meus treinos'),
        AsyncView(
          value: treinosAsync,
          builder: (treinos) {
            if (treinos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: kShadowCard,
                ),
                child: const Center(
                  child: Text(
                    'Nenhum treino prescrito ainda.',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final t in treinos)
                  _TreinoSemanaCard(
                    treino: t,
                    ehHoje: treinoHoje?.id == t.id,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TreinoSemanaCard extends StatelessWidget {
  const _TreinoSemanaCard({required this.treino, required this.ehHoje});

  final Treino treino;
  final bool ehHoje;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ehHoje ? brand.primaria.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ehHoje
              ? brand.primaria.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        boxShadow: kShadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ehHoje
                  ? brand.primaria
                  : brand.primaria.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 20,
              color: ehHoje ? Colors.white : brand.primaria,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        treino.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: ehHoje ? brand.primaria : kTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ehHoje)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: brand.primaria,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Hoje',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${treino.foco} · ${treino.itens.length} exercícios',
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (treino.diasSemana.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _diasStr(treino.diasSemana),
                      style: const TextStyle(
                          fontSize: 11, color: kTextSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _diasStr(List<int> dias) {
    const nomes = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };
    final sorted = [...dias]..sort();
    return sorted.map((d) => nomes[d] ?? '').join(' · ');
  }
}

// ─────────────────────────────────────────────── Água

class _CardAgua extends ConsumerWidget {
  const _CardAgua();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final copos = ref.watch(aguaProvider).valueOrNull ?? 0;
    const meta = 8;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Text('💧', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hidratação: $copos de $meta copos',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (copos / meta).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: context.brand.primaria,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remover copo',
              onPressed: copos > 0
                  ? () => ref.read(aguaProvider.notifier).ajustar(-1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton.filledTonal(
              tooltip: 'Bebi um copo!',
              onPressed: () => ref.read(aguaProvider.notifier).ajustar(1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Dashboard rápido

class _DashboardAluno extends StatelessWidget {
  const _DashboardAluno({required this.avaliacoesAsync});

  final AsyncValue<List<AvaliacaoFisica>> avaliacoesAsync;

  @override
  Widget build(BuildContext context) {
    final ultima = avaliacoesAsync.valueOrNull
        ?.where((a) => a.pesoKg > 0)
        .lastOrNull;
    if (ultima == null) return const SizedBox.shrink();

    final brand = context.brand;

    Color corGordura(double pct) {
      if (pct <= 0) return kTextSecondary;
      if (pct < 20) return const Color(0xFF22C55E);
      if (pct < 28) return const Color(0xFFF59E0B);
      return const Color(0xFFEF4444);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _MiniMetrica(
            icone: Icons.monitor_weight_outlined,
            valor: '${ultima.pesoKg.toStringAsFixed(1)} kg',
            rotulo: 'Peso atual',
            cor: brand.primaria,
          ),
          const SizedBox(width: 8),
          if (ultima.gorduraPct > 0) ...[
            _MiniMetrica(
              icone: Icons.water_drop_outlined,
              valor: '${ultima.gorduraPct.toStringAsFixed(1)}%',
              rotulo: 'Gordura',
              cor: corGordura(ultima.gorduraPct),
            ),
            const SizedBox(width: 8),
          ],
          _MiniMetrica(
            icone: Icons.fitness_center_outlined,
            valor: '${ultima.massaMagraKg.toStringAsFixed(1)} kg',
            rotulo: 'Massa magra',
            cor: const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }
}

class _MiniMetrica extends StatelessWidget {
  const _MiniMetrica({
    required this.icone,
    required this.valor,
    required this.rotulo,
    required this.cor,
  });

  final IconData icone;
  final String valor;
  final String rotulo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: cor)),
                  Text(rotulo,
                      style: const TextStyle(
                          fontSize: 10, color: kTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Banner Personal

class _BannerPersonal extends StatelessWidget {
  const _BannerPersonal({required this.info});

  final InfoPersonal info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A2E22),
        image: info.capaUrl != null
            ? DecorationImage(
                image: NetworkImage(info.capaUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45), BlendMode.darken),
              )
            : null,
        boxShadow: kShadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (info.fotoUrl != null)
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(info.fotoUrl!),
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Text(
                  info.nome.isNotEmpty ? info.nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (info.cref != null)
                    Text(
                      'CREF ${info.cref}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Seu personal trainer',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
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

// ─────────────────────────────────────────────── Exercício tile

class _ExercicioTile extends StatelessWidget {
  const _ExercicioTile({
    required this.item,
    required this.exercicio,
    required this.concluido,
    required this.aoMarcar,
  });

  final ItemTreino item;
  final Exercicio exercicio;
  final bool concluido;
  final VoidCallback aoMarcar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final carga = item.cargaKg > 0
        ? ' · ${item.cargaKg.toStringAsFixed(item.cargaKg % 1 == 0 ? 0 : 1)} kg'
        : '';
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: CheckboxListTile(
        value: concluido,
        onChanged: (_) => aoMarcar(),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: brand.sucesso,
        title: Text(
          exercicio.nome,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: concluido ? TextDecoration.lineThrough : null,
            color: concluido ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(
          '${item.series}x ${item.repeticoes}$carga · descanso ${item.descansoSeg}s',
        ),
        secondary: MediaQuery.sizeOf(context).width < 420
            ? null
            : Chip(
                label: Text(exercicio.grupoMuscular,
                    style: theme.textTheme.labelSmall),
                visualDensity: VisualDensity.compact,
              ),
      ),
    );
  }
}
