import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/mock/mock_database.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Olá, ${sessao?.primeiroNome ?? 'Personal'} 💪',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [LogoutButton()],
      ),
      body: PaginaCentralizada(
        child: AsyncView(
        value: alunosAsync,
        builder: (alunos) {
          final emRisco = alunos.where((a) => a.riscoEvasao).toList();
          final freqMedia = alunos.isEmpty
              ? 0.0
              : alunos
                      .map((a) => a.frequenciaSemanal)
                      .reduce((a, b) => a + b) /
                  alunos.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              ParDeMetricas(
                primeiro: MetricCard(
                  titulo: 'Alunos ativos',
                  valor: '${alunos.length}',
                  subtitulo: '+2 este mês',
                  icone: Icons.group,
                ),
                segundo: MetricCard(
                  titulo: 'Risco de evasão',
                  valor: '${emRisco.length}',
                  subtitulo: 'precisam de atenção',
                  icone: Icons.warning_amber,
                  corIcone: context.brand.alerta,
                ),
              ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: MetricCard(
                  titulo: 'Frequência média',
                  valor: '${freqMedia.toStringAsFixed(1)}x',
                  subtitulo: 'por semana',
                  icone: Icons.event_repeat,
                ),
                segundo: MetricCard(
                  titulo: 'Treinos na semana',
                  valor:
                      '${MockDatabase.instance.treinosRealizadosSemana.reduce((a, b) => a + b)}',
                  subtitulo: 'realizados pelos alunos',
                  icone: Icons.fitness_center,
                ),
              ),
              const SectionTitle('Treinos realizados — últimos 7 dias'),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
                  child: SizedBox(
                    height: 180,
                    child: _BarrasSemana(
                      valores: MockDatabase.instance.treinosRealizadosSemana,
                    ),
                  ),
                ),
              ),
              SectionTitle(
                'Alunos em risco de evasão',
                trailing: TextButton(
                  onPressed: () => context.go('/personal/alunos'),
                  child: const Text('Ver todos'),
                ),
              ),
              for (final aluno in emRisco)
                Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: IniciaisAvatar(aluno.iniciais),
                    title: Text(aluno.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${aluno.frequenciaSemanal}x por semana · ${aluno.objetivo}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/personal/alunos/${aluno.id}'),
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

class _BarrasSemana extends StatelessWidget {
  const _BarrasSemana({required this.valores});

  final List<int> valores;

  static const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _dias[v.toInt() % 7],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (final (i, v) in valores.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v.toDouble(),
                  color: cor,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
