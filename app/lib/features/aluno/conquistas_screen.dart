import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Medalhas de consistência derivadas do histórico de treinos.
class ConquistasScreen extends ConsumerWidget {
  const ConquistasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medalhasAsync = ref.watch(medalhasProvider);
    final brand = context.brand;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas conquistas')),
      body: PaginaCentralizada(
        child: AsyncView(
          value: medalhasAsync,
          builder: (medalhas) {
            final ganhas = medalhas.where((m) => m.conquistada).length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '$ganhas de ${medalhas.length} medalhas '
                            'conquistadas',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Medalhas'),
                for (final m in medalhas)
                  Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Opacity(
                      opacity: m.conquistada ? 1 : 0.45,
                      child: ListTile(
                        leading: Text(m.emoji,
                            style: const TextStyle(fontSize: 30)),
                        title: Text(m.titulo,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(m.descricao),
                        trailing: m.conquistada
                            ? Icon(Icons.verified, color: brand.sucesso)
                            : const Icon(Icons.lock_outline),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
