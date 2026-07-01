import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/mock_data.dart' as mock;
import 'core/theme.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/alunos/aluno_detalhe_screen.dart';
import 'features/alunos/alunos_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/financeiro/financeiro_screen.dart';
import 'shared/widgets.dart';

// ── Roteamento ────────────────────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AcademyShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/alunos',
            builder: (_, __) => const AlunosScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => AlunoDetalheScreen(
                    alunoId: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/financeiro',
              builder: (_, __) => const FinanceiroScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/agenda',
              builder: (_, __) => const AgendaScreen()),
        ]),
      ],
    ),
  ],
);

// ── App ───────────────────────────────────────────────────────────────────────
class AcademyApp extends StatelessWidget {
  const AcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '360Fit Academy',
      theme: academyTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ── Shell com sidebar ─────────────────────────────────────────────────────────
const _destinos = [
  (icon: Icons.dashboard_outlined,    iconSel: Icons.dashboard,    label: 'Dashboard',   path: '/dashboard'),
  (icon: Icons.people_outline,        iconSel: Icons.people,       label: 'Alunos',      path: '/alunos'),
  (icon: Icons.attach_money,          iconSel: Icons.attach_money, label: 'Financeiro',  path: '/financeiro'),
  (icon: Icons.calendar_month_outlined,iconSel: Icons.calendar_month,label: 'Agenda',    path: '/agenda'),
];

class _AcademyShell extends StatelessWidget {
  const _AcademyShell({required this.shell});
  final StatefulNavigationShell shell;

  void _navegar(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    if (desktop) {
      return Scaffold(
        backgroundColor: kBgPage,
        body: Row(
          children: [
            _Sidebar(selectedIndex: shell.currentIndex, onSelect: _navegar),
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
        onDestinationSelected: _navegar,
        destinations: _destinos
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.iconSel),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

// ── Sidebar desktop ───────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: const Align(
                alignment: Alignment.centerLeft, child: LogoAcademy()),
          ),
          // Informações da academia
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mock.usuarioDemo.academiaNome,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTxt1)),
                Text(mock.usuarioDemo.perfil == mock.usuarioDemo.perfil
                    ? 'Gestor'
                    : 'Recepcionista',
                    style:
                        const TextStyle(fontSize: 11, color: kTxt2)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 16),
          ),
          // Itens de navegação
          for (int i = 0; i < _destinos.length; i++)
            _ItemSidebar(
              icon: _destinos[i].icon,
              iconSel: _destinos[i].iconSel,
              label: _destinos[i].label,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          const Divider(),
          // Usuário logado
          ListTile(
            leading: AvatarIniciais(
              mock.usuarioDemo.nome.split(' ').map((p) => p[0]).take(2).join(),
              radius: 18,
            ),
            title: Text(mock.usuarioDemo.nome,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Gestor',
                style: TextStyle(fontSize: 11, color: kTxt2)),
            trailing: const Icon(Icons.logout, size: 18, color: kTxt2),
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ItemSidebar extends StatelessWidget {
  const _ItemSidebar({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected
            ? kPrimaria.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? iconSel : icon,
                  size: 20,
                  color: selected ? kPrimaria : kTxt2,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? kPrimaria : kTxt1,
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
