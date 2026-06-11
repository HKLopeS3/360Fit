import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Comparação lado a lado entre duas avaliações físicas do aluno.
class ComparativoScreen extends ConsumerStatefulWidget {
  const ComparativoScreen({
    super.key,
    required this.alunoId,
    required this.nomeAluno,
  });

  final String alunoId;
  final String nomeAluno;

  @override
  ConsumerState<ComparativoScreen> createState() => _ComparativoScreenState();
}

class _ComparativoScreenState extends ConsumerState<ComparativoScreen> {
  int? _indiceA;
  int? _indiceB;

  @override
  Widget build(BuildContext context) {
    final avaliacoesAsync = ref.watch(avaliacoesProvider(widget.alunoId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Evolução — ${widget.nomeAluno}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PaginaCentralizada(
        child: AsyncView(
          value: avaliacoesAsync,
          builder: (avaliacoes) {
            if (avaliacoes.length < 2) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'São necessárias pelo menos 2 avaliações para comparar. '
                    'Registre uma nova avaliação primeiro.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final a = avaliacoes[_indiceA ?? 0];
            final b = avaliacoes[_indiceB ?? avaliacoes.length - 1];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SeletorAvaliacao(
                        rotulo: 'De',
                        avaliacoes: avaliacoes,
                        indice: _indiceA ?? 0,
                        aoMudar: (i) => setState(() => _indiceA = i),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward),
                    ),
                    Expanded(
                      child: _SeletorAvaliacao(
                        rotulo: 'Até',
                        avaliacoes: avaliacoes,
                        indice: _indiceB ?? avaliacoes.length - 1,
                        aoMudar: (i) => setState(() => _indiceB = i),
                      ),
                    ),
                  ],
                ),
                const SectionTitle('Comparativo'),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        _LinhaDelta(
                          rotulo: 'Peso',
                          de: a.pesoKg,
                          ate: b.pesoKg,
                          unidade: 'kg',
                          melhoraQuandoCai: null, // depende do objetivo
                        ),
                        _LinhaDelta(
                          rotulo: 'Gordura corporal',
                          de: a.gorduraPct,
                          ate: b.gorduraPct,
                          unidade: '%',
                          melhoraQuandoCai: true,
                        ),
                        _LinhaDelta(
                          rotulo: 'Massa magra',
                          de: a.massaMagraKg,
                          ate: b.massaMagraKg,
                          unidade: 'kg',
                          melhoraQuandoCai: false,
                        ),
                        for (final chave in {
                          ...a.medidas.keys,
                          ...b.medidas.keys,
                        })
                          if (a.medidas[chave] != null &&
                              b.medidas[chave] != null)
                            _LinhaDelta(
                              rotulo: chave,
                              de: a.medidas[chave]!,
                              ate: b.medidas[chave]!,
                              unidade: 'cm',
                              melhoraQuandoCai: null,
                            ),
                      ],
                    ),
                  ),
                ),
                if (b.observacoes.isNotEmpty) ...[
                  const SectionTitle('Observações da última avaliação'),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(b.observacoes),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeletorAvaliacao extends StatelessWidget {
  const _SeletorAvaliacao({
    required this.rotulo,
    required this.avaliacoes,
    required this.indice,
    required this.aoMudar,
  });

  final String rotulo;
  final List<AvaliacaoFisica> avaliacoes;
  final int indice;
  final ValueChanged<int> aoMudar;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: indice,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: rotulo,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final (i, a) in avaliacoes.indexed)
          DropdownMenuItem(
            value: i,
            child: Text(
                '${fmtDiaMes.format(a.data)}/${a.data.year % 100}'),
          ),
      ],
      onChanged: (i) {
        if (i != null) aoMudar(i);
      },
    );
  }
}

class _LinhaDelta extends StatelessWidget {
  const _LinhaDelta({
    required this.rotulo,
    required this.de,
    required this.ate,
    required this.unidade,
    required this.melhoraQuandoCai,
  });

  final String rotulo;
  final double de;
  final double ate;
  final String unidade;

  /// true = queda é melhora (gordura); false = alta é melhora (massa magra);
  /// null = neutro (peso, medidas — depende do objetivo).
  final bool? melhoraQuandoCai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    final delta = ate - de;
    final estavel = delta.abs() < 0.05;

    Color cor;
    if (estavel || melhoraQuandoCai == null) {
      cor = theme.colorScheme.onSurfaceVariant;
    } else {
      final melhorou = melhoraQuandoCai! ? delta < 0 : delta > 0;
      cor = melhorou ? brand.sucesso : theme.colorScheme.error;
    }
    final seta = estavel
        ? '—'
        : delta > 0
            ? '▲'
            : '▼';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(rotulo,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Text('${de.toStringAsFixed(1)} $unidade',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Text('${ate.toStringAsFixed(1)} $unidade',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$seta ${delta.abs().toStringAsFixed(1)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w700, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}
