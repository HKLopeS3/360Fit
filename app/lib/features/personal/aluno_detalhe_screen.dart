import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/chat_screen.dart';

class AlunoDetalheScreen extends ConsumerWidget {
  const AlunoDetalheScreen({super.key, required this.alunoId});

  final String alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final treinosAsync = ref.watch(treinosDoAlunoProvider(alunoId));
    final avaliacoesAsync = ref.watch(avaliacoesProvider(alunoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do aluno')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(alunoId: alunoId, comoAluno: false),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Conversar'),
      ),
      body: AsyncView(
        value: alunoAsync,
        builder: (aluno) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IniciaisAvatar(aluno.iniciais, raio: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aluno.nome,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            '${aluno.idade} anos · ${aluno.objetivo}\n'
                            'Aluno desde ${DateFormat('MMM/y').format(aluno.inicio)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (aluno.riscoEvasao)
                      Tooltip(
                        message: 'Risco de evasão',
                        child: Icon(Icons.warning_amber,
                            color: context.brand.alerta, size: 28),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    titulo: 'Peso atual',
                    valor: '${aluno.pesoAtualKg.toStringAsFixed(1)} kg',
                    icone: Icons.monitor_weight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    titulo: 'Frequência',
                    valor: '${aluno.frequenciaSemanal}x',
                    subtitulo: 'por semana',
                    icone: Icons.event_repeat,
                  ),
                ),
              ],
            ),
            const SectionTitle('Treinos prescritos'),
            AsyncView(
              value: treinosAsync,
              builder: (treinos) => treinos.isEmpty
                  ? const Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Nenhum treino prescrito ainda. Use a aba Prescrição.'),
                      ),
                    )
                  : Column(
                      children: [
                        for (final t in treinos) _TreinoResumo(treino: t),
                      ],
                    ),
            ),
            const SectionTitle('Avaliações físicas'),
            AsyncView(
              value: avaliacoesAsync,
              builder: (avaliacoes) => avaliacoes.isEmpty
                  ? const Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nenhuma avaliação registrada.'),
                      ),
                    )
                  : Column(
                      children: [
                        for (final a in avaliacoes.reversed)
                          Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.assessment_outlined),
                              title: Text(
                                  '${a.pesoKg.toStringAsFixed(1)} kg · ${a.gorduraPct.toStringAsFixed(1)}% gordura'),
                              subtitle: Text(
                                  'Massa magra ${a.massaMagraKg.toStringAsFixed(1)} kg · ${fmtDiaMes.format(a.data)}/${a.data.year}'),
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

class _TreinoResumo extends ConsumerWidget {
  const _TreinoResumo({required this.treino});

  final Treino treino;

  static const _dias = {
    DateTime.monday: 'Seg',
    DateTime.tuesday: 'Ter',
    DateTime.wednesday: 'Qua',
    DateTime.thursday: 'Qui',
    DateTime.friday: 'Sex',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicios = ref.read(exercicioRepositoryProvider);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        shape: const Border(),
        title: Text('${treino.nome} — ${treino.foco}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${treino.itens.length} exercícios · ${treino.diasSemana.map((d) => _dias[d]).join(', ')}',
        ),
        children: [
          for (final item in treino.itens)
            ListTile(
              dense: true,
              leading: const Icon(Icons.fitness_center, size: 18),
              title: Text(exercicios.porId(item.exercicioId).nome),
              trailing: Text('${item.series}x ${item.repeticoes}'),
            ),
        ],
      ),
    );
  }
}
