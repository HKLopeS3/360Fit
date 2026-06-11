import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/chat_screen.dart';
import 'comparativo_screen.dart';
import 'nova_avaliacao_screen.dart';

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
      body: PaginaCentralizada(
        child: AsyncView(
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
            ParDeMetricas(
              primeiro: MetricCard(
                titulo: 'Peso atual',
                valor: '${aluno.pesoAtualKg.toStringAsFixed(1)} kg',
                icone: Icons.monitor_weight,
              ),
              segundo: MetricCard(
                titulo: 'Frequência',
                valor: '${aluno.frequenciaSemanal}x',
                subtitulo: 'por semana',
                icone: Icons.event_repeat,
              ),
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
                        for (final t in treinos) TreinoResumoCard(treino: t),
                      ],
                    ),
            ),
            SectionTitle(
              'Avaliações físicas',
              trailing: TextButton.icon(
                onPressed: () {
                  final aluno = alunoAsync.valueOrNull;
                  if (aluno == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ComparativoScreen(
                          alunoId: alunoId, nomeAluno: aluno.primeiroNome),
                    ),
                  );
                },
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('Comparar'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                final aluno = alunoAsync.valueOrNull;
                if (aluno == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NovaAvaliacaoScreen(
                        alunoId: alunoId, nomeAluno: aluno.primeiroNome),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova avaliação'),
            ),
            const SizedBox(height: 10),
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
                                'Massa magra ${a.massaMagraKg.toStringAsFixed(1)} kg · ${fmtDiaMes.format(a.data)}/${a.data.year}'
                                '${a.medidas.isEmpty ? '' : '\n${a.medidas.entries.map((m) => '${m.key} ${m.value.toStringAsFixed(0)}cm').join(' · ')}'}',
                              ),
                              isThreeLine: a.medidas.isNotEmpty,
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

