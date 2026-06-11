import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Anamnese digital: PAR-Q + histórico de saúde.
class AnamneseScreen extends ConsumerStatefulWidget {
  const AnamneseScreen({
    super.key,
    required this.alunoId,
    required this.nomeAluno,
  });

  final String alunoId;
  final String nomeAluno;

  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen> {
  static const _perguntasParq = [
    'Algum médico já disse que você possui problema cardíaco e recomendou '
        'atividade física apenas sob supervisão médica?',
    'Sente dor no peito ao praticar atividade física?',
    'No último mês, sentiu dor no peito em repouso?',
    'Já perdeu o equilíbrio por tontura ou perdeu a consciência?',
    'Possui problema ósseo ou articular que poderia piorar com a '
        'atividade física?',
    'Toma atualmente algum medicamento para pressão arterial ou coração?',
    'Conhece alguma outra razão pela qual não deveria praticar '
        'atividade física?',
  ];

  final List<bool> _parq = List.filled(7, false);
  final _lesoes = TextEditingController();
  final _cirurgias = TextEditingController();
  final _medicamentos = TextEditingController();
  final _habitos = TextEditingController();
  int _horasSono = 7;
  bool _salvando = false;
  bool _carregouExistente = false;

  @override
  void dispose() {
    _lesoes.dispose();
    _cirurgias.dispose();
    _medicamentos.dispose();
    _habitos.dispose();
    super.dispose();
  }

  void _preencherCom(Anamnese a) {
    if (_carregouExistente) return;
    _carregouExistente = true;
    for (var i = 0; i < a.parq.length && i < 7; i++) {
      _parq[i] = a.parq[i];
    }
    _lesoes.text = a.lesoes;
    _cirurgias.text = a.cirurgias;
    _medicamentos.text = a.medicamentos;
    _habitos.text = a.habitos;
    _horasSono = a.horasSono;
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await ref.read(evolucaoRepositoryProvider).salvarAnamnese(Anamnese(
          alunoId: widget.alunoId,
          data: DateTime.now(),
          parq: List.of(_parq),
          lesoes: _lesoes.text.trim(),
          cirurgias: _cirurgias.text.trim(),
          medicamentos: _medicamentos.text.trim(),
          horasSono: _horasSono,
          habitos: _habitos.text.trim(),
        ));
    ref.invalidate(anamneseProvider(widget.alunoId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Anamnese de ${widget.nomeAluno} salva!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen(anamneseProvider(widget.alunoId), (anterior, atual) {
      final a = atual.valueOrNull;
      if (a != null) setState(() => _preencherCom(a));
    });
    final exigeLiberacao = _parq.any((r) => r);

    InputDecoration dec(String rotulo) => InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Anamnese — ${widget.nomeAluno}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PaginaCentralizada(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle('Questionário PAR-Q'),
            if (exigeLiberacao)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Há resposta positiva no PAR-Q: solicite '
                          'liberação médica antes de iniciar os treinos.',
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            for (final (i, pergunta) in _perguntasParq.indexed)
              Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  title: Text('${i + 1}. $pergunta',
                      style: theme.textTheme.bodyMedium),
                  value: _parq[i],
                  activeTrackColor: theme.colorScheme.error,
                  onChanged: (v) => setState(() => _parq[i] = v),
                ),
              ),
            const SectionTitle('Histórico de saúde'),
            TextField(controller: _lesoes, decoration: dec('Lesões prévias')),
            const SizedBox(height: 12),
            TextField(
                controller: _cirurgias, decoration: dec('Cirurgias')),
            const SizedBox(height: 12),
            TextField(
                controller: _medicamentos,
                decoration: dec('Medicamentos em uso')),
            const SectionTitle('Rotina'),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Text('Horas de sono por noite')),
                    IconButton(
                      onPressed: _horasSono > 3
                          ? () => setState(() => _horasSono--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_horasSono h',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: _horasSono < 12
                          ? () => setState(() => _horasSono++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _habitos,
              maxLines: 3,
              decoration:
                  dec('Hábitos (alimentação, álcool, tabaco, estresse…)'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Salvar anamnese'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
