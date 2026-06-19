import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';

/// Tela de celebração exibida ao concluir um treino.
class ResultadoTreinoScreen extends StatelessWidget {
  const ResultadoTreinoScreen({super.key, required this.conclusao});

  final TreinoConcluido conclusao;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pse = conclusao.pse;
    final (pseLabel, pseColor) = switch (pse) {
      <= 3 => ('Leve', Colors.green),
      <= 6 => ('Moderado', Colors.orange),
      _ => ('Intenso', Colors.red),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: brand.gradientePrimario,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Ícone de conquista
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 3),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 60,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Treino concluído!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conclusao.nomeTreino,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Métricas
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metrica(
                            icone: Icons.timer_outlined,
                            valor: '${conclusao.duracaoMin}',
                            unidade: 'min',
                            rotulo: 'Duração',
                          ),
                          _Divisor(),
                          _Metrica(
                            icone: Icons.repeat_rounded,
                            valor: '${conclusao.series.length}',
                            unidade: 'séries',
                            rotulo: 'Completadas',
                          ),
                          _Divisor(),
                          _Metrica(
                            icone: Icons.fitness_center_rounded,
                            valor: conclusao.volumeTotalKg
                                .toStringAsFixed(0),
                            unidade: 'kg',
                            rotulo: 'Volume total',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PSE e dor
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed_outlined,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              const Text('Esforço percebido',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pseColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          pseColor.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  '$pse/10 — $pseLabel',
                                  style: TextStyle(
                                    color: pseColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (conclusao.dorArticular) ...[
                            const Divider(color: Colors.white24, height: 20),
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Colors.orangeAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    conclusao.dorRelato.isEmpty
                                        ? 'Dor articular relatada'
                                        : conclusao.dorRelato,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Mensagem motivacional
                    Text(
                      _mensagem(conclusao),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Botão voltar
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brand.primaria,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => context.go('/aluno/hoje'),
                        child: const Text('Ir para o início'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.white70),
                      onPressed: () => context.go('/aluno/evolucao'),
                      child: const Text('Ver minha evolução'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _mensagem(TreinoConcluido c) {
    if (c.series.length >= c.series.length && c.pse <= 4) {
      return '"Consistência é o segredo do progresso. Continue assim!"';
    }
    if (c.pse >= 8) {
      return '"Você foi além dos seus limites hoje. Recuperação é parte do treino!"';
    }
    return '"Cada treino concluído é um passo rumo à sua melhor versão!"';
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icone,
    required this.valor,
    required this.unidade,
    required this.rotulo,
  });

  final IconData icone;
  final String valor;
  final String unidade;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icone, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' $unidade',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white24,
    );
  }
}
