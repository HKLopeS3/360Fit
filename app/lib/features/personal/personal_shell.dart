import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';

class PersonalShell extends ConsumerWidget {
  const PersonalShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _atualizarDadosDaAba(WidgetRef ref, int i) {
    switch (i) {
      case 0:
        ref.invalidate(alunosProvider);
        ref.invalidate(treinosSemanaProvider);
        ref.invalidate(alertasProvider);
      case 1:
        ref.invalidate(alunosProvider);
      case 2:
        ref.invalidate(alunosProvider);
        ref.invalidate(bibliotecaExerciciosProvider);
      case 3:
        ref.invalidate(agendaProvider(null));
        ref.invalidate(alunosProvider);
      case 4:
        ref.invalidate(configuracaoEmpresaProvider);
    }
  }

  void _navegar(WidgetRef ref, int i) {
    _atualizarDadosDaAba(ref, i);
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  static const _destinos = [
    (icon: Icons.dashboard_outlined, iconSel: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.group_outlined, iconSel: Icons.group, label: 'Alunos'),
    (icon: Icons.edit_note_outlined, iconSel: Icons.edit_note, label: 'Prescrição'),
    (icon: Icons.calendar_month_outlined, iconSel: Icons.calendar_month, label: 'Agenda'),
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
              _SideRail(
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

class _SideRail extends StatelessWidget {
  const _SideRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _itens = PersonalShell._destinos;

  @override
  Widget build(BuildContext context) {
    final primaria = const Color(0xFF1B8A6B);

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          // Logo / cabeçalho
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

          // Itens de navegação
          const SizedBox(height: 8),
          for (var i = 0; i < _itens.length; i++) ...[
            _ItemRail(
              icon: _itens[i].icon,
              iconSel: _itens[i].iconSel,
              label: _itens[i].label,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
              primaria: primaria,
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRail extends StatelessWidget {
  const _ItemRail({
    required this.icon,
    required this.iconSel,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primaria,
  });

  final IconData icon;
  final IconData iconSel;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primaria;

  @override
  Widget build(BuildContext context) {
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
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
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
