import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';

/// Tela de criação de conta.
///
/// Sem código de convite, vira um profissional dono da própria empresa
/// (tenant); com um código de convite (gerado pelo profissional ao
/// cadastrar um aluno), vira o login desse aluno.
class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  final _codigoConvite = TextEditingController();
  bool _ocultarSenha = true;
  bool _criando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    _codigoConvite.dispose();
    super.dispose();
  }

  String _mensagemErro(Object e) {
    if (e is AuthException) {
      if (e.message.contains('Código de convite inválido')) {
        return 'Código de convite inválido.';
      }
      if (e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered')) {
        return 'Já existe uma conta com este email.';
      }
      return 'Não foi possível criar a conta agora. Tente novamente.';
    }
    return 'Falha de conexão. Verifique sua internet e tente novamente.';
  }

  Future<void> _criar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _criando = true);
    final codigo = _codigoConvite.text.trim().toUpperCase();
    try {
      if (codigo.isNotEmpty) {
        final valido =
            await ref.read(authRepositoryProvider).validarCodigoConvite(codigo);
        if (!valido) {
          throw const AuthException('Código de convite inválido');
        }
      }
      final usuario = await ref.read(authRepositoryProvider).registrar(
            _nome.text.trim(),
            _email.text.trim(),
            _senha.text,
            codigoConvite: codigo.isEmpty ? null : codigo,
          );
      if (!mounted) return;
      if (usuario == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirme seu email'),
            content: const Text(
                'Enviamos um link de confirmação para o seu email. '
                'Abra-o para ativar sua conta e depois faça login.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        context.go('/login');
        return;
      }
      context.go(usuario.perfil == PerfilUsuario.aluno
          ? '/aluno/hoje'
          : '/personal/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _criando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(e))),
      );
    }
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
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.person_add_alt_1,
                            size: 48, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Criar conta',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profissionais criam sua própria empresa. '
                          'Alunos usam o código de convite recebido do '
                          'seu personal.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nome,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().length < 3)
                              ? 'Informe seu nome'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.newUsername],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final email = v?.trim() ?? '';
                            if (email.isEmpty) return 'Informe seu email';
                            if (!email.contains('@') ||
                                !email.contains('.')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _senha,
                          obscureText: _ocultarSenha,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _ocultarSenha
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              icon: Icon(_ocultarSenha
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _ocultarSenha = !_ocultarSenha),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo de 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmarSenha,
                          obscureText: _ocultarSenha,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v != _senha.text
                              ? 'As senhas não coincidem'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _codigoConvite,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Código de convite (se você é aluno)',
                            prefixIcon: Icon(Icons.confirmation_number_outlined),
                            border: OutlineInputBorder(),
                            helperText: 'Deixe em branco se você é um '
                                'profissional criando sua empresa.',
                            helperMaxLines: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _criando ? null : _criar,
                          icon: _criando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Criar conta'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Já tenho conta — Entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
