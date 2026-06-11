import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Execução guiada do treino: série a série, com cronômetro de descanso.
class ExecucaoTreinoScreen extends ConsumerStatefulWidget {
  const ExecucaoTreinoScreen({super.key});

  @override
  ConsumerState<ExecucaoTreinoScreen> createState() =>
      _ExecucaoTreinoScreenState();
}

class _ExecucaoTreinoScreenState extends ConsumerState<ExecucaoTreinoScreen> {
  final _carga = TextEditingController();
  final _reps = TextEditingController();
  int _ultimoItemPreenchido = -1;
  bool _finalizando = false;

  @override
  void dispose() {
    _carga.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _preencherSugestao(EstadoExecucao sessao) {
    // Pré-preenche com a prescrição ao trocar de exercício.
    if (_ultimoItemPreenchido == sessao.itemAtual) return;
    _ultimoItemPreenchido = sessao.itemAtual;
    _carga.text = sessao.item.cargaKg % 1 == 0
        ? sessao.item.cargaKg.toStringAsFixed(0)
        : sessao.item.cargaKg.toString();
    final faixa = RegExp(r'^(\d+)').firstMatch(sessao.item.repeticoes);
    _reps.text = faixa?.group(1) ?? '10';
  }

  Future<void> _trocarExercicio(EstadoExecucao sessao) async {
    final atual = ref
        .read(exercicioRepositoryProvider)
        .porId(sessao.item.exercicioId);
    final biblioteca =
        await ref.read(exercicioRepositoryProvider).biblioteca();
    if (!mounted) return;
    final alternativas = biblioteca
        .where((e) =>
            e.grupoMuscular == atual.grupoMuscular && e.id != atual.id)
        .toList();
    if (alternativas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sem equivalentes para este grupo muscular.')),
      );
      return;
    }
    final escolhido = await showModalBottomSheet<Exercicio>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Equivalentes de ${atual.nome} (${atual.grupoMuscular})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final e in alternativas)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(e.nome),
                subtitle: Text(e.equipamento),
                onTap: () => Navigator.of(context).pop(e),
              ),
          ],
        ),
      ),
    );
    if (escolhido == null) return;
    ref.read(execucaoSessaoProvider.notifier).trocarExercicio(escolhido.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trocado para ${escolhido.nome}!')),
      );
    }
  }

  void _concluirSerie(EstadoExecucao sessao) {
    final carga = double.tryParse(_carga.text.replaceAll(',', '.')) ??
        sessao.item.cargaKg;
    final reps = int.tryParse(_reps.text) ?? 0;
    final eraUltima = sessao.ultimaSerieDoTreino;
    ref
        .read(execucaoSessaoProvider.notifier)
        .concluirSerie(cargaKg: carga, repeticoes: reps);
    if (eraUltima) _finalizar();
  }

  Future<void> _finalizar({bool confirmarIncompleto = false}) async {
    final sessao = ref.read(execucaoSessaoProvider);
    if (sessao == null || _finalizando) return;
    if (confirmarIncompleto) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalizar treino incompleto?'),
          content: Text(
              'Você concluiu ${sessao.realizadas.length} de '
              '${sessao.totalSeries} séries. As séries feitas serão salvas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar treinando'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
      if (continuar != true) return;
    }
    if (!mounted) return;
    // Feedback pós-treino: PSE (Borg) e dores.
    final feedback = await showDialog<({int pse, bool dor, String relato})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FeedbackDialog(),
    );
    if (feedback == null) return;
    setState(() => _finalizando = true);
    final conclusao =
        await ref.read(execucaoSessaoProvider.notifier).finalizar(
              pse: feedback.pse,
              dorArticular: feedback.dor,
              dorRelato: feedback.relato,
            );
    if (!mounted || conclusao == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResumoDialog(conclusao: conclusao),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sessao = ref.watch(execucaoSessaoProvider);
    if (sessao == null) {
      // Sessão encerrada (resumo em exibição) ou acesso sem iniciar —
      // nada animado aqui para não segurar pumpAndSettle nos testes.
      return const Scaffold(body: SizedBox.shrink());
    }
    _preencherSugestao(sessao);

    final theme = Theme.of(context);
    final brand = context.brand;
    final exercicio = ref
        .read(exercicioRepositoryProvider)
        .porId(sessao.item.exercicioId);
    final progresso = sessao.realizadas.length / sessao.totalSeries;
    final emDescanso = sessao.descansoRestante > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${sessao.treino.nome} — ${sessao.treino.foco}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          tooltip: 'Sair do treino',
          icon: const Icon(Icons.close),
          onPressed: () => _finalizar(confirmarIncompleto: true),
        ),
      ),
      body: PaginaCentralizada(
        maxWidth: 520,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progresso, minHeight: 10),
            ),
            const SizedBox(height: 6),
            Text(
              '${sessao.realizadas.length} de ${sessao.totalSeries} séries '
              '· exercício ${sessao.itemAtual + 1} de '
              '${sessao.treino.itens.length}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(exercicio.grupoMuscular.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            exercicio.nome,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (exercicio.videoUrl.isNotEmpty)
                          IconButton(
                            tooltip: 'Ver vídeo demonstrativo',
                            icon: Icon(Icons.play_circle_fill,
                                color: theme.colorScheme.primary, size: 30),
                            onPressed: () =>
                                launchUrl(Uri.parse(exercicio.videoUrl)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Série ${sessao.serieAtual} de ${sessao.item.series} · '
                      'alvo ${sessao.item.repeticoes} reps'
                      '${sessao.item.cargaKg > 0 ? ' · ${sessao.item.cargaKg.toStringAsFixed(0)} kg' : ''}'
                      '${sessao.item.cadencia.isNotEmpty ? ' · cad. ${sessao.item.cadencia}' : ''}'
                      '${sessao.item.metodo != MetodoTreino.normal ? ' · ${sessao.item.metodo.rotulo}' : ''}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      onPressed: () => _trocarExercicio(sessao),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Aparelho ocupado? Trocar'),
                    ),
                    const SizedBox(height: 20),
                    if (emDescanso)
                      _Descanso(
                        restante: sessao.descansoRestante,
                        total: sessao.item.descansoSeg,
                        aoPular: () => ref
                            .read(execucaoSessaoProvider.notifier)
                            .pularDescanso(),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _carga,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Carga (kg)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _reps,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Repetições',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed:
                            _finalizando ? null : () => _concluirSerie(sessao),
                        icon: const Icon(Icons.check),
                        label: Text(sessao.ultimaSerieDoTreino
                            ? 'Concluir última série'
                            : 'Concluir série'),
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.sucesso,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SectionTitle('Próximos exercícios'),
            for (var i = sessao.itemAtual;
                i < sessao.treino.itens.length;
                i++)
              _ProximoItem(
                item: sessao.treino.itens[i],
                nome: ref
                    .read(exercicioRepositoryProvider)
                    .porId(sessao.treino.itens[i].exercicioId)
                    .nome,
                atual: i == sessao.itemAtual,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _finalizando
                  ? null
                  : () => _finalizar(confirmarIncompleto: true),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Finalizar treino'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Descanso extends StatelessWidget {
  const _Descanso({
    required this.restante,
    required this.total,
    required this.aoPular,
  });

  final int restante;
  final int total;
  final VoidCallback aoPular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: total == 0 ? 0 : restante / total,
                  strokeWidth: 8,
                ),
              ),
              Text(
                '${restante}s',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Descanso', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: aoPular,
          icon: const Icon(Icons.skip_next),
          label: const Text('Pular descanso'),
        ),
      ],
    );
  }
}

