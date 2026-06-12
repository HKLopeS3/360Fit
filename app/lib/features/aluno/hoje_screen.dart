import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
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
      body: PaginaCentralizada(
        child: AsyncView(
          value: treinoAsync,
          builder: (treino) => treino == null
              ? const _DiaDeDescanso()
              : _TreinoDoDia(treino: treino),
        ),
      ),
    );
  }
}

class _DiaDeDescanso extends StatelessWidget {
  const _DiaDeDescanso();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, size: 72, color: Colors.teal),
          const SizedBox(height: 12),
          Text('Hoje é dia de descanso!',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Aproveite para se recuperar e hidratar.'),
        ],
      ),
    );
  }
}

class _TreinoDoDia extends ConsumerWidget {
  const _TreinoDoDia({required this.treino});

  final Treino treino;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = context.brand;
    final theme = Theme.of(context);
    final execucao = ref.watch(execucaoTreinoProvider);
    final concluidos = execucao[treino.id] ?? const <int>{};
    final progresso =
        treino.itens.isEmpty ? 0.0 : concluidos.length / treino.itens.length;
    final exercicios = ref.read(exercicioRepositoryProvider);
    final historicoAsync =
        ref.watch(historicoConcluidosProvider(alunoLogadoId));
    final treinosAsync = ref.watch(treinosDoAlunoProvider(alunoLogadoId));

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
        // Cartão-resumo do treino
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
                      ref
                          .read(execucaoSessaoProvider.notifier)
                          .iniciar(treino);
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
        const SizedBox(height: 12),
        const _CardAgua(),
        const SectionTitle('Exercícios de hoje'),
        for (final (i, item) in treino.itens.indexed)
          _ExercicioTile(
            item: item,
            exercicio: exercicios.porId(item.exercicioId),
            concluido: concluidos.contains(i),
            aoMarcar: () => ref
                .read(execucaoTreinoProvider.notifier)
                .alternar(treino.id, i),
          ),
        const SectionTitle('Meus treinos'),
        AsyncView(
          value: treinosAsync,
          builder: (treinos) => Column(
            children: [
              for (final t in treinos) TreinoResumoCard(treino: t),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contador diário de hidratação (meta: 8 copos).
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
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (copos / meta).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: Colors.lightBlue,
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
    final carga = item.cargaKg > 0 ? ' · ${item.cargaKg.toStringAsFixed(item.cargaKg % 1 == 0 ? 0 : 1)} kg' : '';
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
        // Em telas estreitas o chip rouba espaço do nome do exercício.
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
