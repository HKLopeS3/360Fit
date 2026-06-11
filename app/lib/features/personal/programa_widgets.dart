import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Seção de periodização no detalhe do aluno.
class ProgramaSection extends ConsumerWidget {
  const ProgramaSection({super.key, required this.alunoId});

  final String alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programasAsync = ref.watch(programasProvider(alunoId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Programa de treino',
          trailing: TextButton.icon(
            onPressed: () => mostrarDialogPrograma(context, ref, alunoId),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo'),
          ),
        ),
        AsyncView(
          value: programasAsync,
          builder: (programas) {
            if (programas.isEmpty) {
              return const Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Sem programa ativo. Crie um ciclo para periodizar '
                      'os treinos deste aluno.'),
                ),
              );
            }
            return Column(
              children: [
                for (final p in programas.take(3)) ProgramaCard(programa: p),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ProgramaCard extends StatelessWidget {
  const ProgramaCard({super.key, required this.programa});

  final Programa programa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = programa;
    final progresso = (p.semanaAtual / p.semanasTotais).clamp(0.0, 1.0);
    final fmt = DateFormat('dd/MM/yy');
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${p.nome} · ${p.objetivo}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Chip(
                  label: Text(p.vigente ? 'Vigente' : 'Encerrado'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: p.vigente
                      ? theme.colorScheme.primaryContainer
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (p.macrociclo.isNotEmpty) 'Macro: ${p.macrociclo}',
                if (p.mesociclo.isNotEmpty) 'Meso: ${p.mesociclo}',
                if (p.microciclo.isNotEmpty) 'Micro: ${p.microciclo}',
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progresso, minHeight: 8),
            ),
            const SizedBox(height: 6),
            Text(
              'Semana ${p.semanaAtual} de ${p.semanasTotais} · '
              '${fmt.format(p.inicio)} → ${fmt.format(p.fim)}',
              style: theme.textTheme.bodySmall,
            ),
            if (p.observacoes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p.observacoes, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> mostrarDialogPrograma(
    BuildContext context, WidgetRef ref, String alunoId) async {
  final nome = TextEditingController();
  final objetivo = TextEditingController(text: 'Hipertrofia');
  final macro = TextEditingController();
  final meso = TextEditingController();
  final micro = TextEditingController();
  final obs = TextEditingController();
  var inicio = DateTime.now();
  var fim = DateTime.now().add(const Duration(days: 56));

  final salvar = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        InputDecoration dec(String r) => InputDecoration(
            labelText: r, border: const OutlineInputBorder());
        final fmt = DateFormat('dd/MM/y');
        return AlertDialog(
          title: const Text('Novo programa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nome, decoration: dec('Nome *')),
                const SizedBox(height: 10),
                TextField(
                    controller: objetivo, decoration: dec('Objetivo')),
                const SizedBox(height: 10),
                TextField(
                    controller: macro, decoration: dec('Macrociclo')),
                const SizedBox(height: 10),
                TextField(controller: meso, decoration: dec('Mesociclo')),
                const SizedBox(height: 10),
                TextField(
                    controller: micro, decoration: dec('Microciclo')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: inicio,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => inicio = d);
                        },
                        child: Text('Início: ${fmt.format(inicio)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: fim,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2031),
                          );
                          if (d != null) setState(() => fim = d);
                        },
                        child: Text('Fim: ${fmt.format(fim)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: obs,
                    maxLines: 2,
                    decoration: dec('Observações')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Criar programa'),
            ),
          ],
        );
      },
    ),
  );
  if (salvar != true || nome.text.trim().isEmpty) return;
  await ref.read(treinoRepositoryProvider).salvarPrograma(Programa(
        id: 'pg-novo-${DateTime.now().millisecondsSinceEpoch}',
        alunoId: alunoId,
        nome: nome.text.trim(),
        objetivo: objetivo.text.trim(),
        inicio: inicio,
        fim: fim.isAfter(inicio)
            ? fim
            : inicio.add(const Duration(days: 28)),
        macrociclo: macro.text.trim(),
        mesociclo: meso.text.trim(),
        microciclo: micro.text.trim(),
        observacoes: obs.text.trim(),
      ));
  ref.invalidate(programasProvider(alunoId));
}
