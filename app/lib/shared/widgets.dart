import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.texto, {super.key, this.trailing});

  final String texto;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
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
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
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
