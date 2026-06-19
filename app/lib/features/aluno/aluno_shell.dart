import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

class AlunoShell extends ConsumerWidget {
  const AlunoShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _atualizarDadosDaAba(WidgetRef ref, int i) {
    switch (i) {
      case 0:
        ref.invalidate(treinoDoDiaProvider);
        ref.invalidate(historicoConcluidosProvider(alunoLogadoId));
        ref.invalidate(treinosDoAlunoProvider(alunoLogadoId));
        ref.invalidate(aguaProvider);
      case 1:
        ref.invalidate(pesosProvider(alunoLogadoId));
        ref.invalidate(avaliacoesProvider(alunoLogadoId));
        ref.invalidate(fotosEvolucaoProvider(alunoLogadoId));
      case 2:
        ref.invalidate(agendaProvider(alunoLogadoId));
      case 4:
        ref.invalidate(alunoProvider(alunoLogadoId));
        ref.invalidate(mensalidadesProvider(alunoLogadoId));
        ref.invalidate(medalhasProvider);
    }
  }

  void _navegar(WidgetRef ref, int i) {
    _atualizarDadosDaAba(ref, i);
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  static const _destinos = [
    (icon: Icons.fitness_center_outlined, iconSel: Icons.fitness_center, label: 'Hoje'),
    (icon: Icons.show_chart_outlined, iconSel: Icons.show_chart, label: 'Evolução'),
    (icon: Icons.calendar_month_outlined, iconSel: Icons.calendar_month, label: 'Agenda'),
    (icon: Icons.chat_bubble_outline, iconSel: Icons.chat_bubble, label: 'Chat'),
    (icon: Icons.menu_outlined, iconSel: Icons.menu, label: 'Mais'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;

      if (desktop) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F6),
          body: Row(
            children: [
              _SideRailAluno(
                selectedIndex: shell.currentIndex,
                onSelect: (i) => _navegar(ref, i),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: shell),
            ],
          ),
        );
      }

      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => _navegar(ref, i),
          destinations: _destinos
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.iconSel),
                    label: d.label,
                  ))
              .toList(),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────── Side Rail (desktop)

class _SideRailAluno extends StatelessWidget {
  const _SideRailAluno({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _itens = AlunoShell._destinos;

  @override
  Widget build(BuildContext context) {
    const primaria = Color(0xFF1B8A6B);

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaria,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '360',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '360Fit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _itens.length; i++)
            _ItemRailAluno(
              icon: _itens[i].icon,
              iconSel: _itens[i].iconSel,
              label: _itens[i].label,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _ItemRailAluno extends StatelessWidget {
  const _ItemRailAluno({
    required this.icon,
    required this.iconSel,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData iconSel;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaria = Color(0xFF1B8A6B);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? primaria.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? iconSel : icon,
                  size: 20,
                  color: selected ? primaria : const Color(0xFF666680),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? primaria : const Color(0xFF444455),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
