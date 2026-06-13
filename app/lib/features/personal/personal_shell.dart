import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

class PersonalShell extends ConsumerWidget {
  const PersonalShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// Providers a invalidar ao abrir cada aba, para que os dados sejam
  /// buscados novamente no banco a cada visita.
  void _atualizarDadosDaAba(WidgetRef ref, int i) {
    switch (i) {
      case 0: // Dashboard
        ref.invalidate(alunosProvider);
        ref.invalidate(treinosSemanaProvider);
        ref.invalidate(alertasProvider);
      case 1: // Alunos
        ref.invalidate(alunosProvider);
      case 2: // Prescrição
        ref.invalidate(alunosProvider);
        ref.invalidate(bibliotecaExerciciosProvider);
      case 3: // Agenda
        ref.invalidate(agendaProvider(null));
        ref.invalidate(alunosProvider);
      case 4: // Mais
        ref.invalidate(configuracaoEmpresaProvider);
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Alunos',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Prescrição',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
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
