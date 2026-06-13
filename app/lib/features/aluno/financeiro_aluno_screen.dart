import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Tela "Financeiro" do aluno: mensalidades do acompanhamento com o
/// profissional, destacando pendências.
class FinanceiroAlunoScreen extends ConsumerWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mensalidadesAsync = ref.watch(mensalidadesProvider(alunoLogadoId));
    final brand = context.brand;
    final fmt = DateFormat('MM/y');

    return Scaffold(
      appBar: AppBar(title: const Text('Financeiro')),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: AsyncView(
          value: mensalidadesAsync,
          builder: (mensalidades) {
            if (mensalidades.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nenhuma mensalidade gerada pelo seu profissional '
                    'ainda.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final pendentes = mensalidades.where((m) => !m.paga).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SectionTitle(pendentes.isEmpty
                    ? 'Tudo certo por aqui ✅'
                    : 'Mensalidades pendentes'),
                if (pendentes.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Você não tem mensalidades pendentes.'),
                    ),
                  )
                else
                  for (final m in pendentes)
                    Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          m.atrasada ? Icons.error : Icons.schedule,
                          color: m.atrasada
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        title: Text(
                            '${fmt.format(m.competencia)} · R\$ ${m.valor.toStringAsFixed(2)}'),
                        subtitle: Text(m.atrasada
                            ? 'ATRASADA — venceu ${DateFormat('dd/MM').format(m.vencimento)}'
                            : 'Vence ${DateFormat('dd/MM').format(m.vencimento)}'),
                      ),
                    ),
                const SectionTitle('Histórico'),
                for (final m in mensalidades.where((m) => m.paga))
                  Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.check_circle, color: brand.sucesso),
                      title: Text(
                          '${fmt.format(m.competencia)} · R\$ ${m.valor.toStringAsFixed(2)}'),
                      subtitle: Text(
                          'Paga em ${DateFormat('dd/MM').format(m.pagoEm!)}'),
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
