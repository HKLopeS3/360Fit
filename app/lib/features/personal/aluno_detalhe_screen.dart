import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/chat_screen.dart';
import 'anamnese_screen.dart';
import 'comparativo_screen.dart';
import 'form_aluno_screen.dart';
import 'fotos_postura_screen.dart';
import 'nova_avaliacao_screen.dart';
import 'programa_widgets.dart';

/// Mensalidades manuais do aluno (Fase 1: sem gateway de pagamento).
class _FinanceiroSection extends ConsumerWidget {
  const _FinanceiroSection({required this.alunoId});

  final String alunoId;

  Future<void> _gerarMes(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '250,00');
    final valor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gerar mensalidade do mês'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valor',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
                double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Gerar'),
          ),
        ],
      ),
    );
    if (valor == null) return;
    await ref
        .read(financeiroRepositoryProvider)
        .gerar(alunoId, DateTime.now(), valor);
    ref.invalidate(mensalidadesProvider(alunoId));
    ref.invalidate(alertasProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mensalidadesAsync = ref.watch(mensalidadesProvider(alunoId));
    final brand = context.brand;
    final fmt = DateFormat('MM/y');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Mensalidades',
          trailing: TextButton.icon(
            onPressed: () => _gerarMes(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Gerar mês'),
          ),
        ),
        AsyncView(
          value: mensalidadesAsync,
          builder: (mensalidades) => mensalidades.isEmpty
              ? const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma mensalidade gerada ainda.'),
                  ),
                )
              : Column(
                  children: [
                    for (final m in mensalidades.take(4))
                      Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            m.paga
                                ? Icons.check_circle
                                : m.atrasada
                                    ? Icons.error
                                    : Icons.schedule,
                            color: m.paga
                                ? brand.sucesso
                                : m.atrasada
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                          ),
                          title: Text(
                              '${fmt.format(m.competencia)} · R\$ ${m.valor.toStringAsFixed(2)}'),
                          subtitle: Text(m.paga
                              ? 'Paga em ${DateFormat('dd/MM').format(m.pagoEm!)}'
                              : m.atrasada
                                  ? 'ATRASADA — venceu ${DateFormat('dd/MM').format(m.vencimento)}'
                                  : 'Vence ${DateFormat('dd/MM').format(m.vencimento)}'),
                          trailing: m.paga
                              ? null
                              : FilledButton.tonal(
                                  onPressed: () async {
                                    await ref
                                        .read(financeiroRepositoryProvider)
                                        .marcarPaga(m.id);
                                    ref.invalidate(
                                        mensalidadesProvider(alunoId));
                                    ref.invalidate(alertasProvider);
                                  },
                                  child: const Text('Recebi'),
                                ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class AlunoDetalheScreen extends ConsumerWidget {
  const AlunoDetalheScreen({super.key, required this.alunoId});

  final String alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final treinosAsync = ref.watch(treinosDoAlunoProvider(alunoId));
    final avaliacoesAsync = ref.watch(avaliacoesProvider(alunoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do aluno'),
        actions: [
          IconButton(
            tooltip: 'Editar dados',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final aluno = alunoAsync.valueOrNull;
              if (aluno == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => FormAlunoScreen(aluno: aluno)),
              );
            },
          ),
        ],
      ),
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
            ProgramaSection(alunoId: alunoId),
            _FinanceiroSection(alunoId: alunoId),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    final aluno = alunoAsync.valueOrNull;
                    if (aluno == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NovaAvaliacaoScreen(
                            alunoId: alunoId,
                            nomeAluno: aluno.primeiroNome),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nova avaliação'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final aluno = alunoAsync.valueOrNull;
                    if (aluno == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnamneseScreen(
                            alunoId: alunoId,
                            nomeAluno: aluno.primeiroNome),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Anamnese'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final aluno = alunoAsync.valueOrNull;
                    if (aluno == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FotosPosturaScreen(
                            alunoId: alunoId,
                            nomeAluno: aluno.primeiroNome),
                      ),
                    );
                  },
                  icon: const Icon(Icons.accessibility_new),
                  label: const Text('Postura'),
                ),
              ],
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

