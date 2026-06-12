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
class LoginEmailSenhaForm extends ConsumerStatefulWidget {
  const LoginEmailSenhaForm({super.key});

  @override
  ConsumerState<LoginEmailSenhaForm> createState() =>
      _LoginEmailSenhaFormState();
}

class _LoginEmailSenhaFormState extends ConsumerState<LoginEmailSenhaForm> {
  bool _estahRegistrando = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_estahRegistrando)
          _RegistroAlunoForm(
            aoVoltar: () => setState(() => _estahRegistrando = false),
            aoRegistrarSucesso: () {
              setState(() => _estahRegistrando = false);
              if (context.mounted) {
                context.go('/aluno/hoje');
              }
            },
          )
        else
          _LoginForm(
            aoRegistrar: () => setState(() => _estahRegistrando = true),
          ),
      ],
    );
  }
}

/// Formulário de login com email/senha.
class _LoginForm extends ConsumerStatefulWidget {
  final VoidCallback aoRegistrar;

  const _LoginForm({required this.aoRegistrar});

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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _entrando ? null : widget.aoRegistrar,
            icon: const Icon(Icons.person_add),
            label: const Text('Criar nova conta'),
            style: OutlinedButton.styleFrom(
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

/// Formulário para criar nova conta como aluno.
class _RegistroAlunoForm extends ConsumerStatefulWidget {
  final VoidCallback aoVoltar;
  final VoidCallback aoRegistrarSucesso;

  const _RegistroAlunoForm({
    required this.aoVoltar,
    required this.aoRegistrarSucesso,
  });

  @override
  ConsumerState<_RegistroAlunoForm> createState() =>
      _RegistroAlunoFormState();
}

class _RegistroAlunoFormState extends ConsumerState<_RegistroAlunoForm> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmar = true;
  bool _registrando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  String _mensagemErro(Object e) {
    if (e is AuthException) {
      if (e.code == 'user_already_exists') {
        return 'Este email já está cadastrado.';
      }
      if (e.code == 'weak_password') {
        return 'Senha muito fraca. Use pelo menos 8 caracteres.';
      }
      return 'Não foi possível criar sua conta. Tente novamente.';
    }
    return 'Falha de conexão. Verifique sua internet e tente novamente.';
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    if (_senha.text != _confirmarSenha.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }
    setState(() => _registrando = true);
    try {
      await ref.read(sessaoProvider.notifier).registrar(
            _nome.text.trim(),
            _email.text.trim(),
            _senha.text,
          );
      if (!mounted) return;
      widget.aoRegistrarSucesso();
    } catch (e) {
      if (!mounted) return;
      setState(() => _registrando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Criar nova conta',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Seu nome completo',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
          ),
          const SizedBox(height: 12),
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
            decoration: InputDecoration(
              labelText: 'Senha (mínimo 8 caracteres)',
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe uma senha';
              if (v.length < 8) return 'Senha deve ter pelo menos 8 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmarSenha,
            obscureText: _ocultarConfirmar,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _ocultarConfirmar
                    ? 'Mostrar senha'
                    : 'Ocultar senha',
                icon: Icon(_ocultarConfirmar
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _ocultarConfirmar = !_ocultarConfirmar),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Confirme sua senha' : null,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _registrando ? null : _registrar,
            icon: _registrando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add),
            label: const Text('Criar minha conta'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _registrando ? null : widget.aoVoltar,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Voltar ao login'),
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
