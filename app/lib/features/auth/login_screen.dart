import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../app/theme/brand_theme.dart';
import '../../core/config/app_config.dart';
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
                      if (AppConfig.usarSupabase)
                        const LoginEmailSenhaForm()
                      else ...[
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

/// Formulário de autenticação real (modo Supabase).
class LoginEmailSenhaForm extends ConsumerWidget {
  const LoginEmailSenhaForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _LoginForm();
  }
}

/// Formulário de login com email/senha.
class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultarSenha = true;
  bool _entrando = false;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  String _mensagemErro(Object e) {
    if (e is AuthException) {
      if (e.code == 'invalid_credentials' || e.statusCode == '400') {
        return 'Email ou senha incorretos.';
      }
      if (e.code == 'email_not_confirmed') {
        return 'Confirme seu email antes de entrar.';
      }
      return 'Não foi possível entrar agora. Tente novamente.';
    }
    return 'Falha de conexão. Verifique sua internet e tente novamente.';
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _entrando = true);
    try {
      final usuario = await ref
          .read(sessaoProvider.notifier)
          .entrarComEmailSenha(_email.text, _senha.text);
      if (!mounted) return;
      context.go(usuario.perfil == PerfilUsuario.aluno
          ? '/aluno/hoje'
          : '/personal/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _entrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(e))),
      );
    }
  }

  Future<void> _esqueciSenha() async {
    final controller = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email cadastrado',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await ref.read(authRepositoryProvider).recuperarSenha(email);
    } catch (_) {
      // Não revelamos se o email existe — mensagem única abaixo.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Se $email estiver cadastrado, você receberá o link de '
            'recuperação em instantes.'),
      ),
    );
  }

  void _preencherDemo(PerfilUsuario perfil) {
    _email.text = perfil == PerfilUsuario.aluno
        ? 'carlos.mendes@email.com'
        : 'joao.silva@360fit.com.br';
    _senha.text = AppConfig.demoSenha;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) return 'Informe seu email';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _senha,
            obscureText: _ocultarSenha,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _entrar(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(_ocultarSenha
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _ocultarSenha = !_ocultarSenha),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe sua senha' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _esqueciSenha,
              child: const Text('Esqueci minha senha'),
            ),
          ),
          FilledButton.icon(
            onPressed: _entrando ? null : _entrar,
            icon: _entrando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: const Text('Entrar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contas de demonstração:',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person, size: 18),
                label: const Text('Demo aluno'),
                onPressed: () => _preencherDemo(PerfilUsuario.aluno),
              ),
              ActionChip(
                avatar: const Icon(Icons.assignment_ind, size: 18),
                label: const Text('Demo personal'),
                onPressed: () => _preencherDemo(PerfilUsuario.personal),
              ),
            ],
          ),
        ],
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
