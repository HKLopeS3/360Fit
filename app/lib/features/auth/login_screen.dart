import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/config/contato.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../institucional/institucional_screens.dart';
import '../institucional/politicas_conteudo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  PerfilUsuario? _entrando;

  Future<void> _entrar(PerfilUsuario perfil) async {
    setState(() => _entrando = perfil);
    await ref.read(sessaoProvider.notifier).entrar(perfil);
    if (!mounted) return;
    context.go(
      perfil == PerfilUsuario.aluno ? '/aluno/hoje' : '/personal/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: brand.gradientePrimario,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        brand.nomeMarca,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestão fitness, saúde e performance',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Ambiente de demonstração — escolha um perfil:',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _entrando != null
                            ? null
                            : () => _entrar(PerfilUsuario.aluno),
                        icon: _entrando == PerfilUsuario.aluno
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person),
                        label: const Text('Entrar como Aluno'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _entrando != null
                            ? null
                            : () => _entrar(PerfilUsuario.personal),
                        icon: _entrando == PerfilUsuario.personal
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.assignment_ind),
                        label: const Text('Entrar como Personal'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  const SizedBox(height: 16),
                  const _RodapeInstitucional(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rodapé com links institucionais e contato, visível antes do login.
class _RodapeInstitucional extends StatelessWidget {
  const _RodapeInstitucional();

  @override
  Widget build(BuildContext context) {
    void abrir(Widget tela) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => tela));

    TextButton link(String rotulo, VoidCallback aoTocar) => TextButton(
          onPressed: aoTocar,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            textStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: Text(rotulo),
        );

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            link('Ajuda', () => abrir(const AjudaScreen())),
            link('Trabalhe conosco',
                () => abrir(const TrabalheConoscoScreen())),
            link('Privacidade',
                () => abrir(const DocumentoScreen(doc: politicaPrivacidade))),
            link('Termos',
                () => abrir(const DocumentoScreen(doc: termosDeUso))),
            link('Contato', () => abrir(const ContatoScreen())),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '${Contato.email} · ${Contato.telefone}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
