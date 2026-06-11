import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Notificação derivada dos dados do aluno (Fase 1: sem push real;
/// na Fase 2 virá do FCM + Supabase).
class NotificacaoApp {
  const NotificacaoApp({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.icone,
  });

  final String id;
  final String titulo;
  final String corpo;
  final IconData icone;
}

final notificacoesProvider = FutureProvider<List<NotificacaoApp>>((ref) async {
  final treino = await ref.watch(treinoDoDiaProvider.future);
  final agenda = await ref.watch(agendaProvider(alunoLogadoId).future);
  final agora = DateTime.now();

  final lista = <NotificacaoApp>[
    if (treino != null)
      NotificacaoApp(
        id: 'treino-${treino.id}-${agora.day}',
        titulo: 'Seu treino de hoje te espera 💪',
        corpo: '${treino.nome} — ${treino.foco} '
            '(${treino.itens.length} exercícios). Bora?',
        icone: Icons.fitness_center,
      ),
    for (final a in agenda)
      if (a.status != StatusAgendamento.cancelado &&
          a.dataHora.difference(agora).inHours <= 36)
        NotificacaoApp(
          id: 'agenda-${a.id}',
          titulo: a.tipo == TipoAgendamento.avaliacao
              ? 'Avaliação física chegando'
              : 'Lembrete de agendamento',
          corpo: '${a.titulo} · ${fmtDataHora.format(a.dataHora)}'
              '${a.status == StatusAgendamento.pendente ? ' — confirme sua presença na Agenda' : ''}',
          icone: a.tipo == TipoAgendamento.avaliacao
              ? Icons.monitor_weight
              : Icons.event,
        ),
  ];
  return lista;
});

class NotificacoesLidasNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void marcarTodas(Iterable<String> ids) => state = {...state, ...ids};
}

final notificacoesLidasProvider =
    NotifierProvider<NotificacoesLidasNotifier, Set<String>>(
        NotificacoesLidasNotifier.new);

/// Sininho com badge de não-lidas; abre a lista em bottom sheet.
class SinoNotificacoes extends ConsumerWidget {
  const SinoNotificacoes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacoes = ref.watch(notificacoesProvider).valueOrNull ?? [];
    final lidas = ref.watch(notificacoesLidasProvider);
    final naoLidas = notificacoes.where((n) => !lidas.contains(n.id)).length;

    return IconButton(
      tooltip: 'Notificações',
      onPressed: () {
        ref
            .read(notificacoesLidasProvider.notifier)
            .marcarTodas(notificacoes.map((n) => n.id));
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _ListaNotificacoes(notificacoes: notificacoes),
        );
      },
      icon: Badge(
        isLabelVisible: naoLidas > 0,
        label: Text('$naoLidas'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _ListaNotificacoes extends StatelessWidget {
  const _ListaNotificacoes({required this.notificacoes});

  final List<NotificacaoApp> notificacoes;

  @override
  Widget build(BuildContext context) {
    if (notificacoes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Nenhuma notificação por aqui. 😌'),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          for (final n in notificacoes)
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(n.icone,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              title: Text(n.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(n.corpo),
            ),
        ],
      ),
    );
  }
}
