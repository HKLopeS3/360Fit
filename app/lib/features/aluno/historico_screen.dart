import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Histórico de treinos concluídos: calendário de frequência + lista.
class HistoricoScreen extends ConsumerStatefulWidget {
  const HistoricoScreen({super.key});

  @override
  ConsumerState<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends ConsumerState<HistoricoScreen> {
  late DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final historicoAsync =
        ref.watch(historicoConcluidosProvider(alunoLogadoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de treinos')),
      body: PaginaCentralizada(
        child: AsyncView(
          value: historicoAsync,
          builder: (historico) {
            final diasComTreino = {
              for (final c in historico)
                if (c.data.year == _mes.year && c.data.month == _mes.month)
                  c.data.day,
            };
            final doMes = historico
                .where((c) =>
                    c.data.year == _mes.year && c.data.month == _mes.month)
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Mês anterior',
                              onPressed: () => setState(() =>
                                  _mes = DateTime(_mes.year, _mes.month - 1)),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              capitalizar(
                                  DateFormat('MMMM y').format(_mes)),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Próximo mês',
                              onPressed: () => setState(() =>
                                  _mes = DateTime(_mes.year, _mes.month + 1)),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        _CalendarioMes(mes: _mes, diasMarcados: diasComTreino),
                        const SizedBox(height: 8),
                        Text(
                          '$doMes treino${doMes == 1 ? '' : 's'} neste mês',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Últimos treinos'),
                if (historico.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                          'Nenhum treino concluído ainda. Comece pela aba Hoje!'),
                    ),
                  ),
                for (final c in historico.take(15)) _ConclusaoCard(c: c),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalendarioMes extends StatelessWidget {
  const _CalendarioMes({required this.mes, required this.diasMarcados});

  final DateTime mes;
  final Set<int> diasMarcados;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final primeiroDia = DateTime(mes.year, mes.month, 1);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    // Coluna inicial (segunda = 0).
    final offset = primeiroDia.weekday - 1;
    final hoje = DateTime.now();

    Widget celula(Widget child) => AspectRatio(
          aspectRatio: 1,
          child: Center(child: child),
        );

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'])
              Expanded(
                child: Center(
                  child: Text(d,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var semana = 0; semana * 7 < offset + diasNoMes; semana++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(builder: (context) {
                    final dia = semana * 7 + col - offset + 1;
                    if (dia < 1 || dia > diasNoMes) {
                      return celula(const SizedBox());
                    }
                    final marcado = diasMarcados.contains(dia);
                    final ehHoje = hoje.year == mes.year &&
                        hoje.month == mes.month &&
                        hoje.day == dia;
                    return celula(
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: marcado ? brand.sucesso : null,
                          shape: BoxShape.circle,
                          border: ehHoje && !marcado
                              ? Border.all(
                                  color: theme.colorScheme.primary, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dia',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                marcado ? FontWeight.w700 : FontWeight.w400,
                            color: marcado ? Colors.white : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
      ],
    );
  }
}

class _ConclusaoCard extends StatelessWidget {
  const _ConclusaoCard({required this.c});

  final TreinoConcluido c;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: brand.sucesso.withValues(alpha: 0.15),
          child: Icon(Icons.check, color: brand.sucesso),
        ),
        title: Text(c.nomeTreino,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${fmtDiaMes.format(c.data)} · ${c.duracaoMin} min · '
          '${c.series.length} séries · ${c.volumeTotalKg.toStringAsFixed(0)} kg',
        ),
      ),
    );
  }
}
