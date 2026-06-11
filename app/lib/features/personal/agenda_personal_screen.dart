import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/agenda_screen.dart';
import 'novo_agendamento_screen.dart';

class AgendaPersonalScreen extends ConsumerWidget {
  const AgendaPersonalScreen({super.key});

  Future<void> _remarcar(
      BuildContext context, WidgetRef ref, Agendamento a) async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: a.dataHora,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (novaData == null || !context.mounted) return;
    final novaHora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(a.dataHora),
    );
    if (novaHora == null) return;
    await ref.read(agendaRepositoryProvider).remarcar(
          a.id,
          DateTime(novaData.year, novaData.month, novaData.day,
              novaHora.hour, novaHora.minute),
        );
    ref.invalidate(agendaProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento remarcado.')),
      );
    }
  }

  Future<void> _cancelar(
      BuildContext context, WidgetRef ref, Agendamento a) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar agendamento?'),
        content: Text('${a.titulo} · ${fmtDataHora.format(a.dataHora)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar agendamento'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await ref.read(agendaRepositoryProvider).cancelar(a.id);
    ref.invalidate(agendaProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider(null));
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda da semana'),
        actions: const [LogoutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NovoAgendamentoScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      body: PaginaCentralizada(
        child: AsyncView(
        value: agendaAsync,
        builder: (agendamentos) => AsyncView(
          value: alunosAsync,
          builder: (alunos) {
            if (agendamentos.isEmpty) {
              return const Center(child: Text('Nenhum agendamento futuro.'));
            }
            String nomeAluno(String id) => alunos
                .firstWhere((a) => a.id == id,
                    orElse: () => alunos.first)
                .nome;

            // Agrupa por dia.
            final porDia = <DateTime, List<dynamic>>{};
            for (final a in agendamentos) {
              final dia = DateTime(
                  a.dataHora.year, a.dataHora.month, a.dataHora.day);
              porDia.putIfAbsent(dia, () => []).add(a);
            }
            final dias = porDia.keys.toList()..sort();
            final fmtDia = DateFormat("EEEE, dd/MM");

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final dia in dias) ...[
                  SectionTitle(capitalizar(fmtDia.format(dia))),
                  for (final a in porDia[dia]!)
                    AgendamentoCard(
                      agendamento: a,
                      rodape: 'Aluno: ${nomeAluno(a.alunoId)}',
                      menu: a.status == StatusAgendamento.cancelado
                          ? null
                          : PopupMenuButton<String>(
                              tooltip: 'Opções',
                              onSelected: (op) => op == 'remarcar'
                                  ? _remarcar(context, ref, a)
                                  : _cancelar(context, ref, a),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'remarcar',
                                  child: Text('Remarcar'),
                                ),
                                PopupMenuItem(
                                  value: 'cancelar',
                                  child: Text('Cancelar'),
                                ),
                              ],
                            ),
                    ),
                ],
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