class _ProximoItem extends StatelessWidget {
  const _ProximoItem({
    required this.item,
    required this.nome,
    required this.atual,
  });

  final ItemTreino item;
  final String nome;
  final bool atual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: atual ? theme.colorScheme.primaryContainer : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(
          atual ? Icons.play_arrow : Icons.fitness_center,
          size: 20,
        ),
        title: Text(nome,
            style: TextStyle(
                fontWeight: atual ? FontWeight.w700 : FontWeight.w500)),
        trailing: Text('${item.series}x ${item.repeticoes}'),
      ),
    );
  }
}

/// PSE (Escala de Borg 0–10) + registro de dor pós-treino.
class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  double _pse = 5;
  bool _dor = false;
  final _relato = TextEditingController();

  static const _emojis = [
    '😴', '😌', '🙂', '😊', '💪', '😅', '😓', '🥵', '😮‍💨', '🥶', '🤯', //
  ];

  @override
  void dispose() {
    _relato.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = _emojis[_pse.round().clamp(0, 10)];
    return AlertDialog(
      title: const Text('Como foi o treino?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Esforço percebido (0 = muito leve · 10 = máximo)',
              style: theme.textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _pse,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _pse.round().toString(),
                    onChanged: (v) => setState(() => _pse = v),
                  ),
                ),
                Text('$emoji ${_pse.round()}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Senti dor articular anormal'),
              value: _dor,
              activeTrackColor: theme.colorScheme.error,
              onChanged: (v) => setState(() => _dor = v),
            ),
            if (_dor)
              TextField(
                controller: _relato,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Onde e quando doeu?',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_dor)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Seu personal será alertado sobre esta dor.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            pse: _pse.round(),
            dor: _dor,
            relato: _relato.text.trim(),
          )),
          child: const Text('Enviar e finalizar'),
        ),
      ],
    );
  }
}

class _ResumoDialog extends StatelessWidget {
  const _ResumoDialog({required this.conclusao});

  final TreinoConcluido conclusao;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget linha(IconData icone, String rotulo, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icone, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(rotulo)),
              Text(valor,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return AlertDialog(
      title: const Text('Treino concluído! 🎉'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            linha(Icons.timer_outlined, 'Duração',
                '${conclusao.duracaoMin} min'),
            linha(Icons.repeat, 'Séries concluídas',
                '${conclusao.series.length}'),
            linha(Icons.fitness_center, 'Volume total',
                '${conclusao.volumeTotalKg.toStringAsFixed(0)} kg'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
