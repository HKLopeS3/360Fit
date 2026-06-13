import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

import '../features/aluno/agenda_screen.dart';
import '../features/aluno/aluno_shell.dart';
import '../features/aluno/chat_screen.dart';
import '../features/aluno/evolucao_screen.dart';
import '../features/aluno/hoje_screen.dart';
import '../features/auth/cadastro_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/institucional/institucional_screens.dart';
import '../features/personal/agenda_personal_screen.dart';
import '../features/personal/aluno_detalhe_screen.dart';
import '../features/personal/alunos_screen.dart';
import '../features/personal/dashboard_screen.dart';
import '../features/personal/personal_shell.dart';
import '../features/personal/prescricao_screen.dart';

/// Router global; o boot pode recriá-lo apontando direto para a home do
/// papel quando há sessão persistida (ver main.dart).
GoRouter router = criarRouter();

GoRouter criarRouter({String initialLocation = '/login'}) => GoRouter(
  initialLocation: initialLocation,
  // Protege deep links: sem sessão (modo Supabase) tudo volta ao login.
  redirect: (context, state) {
    if (!AppConfig.usarSupabase) return null;
    final logado = Supabase.instance.client.auth.currentSession != null;
    const publicas = {'/login', '/cadastro'};
    if (!logado && !publicas.contains(state.matchedLocation)) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const CadastroScreen(),
    ),
    // ------------------------------------------------------------- aluno
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AlunoShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aluno/hoje',
            pageBuilder: _semTransicao(const HojeScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aluno/evolucao',
            pageBuilder: _semTransicao(const EvolucaoScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aluno/agenda',
            pageBuilder: _semTransicao(const AgendaAlunoScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aluno/chat',
            pageBuilder: _semTransicao(const ChatScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/aluno/mais',
            pageBuilder: _semTransicao(const MaisScreen()),
          ),
        ]),
      ],
    ),
    // ---------------------------------------------------------- personal
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => PersonalShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/personal/dashboard',
            pageBuilder: _semTransicao(const DashboardScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/personal/alunos',
            pageBuilder: _semTransicao(const AlunosScreen()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    AlunoDetalheScreen(alunoId: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/personal/prescricao',
            pageBuilder: _semTransicao(const PrescricaoScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/personal/agenda',
            pageBuilder: _semTransicao(const AgendaPersonalScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/personal/mais',
            pageBuilder: _semTransicao(const MaisScreen()),
          ),
        ]),
      ],
    ),
  ],
);

GoRouterPageBuilder _semTransicao(Widget child) =>
    (context, state) => NoTransitionPage(child: child);
