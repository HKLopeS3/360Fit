import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../app/theme/brand_theme.dart';
import '../core/models/models.dart';
import '../data/providers.dart';

/// Botão de sair usado nas AppBars de ambos os perfis.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sair',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await ref.read(sessaoProvider.notifier).sair();
        if (context.mounted) context.go('/login');
      },
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (tablet/desktop),
/// mantendo as listas legíveis e centralizadas.
class PaginaCentralizada extends StatelessWidget {
  const PaginaCentralizada({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Renderiza um [AsyncValue] com loading/erro padrão.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Algo deu errado: $e'),
        ),
      ),
    );
  }
}

/// Título de seção com barra colorida lateral — padrão do design system.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.texto, {super.key, this.trailing, this.topPadding = 20});

  final String texto;
  final Widget? trailing;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final cor = context.brand.primaria;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, topPadding, 0, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card branco com sombra sutil — padrão do design system.
/// Substitui `Card(color: Colors.white)` em toda a app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 16,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: kShadowCard,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}

/// Estado vazio padronizado.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icone,
    required this.titulo,
    this.descricao,
    this.acao,
    this.rotuloAcao,
  });

  final IconData icone;
  final String titulo;
  final String? descricao;
  final VoidCallback? acao;
  final String? rotuloAcao;

  @override
  Widget build(BuildContext context) {
    final cor = context.brand.primaria;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 36, color: cor),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            if (descricao != null) ...[
              const SizedBox(height: 6),
              Text(
                descricao!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (acao != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: acao, child: Text(rotuloAcao ?? 'Ok')),
            ],
          ],
        ),
      ),
    );
  }
}

class IniciaisAvatar extends StatelessWidget {
  const IniciaisAvatar(this.iniciais, {super.key, this.raio = 22});

  final String iniciais;
  final double raio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: raio,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        iniciais,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: raio * 0.7,
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    this.icone,
    this.corIcone,
  });

  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData? icone;
  final Color? corIcone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 18, color: corIcone ?? theme.colorScheme.primary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: kTextPrimary),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitulo!,
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card expansível com o resumo de um treino (usado no detalhe do aluno
/// e na seção "Meus treinos" da aba Hoje).
class TreinoResumoCard extends ConsumerWidget {
  const TreinoResumoCard({super.key, required this.treino});

  final Treino treino;

  static const _dias = {
    DateTime.monday: 'Seg',
    DateTime.tuesday: 'Ter',
    DateTime.wednesday: 'Qua',
    DateTime.thursday: 'Qui',
    DateTime.friday: 'Sex',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicios = ref.read(exercicioRepositoryProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kShadowCard,
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text('${treino.nome} — ${treino.foco}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${treino.itens.length} exercícios · '
          '${treino.diasSemana.map((d) => _dias[d]).join(', ')}',
        ),
        children: [
          for (final item in treino.itens)
            ListTile(
              dense: true,
              leading: const Icon(Icons.fitness_center, size: 18),
              title: Text(exercicios.porId(item.exercicioId).nome),
              trailing: Text('${item.series}x ${item.repeticoes}'),
            ),
        ],
      ),
    );
  }
}

/// Dois cards de métrica lado a lado; empilha em telas muito estreitas
/// para os números não ficarem espremidos.
class ParDeMetricas extends StatelessWidget {
  const ParDeMetricas({super.key, required this.primeiro, required this.segundo});

  final Widget primeiro;
  final Widget segundo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [primeiro, const SizedBox(height: 12), segundo],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: primeiro),
            const SizedBox(width: 12),
            Expanded(child: segundo),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ formatos

final fmtDiaMes = DateFormat('dd/MM');
final fmtDataCurta = DateFormat('dd/MM/yyyy');
final fmtDataCompleta = DateFormat("EEEE, d 'de' MMMM");
final fmtDataHora = DateFormat("dd/MM 'às' HH:mm");
final fmtHora = DateFormat('HH:mm');

String capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Substituto responsivo para Scaffold + AppBar.
/// - Desktop (≥900px): sem AppBar; mostra barra superior branca com título e ações
/// - Mobile (<900px): Scaffold normal com AppBar
class TelaResponsiva extends StatelessWidget {
  const TelaResponsiva({
    super.key,
    required this.titulo,
    required this.body,
    this.actions = const [],
    this.toolbarHeight = kToolbarHeight,
    this.backgroundColor,
    this.floatingActionButton,
  });

  final String titulo;
  final Widget body;
  final List<Widget> actions;
  final double toolbarHeight;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final bgColor = backgroundColor ?? const Color(0xFFF4F7F6);

    if (desktop) {
      return Scaffold(
        backgroundColor: bgColor,
        floatingActionButton: floatingActionButton,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFE8EAF0)),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        title: Text(titulo),
        toolbarHeight: toolbarHeight,
        actions: actions,
      ),
      body: body,
    );
  }
}
