import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/agenda_screen.dart';

class AgendaPersonalScreen extends ConsumerWidget {
  const AgendaPersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider(null));
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda da semana'),
        actions: const [LogoutButton()],
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
