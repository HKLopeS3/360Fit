import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

class AlunoShell extends ConsumerWidget {
  const AlunoShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Providers a invalidar ao abrir cada aba, para que os dados sejam
  /// buscados novamente no banco a cada visita.
  void _atualizarDadosDaAba(WidgetRef ref, int i) {
    switch (i) {
      case 0: // Hoje
        ref.invalidate(treinoDoDiaProvider);
        ref.invalidate(historicoConcluidosProvider(alunoLogadoId));
        ref.invalidate(treinosDoAlunoProvider(alunoLogadoId));
        ref.invalidate(aguaProvider);
      case 1: // Evolução
        ref.invalidate(pesosProvider(alunoLogadoId));
        ref.invalidate(avaliacoesProvider(alunoLogadoId));
        ref.invalidate(fotosEvolucaoProvider(alunoLogadoId));
      case 2: // Agenda
        ref.invalidate(agendaProvider(alunoLogadoId));
      case 4: // Mais
        ref.invalidate(alunoProvider(alunoLogadoId));
        ref.invalidate(mensalidadesProvider(alunoLogadoId));
        ref.invalidate(medalhasProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) {
          _atualizarDadosDaAba(ref, i);
          shell.goBranch(
            i,
            initialLocation: i == shell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Evolução',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_outlined),
            selectedIcon: Icon(Icons.menu),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}
