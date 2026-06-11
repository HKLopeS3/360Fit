import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

class AgendaAlunoScreen extends ConsumerWidget {
  const AgendaAlunoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(agendaProvider(alunoLogadoId));

    Future<void> confirmar(Agendamento a) async {
      await ref.read(agendaRepositoryProvider).confirmarPresenca(a.id);
      ref.invalidate(agendaProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presença confirmada! 💪')),
      );
    }

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
                      AgendamentoCard(
                        agendamento: a,
                        acoes: a.status == StatusAgendamento.pendente
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: FilledButton.tonalIcon(
                                  onPressed: () => confirmar(a),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Confirmar presença'),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AgendamentoCard extends StatelessWidget {
  const AgendamentoCard({
    super.key,
    required this.agendamento,
    this.rodape,
    this.acoes,
    this.menu,
  });

  final Agendamento agendamento;
  final String? rodape;

  /// Widget de ação abaixo do conteúdo (ex.: confirmar presença).
  final Widget? acoes;

  /// Menu no canto (ex.: remarcar/cancelar do personal).
  final Widget? menu;

  static const _icones = {
    TipoAgendamento.treino: Icons.fitness_center,
    TipoAgendamento.avaliacao: Icons.monitor_weight,
    TipoAgendamento.consulta: Icons.video_call,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final hoje = DateTime.now();
    final ehHoje = agendamento.dataHora.day == hoje.day &&
        agendamento.dataHora.month == hoje.month &&
        agendamento.dataHora.year == hoje.year;
    final cancelado = agendamento.status == StatusAgendamento.cancelado;

    final (statusRotulo, statusCor) = switch (agendamento.status) {
      StatusAgendamento.pendente => ('Pendente', theme.colorScheme.outline),
      StatusAgendamento.confirmado => ('Confirmado', brand.sucesso),
      StatusAgendamento.cancelado => ('Cancelado', theme.colorScheme.error),
    };

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                _icones[agendamento.tipo],
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              agendamento.titulo,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: cancelado ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${fmtDataHora.format(agendamento.dataHora)}\n${agendamento.local}'
                '${rodape != null ? '\n$rodape' : ''}',
              ),
            ),
            isThreeLine: true,
            trailing: menu ??
                (ehHoje && !cancelado
                    ? Chip(
                        label: const Text('Hoje'),
                        backgroundColor: theme.colorScheme.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                        visualDensity: VisualDensity.compact,
                      )
                    : null),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: statusCor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(statusRotulo,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: statusCor)),
              ],
            ),
          ),
          if (acoes != null) acoes!,
        ],
      ),
    );
  }
}
