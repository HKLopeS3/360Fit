import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets.dart';
import 'conquistas_screen.dart';
import 'fotos_evolucao_screen.dart';
import 'historico_screen.dart';
import 'minha_avaliacao_screen.dart';

class EvolucaoScreen extends ConsumerWidget {
  const EvolucaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pesosAsync = ref.watch(pesosProvider(alunoLogadoId));
    final avaliacoesAsync = ref.watch(avaliacoesProvider(alunoLogadoId));
    final cargasSupino = ref.watch(
        cargasProvider((alunoId: alunoLogadoId, exercicioId: 'e1')));

    return TelaResponsiva(
      titulo: 'Minha evolução',
      actions: [
        IconButton(
          tooltip: 'Fotos de evolução',
          icon: const Icon(Icons.photo_library_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const FotosEvolucaoScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Minhas conquistas',
          icon: const Icon(Icons.emoji_events_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConquistasScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Histórico de treinos',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HistoricoScreen()),
          ),
        ),
        const LogoutButton(),
      ],
      body: PaginaCentralizada(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SectionTitle('Peso corporal (kg)'),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
              child: SizedBox(
                height: 220,
                child: AsyncView(
                  value: pesosAsync,
                  builder: (pesos) => _LinhaChart(
                    pontos: [
                      for (final (i, p) in pesos.indexed)
                        FlSpot(i.toDouble(), p.pesoKg),
                    ],
                    rotulos: [for (final p in pesos) fmtDiaMes.format(p.data)],
                    cor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SectionTitle('Carga no supino reto (kg)'),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
              child: SizedBox(
                height: 220,
                child: AsyncView(
                  value: cargasSupino,
                  builder: (cargas) => _LinhaChart(
                    pontos: [
                      for (final (i, c) in cargas.indexed)
                        FlSpot(i.toDouble(), c.cargaKg),
                    ],
                    rotulos: [for (final c in cargas) fmtDiaMes.format(c.data)],
                    cor: context.brand.primaria,
                  ),
                ),
              ),
            ),
          ),
          const SectionTitle('Avaliações físicas'),
          AsyncView(
            value: avaliacoesAsync,
            builder: (avaliacoes) {
              final nomeAluno = ref.read(sessaoProvider)?.nome ?? 'Aluno';
              final nomePersonal =
                  ref.read(personalDoAlunoProvider).valueOrNull?.nome ??
                      'Personal';
              return Column(
                children: [
                  for (final a in avaliacoes.reversed)
                    _AvaliacaoCard(
                      avaliacao: a,
                      nomeAluno: nomeAluno,
                      nomePersonal: nomePersonal,
                    ),
                ],
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}

class _LinhaChart extends StatelessWidget {
  const _LinhaChart({
    required this.pontos,
    required this.rotulos,
    required this.cor,
  });

  final List<FlSpot> pontos;
  final List<String> rotulos;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) {
      return const Center(child: Text('Sem registros ainda.'));
    }
    final ys = pontos.map((p) => p.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final margem = ((maxY - minY) * 0.2).clamp(1.0, 50.0);

    return LineChart(
      LineChartData(
        minY: minY - margem,
        maxY: maxY + margem,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(0),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (pontos.length / 4).ceilToDouble().clamp(1, 100),
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rotulos.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    rotulos[i],
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            isCurved: true,
            color: cor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: cor.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvaliacaoCard extends StatelessWidget {
  const _AvaliacaoCard({
    required this.avaliacao,
    required this.nomeAluno,
    required this.nomePersonal,
  });

  final AvaliacaoFisica avaliacao;
  final String nomeAluno;
  final String nomePersonal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;

    Widget metrica(String rotulo, String valor, Color cor) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(valor,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: cor)),
                const SizedBox(height: 2),
                Text(rotulo,
                    style: const TextStyle(
                        fontSize: 11, color: kTextSecondary)),
              ],
            ),
          ),
        );

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 15,
                  color: kTextSecondary),
              const SizedBox(width: 6),
              Text(
                'Avaliação de ${fmtDiaMes.format(avaliacao.data)}/${avaliacao.data.year}',
                style: const TextStyle(
                    fontSize: 12, color: kTextSecondary,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MinhaAvaliacaoScreen(
                      avaliacao: avaliacao,
                      nomeAluno: nomeAluno,
                      nomePersonal: nomePersonal,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: brand.primaria,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver completo', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              metrica('Peso',
                  '${avaliacao.pesoKg.toStringAsFixed(1)} kg',
                  brand.primaria),
              const SizedBox(width: 8),
              metrica(
                  'Gordura',
                  '${avaliacao.gorduraPct.toStringAsFixed(1)}%',
                  avaliacao.gorduraPct < 20
                      ? const Color(0xFF22C55E)
                      : avaliacao.gorduraPct < 28
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              metrica(
                  'Massa magra',
                  '${avaliacao.massaMagraKg.toStringAsFixed(1)} kg',
                  const Color(0xFF06B6D4)),
            ],
          ),
          if (avaliacao.medidas.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final e in avaliacao.medidas.entries.take(6))
                  Text(
                    '${e.key}: ${e.value.toStringAsFixed(0)}cm',
                    style: const TextStyle(
                        fontSize: 11, color: kTextSecondary),
                  ),
                if (avaliacao.medidas.length > 6)
                  Text(
                    '+ ${avaliacao.medidas.length - 6} medidas',
                    style: TextStyle(
                        fontSize: 11,
                        color: brand.primaria,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
