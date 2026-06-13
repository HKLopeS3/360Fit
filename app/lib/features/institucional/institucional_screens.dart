import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/contato.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import '../aluno/perfil_screen.dart';
import '../personal/financeiro_config_screen.dart';
import '../personal/perfil_personal_screen.dart';
import 'politicas_conteudo.dart';

Future<void> _abrirEmail(BuildContext context, {String? assunto}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: Contato.email,
    query: assunto == null ? null : 'subject=${Uri.encodeComponent(assunto)}',
  );
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Escreva para ${Contato.email}')),
    );
  }
}

Future<void> _abrirTelefone(BuildContext context) async {
  final ok = await launchUrl(Uri(scheme: 'tel', path: Contato.telefoneLink));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ligue para ${Contato.telefone}')),
    );
  }
}

// ================================================================== aba Mais

class MaisScreen extends ConsumerWidget {
  const MaisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final theme = Theme.of(context);

    void abrir(Widget tela) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => tela));

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (sessao != null)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: IniciaisAvatar(
                    sessao.nome
                        .split(' ')
                        .map((p) => p.isEmpty ? '' : p[0])
                        .take(2)
                        .join(),
                  ),
                  title: Text(sessao.nome,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    sessao.perfil == PerfilUsuario.aluno
                        ? '${sessao.email}\nToque para ver e editar seu perfil'
                        : '${sessao.email}\nToque para ver e editar seu perfil',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: sessao.perfil == PerfilUsuario.aluno
                      ? () => abrir(const PerfilAlunoScreen())
                      : () => abrir(const PerfilPersonalScreen()),
                ),
              ),
            if (sessao?.perfil == PerfilUsuario.personal) ...[
              const SectionTitle('Conta'),
              _ItemMenu(
                icone: Icons.person_outline,
                titulo: 'Meu perfil',
                aoTocar: () => abrir(const PerfilPersonalScreen()),
              ),
              _ItemMenu(
                icone: Icons.attach_money,
                titulo: 'Financeiro',
                aoTocar: () => abrir(const FinanceiroConfigScreen()),
              ),
            ],
            const SectionTitle('Suporte'),
            _ItemMenu(
              icone: Icons.help_outline,
              titulo: 'Ajuda e perguntas frequentes',
              aoTocar: () => abrir(const AjudaScreen()),
            ),
            _ItemMenu(
              icone: Icons.alternate_email,
              titulo: 'Fale conosco',
              subtitulo: '${Contato.email} · ${Contato.telefone}',
              aoTocar: () => abrir(const ContatoScreen()),
            ),
            const SectionTitle('Institucional'),
            _ItemMenu(
              icone: Icons.work_outline,
              titulo: 'Trabalhe conosco',
              aoTocar: () => abrir(const TrabalheConoscoScreen()),
            ),
            _ItemMenu(
              icone: Icons.info_outline,
              titulo: 'Sobre o ${Contato.nomeApp}',
              aoTocar: () => abrir(const SobreScreen()),
            ),
            const SectionTitle('Legal'),
            _ItemMenu(
              icone: Icons.privacy_tip_outlined,
              titulo: 'Política de privacidade',
              aoTocar: () =>
                  abrir(const DocumentoScreen(doc: politicaPrivacidade)),
            ),
            _ItemMenu(
              icone: Icons.description_outlined,
              titulo: 'Termos de uso',
              aoTocar: () => abrir(const DocumentoScreen(doc: termosDeUso)),
            ),
            _ItemMenu(
              icone: Icons.delete_outline,
              titulo: 'Excluir minha conta',
              corTitulo: theme.colorScheme.error,
              aoTocar: () => _confirmarExclusao(context, ref),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(sessaoProvider.notifier).sair();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${Contato.nomeApp} · versão 0.1.0 (demonstração)',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Sua conta será desativada agora e todos os seus dados (perfil, '
          'treinos, avaliações, mensagens e fotos) serão apagados '
          'definitivamente em até 30 dias, conforme a Política de '
          'Privacidade.\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
    if (confirmou != true || !context.mounted) return;
    // Fase 1 (demo): registra a intenção e encerra a sessão.
    // Fase 2: chamará a Edge Function de exclusão no Supabase.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Solicitação registrada. Você receberá a confirmação por email.'),
      ),
    );
    await ref.read(sessaoProvider.notifier).sair();
    if (context.mounted) context.go('/login');
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.titulo,
    required this.aoTocar,
    this.subtitulo,
    this.corTitulo,
  });

  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final Color? corTitulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icone, color: corTitulo),
        title: Text(titulo,
            style: TextStyle(fontWeight: FontWeight.w600, color: corTitulo)),
        subtitle: subtitulo == null
            ? null
            : Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: aoTocar,
      ),
    );
  }
}

