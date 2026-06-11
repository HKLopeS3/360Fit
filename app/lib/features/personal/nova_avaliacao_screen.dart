import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Formulário de nova avaliação física de um aluno.
class NovaAvaliacaoScreen extends ConsumerStatefulWidget {
  const NovaAvaliacaoScreen({
    super.key,
    required this.alunoId,
    required this.nomeAluno,
  });

  final String alunoId;
  final String nomeAluno;

  @override
  ConsumerState<NovaAvaliacaoScreen> createState() =>
      _NovaAvaliacaoScreenState();
}

class _NovaAvaliacaoScreenState extends ConsumerState<NovaAvaliacaoScreen> {
  final _form = GlobalKey<FormState>();
  final _peso = TextEditingController();
  final _gordura = TextEditingController();
  final _massaMagra = TextEditingController();
  final _medidas = {
    'Braço': TextEditingController(),
    'Cintura': TextEditingController(),
    'Quadril': TextEditingController(),
    'Coxa': TextEditingController(),
  };
  final _observacoes = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _peso.dispose();
    _gordura.dispose();
    _massaMagra.dispose();
    for (final c in _medidas.values) {
      c.dispose();
    }
    _observacoes.dispose();
    super.dispose();
  }

  double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  String? _validaObrigatorio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe um valor';
    if (_numero(v) == null) return 'Número inválido (use 70,5)';
    return null;
  }

  String? _validaOpcional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (_numero(v) == null) return 'Número inválido';
    return null;
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    final avaliacao = AvaliacaoFisica(
      data: DateTime.now(),
      pesoKg: _numero(_peso.text)!,
      gorduraPct: _numero(_gordura.text) ?? 0,
      massaMagraKg: _numero(_massaMagra.text) ?? 0,
      medidas: {
        for (final MapEntry(:key, :value) in _medidas.entries)
          if (_numero(value.text) != null) key: _numero(value.text)!,
      },
      observacoes: _observacoes.text.trim(),
    );
    await ref
        .read(evolucaoRepositoryProvider)
        .salvarAvaliacao(widget.alunoId, avaliacao);
    ref.invalidate(avaliacoesProvider(widget.alunoId));
    ref.invalidate(pesosProvider(widget.alunoId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Avaliação de ${widget.nomeAluno} salva!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String rotulo, {String? sufixo}) => InputDecoration(
          labelText: rotulo,
          suffixText: sufixo,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Nova avaliação — ${widget.nomeAluno}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SectionTitle('Composição corporal'),
              TextFormField(
                controller: _peso,
                keyboardType: TextInputType.number,
                decoration: dec('Peso *', sufixo: 'kg'),
                validator: _validaObrigatorio,
              ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: TextFormField(
                  controller: _gordura,
                  keyboardType: TextInputType.number,
                  decoration: dec('Gordura', sufixo: '%'),
                  validator: _validaOpcional,
                ),
                segundo: TextFormField(
                  controller: _massaMagra,
                  keyboardType: TextInputType.number,
                  decoration: dec('Massa magra', sufixo: 'kg'),
                  validator: _validaOpcional,
                ),
              ),
              const SectionTitle('Medidas (cm)'),
              for (final medidas in [
                ['Braço', 'Cintura'],
                ['Quadril', 'Coxa'],
              ]) ...[
                ParDeMetricas(
                  primeiro: TextFormField(
                    controller: _medidas[medidas[0]],
                    keyboardType: TextInputType.number,
                    decoration: dec(medidas[0], sufixo: 'cm'),
                    validator: _validaOpcional,
                  ),
                  segundo: TextFormField(
                    controller: _medidas[medidas[1]],
                    keyboardType: TextInputType.number,
                    decoration: dec(medidas[1], sufixo: 'cm'),
                    validator: _validaOpcional,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SectionTitle('Observações'),
              TextFormField(
                controller: _observacoes,
                maxLines: 3,
                decoration: dec('Postura, restrições, metas…'),
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
                label: const Text('Salvar avaliação'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
