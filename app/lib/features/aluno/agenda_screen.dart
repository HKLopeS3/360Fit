import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

class AgendaAlunoScreen extends ConsumerWidget {
  const AgendaAlunoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider(alunoLogadoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha agenda'),
        actions: const [LogoutButton()],
      ),
      body: PaginaCentralizada(
        child: AsyncView(
          value: agendaAsync,
          builder: (agendamentos) => agendamentos.isEmpty
              ? const Center(child: Text('Nenhum agendamento futuro.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final a in agendamentos)
                      AgendamentoCard(agendamento: a),
                  ],
                ),
        ),
      ),
    );
  }
}

class AgendamentoCard extends StatelessWidget {
  const AgendamentoCard({super.key, required this.agendamento, this.rodape});

  final Agendamento agendamento;
  final String? rodape;

  static const _icones = {
    TipoAgendamento.treino: Icons.fitness_center,
    TipoAgendamento.avaliacao: Icons.monitor_weight,
    TipoAgendamento.consulta: Icons.video_call,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoje = DateTime.now();
    final ehHoje = agendamento.dataHora.day == hoje.day &&
        agendamento.dataHora.month == hoje.month &&
        agendamento.dataHora.year == hoje.year;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            _icones[agendamento.tipo],
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(agendamento.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${fmtDataHora.format(agendamento.dataHora)}\n${agendamento.local}'
            '${rodape != null ? '\n$rodape' : ''}',
          ),
        ),
        isThreeLine: true,
        trailing: ehHoje
            ? Chip(
                label: const Text('Hoje'),
                backgroundColor: theme.colorScheme.primary,
                labelStyle: const TextStyle(color: Colors.white),
                visualDensity: VisualDensity.compact,
              )
            : null,
      ),
    );
  }
}