// ====================================================================== Ajuda

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  static const _faq = [
    (
      'Como vejo meu treino do dia?',
      'Na aba "Hoje" você encontra o treino previsto para o dia da semana, '
          'com séries, repetições e cargas. Marque cada exercício ao concluir.'
    ),
    (
      'Esqueci minha senha. E agora?',
      'Na tela de login toque em "Esqueci minha senha" (disponível quando o '
          'acesso por email/senha estiver ativo) ou fale com a sua academia.'
    ),
    (
      'Como falo com meu personal?',
      'Use a aba "Chat" — seu profissional recebe a mensagem na hora.'
    ),
    (
      'Como remarco um horário?',
      'Os agendamentos aparecem na aba "Agenda". Para remarcar, combine pelo '
          'chat com o seu profissional.'
    ),
    (
      'Meus dados estão seguros?',
      'Sim. Seus dados ficam isolados no ambiente da sua academia e só são '
          'vistos por você, pelo profissional responsável e pelo administrador. '
          'Veja a Política de Privacidade em Mais → Legal.'
    ),
    (
      'Como excluo minha conta?',
      'Em Mais → Excluir minha conta, ou enviando email para ${Contato.email}. '
          'Os dados são apagados definitivamente em até 30 dias.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda')),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle('Perguntas frequentes'),
            for (final (pergunta, resposta) in _faq)
              Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(pergunta,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(resposta),
                    ),
                  ],
                ),
              ),
            const SectionTitle('Não encontrou o que precisava?'),
            FilledButton.icon(
              onPressed: () =>
                  _abrirEmail(context, assunto: 'Ajuda — ${Contato.nomeApp}'),
              icon: const Icon(Icons.alternate_email),
              label: const Text('Enviar email para o suporte'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== Contato

class ContatoScreen extends StatelessWidget {
  const ContatoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fale conosco')),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle('Canais de atendimento'),
            Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Email'),
                subtitle: const Text(Contato.email),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _abrirEmail(context),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Telefone / WhatsApp'),
                subtitle: const Text(Contato.telefone),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _abrirTelefone(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Atendemos de segunda a sexta, das 8h às 18h (horário de '
              'Brasília). Respondemos emails em até 1 dia útil.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================== Trabalhe conosco

class TrabalheConoscoScreen extends StatelessWidget {
  const TrabalheConoscoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trabalhe conosco')),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vem construir o futuro do fitness com a gente 💪',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const Text(
                      'O ${Contato.nomeApp} está crescendo e busca pessoas '
                      'apaixonadas por tecnologia, saúde e performance: '
                      'desenvolvimento (Flutter, Supabase), design de produto, '
                      'sucesso do cliente e vendas.\n\n'
                      'Envie seu currículo ou portfólio com a vaga de interesse '
                      'no assunto do email. Respondemos a todas as candidaturas.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _abrirEmail(
                context,
                assunto: 'Candidatura — Trabalhe conosco',
              ),
              icon: const Icon(Icons.send),
              label: const Text('Enviar candidatura'),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                Contato.email,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================== Sobre

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o ${Contato.nomeApp}')),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center,
                        size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(Contato.nomeApp,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Gestão fitness, saúde e performance'),
                    const SizedBox(height: 16),
                    const Text(
                      'Plataforma que conecta academias, personal trainers, '
                      'nutricionistas, fisioterapeutas e alunos em um só '
                      'lugar: treinos, evolução, agenda, comunicação e gestão '
                      'do negócio.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text('Versão 0.1.0 — demonstração',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ documento legal

class DocumentoScreen extends StatelessWidget {
  const DocumentoScreen({super.key, required this.doc});

  final DocumentoLegal doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(doc.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Última atualização: ${doc.atualizadoEm}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final (i, secao) in doc.secoes.indexed) ...[
              SectionTitle('${i + 1}. ${secao.titulo}'),
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(secao.corpo, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
