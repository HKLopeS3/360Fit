import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculos/protocolos.dart';
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

  // --------------------------------------------------- protocolo de dobras
  String _protocolo = ''; // '' = % digitado
  static const _sitios = [
    'tricipital', 'subescapular', 'peitoral', 'axilar_media',
    'suprailiaca', 'abdominal', 'coxa', 'panturrilha', //
  ];
  static const _rotuloSitio = {
    'tricipital': 'Tricipital',
    'subescapular': 'Subescapular',
    'peitoral': 'Peitoral',
    'axilar_media': 'Axilar média',
    'suprailiaca': 'Suprailíaca',
    'abdominal': 'Abdominal',
    'coxa': 'Coxa',
    'panturrilha': 'Panturrilha',
  };
  final Map<String, TextEditingController> _dobras = {
    for (final s in _sitios) s: TextEditingController(),
  };

  // bioimpedância e testes
  final _agua = TextEditingController();
  final _visceral = TextEditingController();
  final _rmCarga = TextEditingController();
  final _rmReps = TextEditingController();
  final _cooper = TextEditingController();
  final _wells = TextEditingController();

  @override
  void dispose() {
    _peso.dispose();
    _gordura.dispose();
    _massaMagra.dispose();
    for (final c in _medidas.values) {
      c.dispose();
    }
    for (final c in _dobras.values) {
      c.dispose();
    }
    _agua.dispose();
    _visceral.dispose();
    _rmCarga.dispose();
    _rmReps.dispose();
    _cooper.dispose();
    _wells.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  /// Sítios exigidos pelo protocolo atual, conforme o sexo do aluno.
  List<String> _sitiosDoProtocolo(String sexo) {
    final masc = sexo != 'feminino';
    return switch (_protocolo) {
      'pollock3' => masc
          ? ['peitoral', 'abdominal', 'coxa']
          : ['tricipital', 'suprailiaca', 'coxa'],
      'pollock7' => [
          'tricipital', 'subescapular', 'peitoral', 'axilar_media',
          'suprailiaca', 'abdominal', 'coxa', //
        ],
      'petroski' => masc
          ? ['subescapular', 'tricipital', 'suprailiaca', 'panturrilha']
          : ['axilar_media', 'suprailiaca', 'coxa', 'panturrilha'],
      _ => const [],
    };
  }

  Dobras _dobrasInformadas() => Dobras(
        tricipital: _numero(_dobras['tricipital']!.text),
        subescapular: _numero(_dobras['subescapular']!.text),
        peitoral: _numero(_dobras['peitoral']!.text),
        axilarMedia: _numero(_dobras['axilar_media']!.text),
        suprailiaca: _numero(_dobras['suprailiaca']!.text),
        abdominal: _numero(_dobras['abdominal']!.text),
        coxa: _numero(_dobras['coxa']!.text),
        panturrilha: _numero(_dobras['panturrilha']!.text),
      );

  void _calcularGordura(Aluno aluno) {
    final sexo =
        aluno.sexo == 'feminino' ? Sexo.feminino : Sexo.masculino;
    final dobras = _dobrasInformadas();
    final faltando = _sitiosDoProtocolo(aluno.sexo)
        .where((s) => _numero(_dobras[s]!.text) == null)
        .toList();
    if (faltando.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Preencha as dobras: ${faltando.map((s) => _rotuloSitio[s]).join(', ')}'),
      ));
      return;
    }
    final densidade = switch (_protocolo) {
      'pollock3' =>
        densidadePollock3(sexo: sexo, idade: aluno.idade, dobras: dobras),
      'pollock7' =>
        densidadePollock7(sexo: sexo, idade: aluno.idade, dobras: dobras),
      _ =>
        densidadePetroski(sexo: sexo, idade: aluno.idade, dobras: dobras),
    };
    final pct = percentualGorduraSiri(densidade).clamp(2.0, 60.0);
    setState(() {
      _gordura.text = pct.toStringAsFixed(1).replaceAll('.', ',');
      final peso = _numero(_peso.text);
      if (peso != null) {
        _massaMagra.text =
            (peso * (1 - pct / 100)).toStringAsFixed(1).replaceAll('.', ',');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Gordura calculada (${_protocolo == 'pollock3' ? 'Pollock 3' : _protocolo == 'pollock7' ? 'Pollock 7' : 'Petroski'}): ${pct.toStringAsFixed(1)}%'),
    ));
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
      pro: AvaliacaoPro(
        protocolo: _protocolo,
        dobras: {
          for (final MapEntry(:key, :value) in _dobras.entries)
            if (_numero(value.text) != null) key: _numero(value.text)!,
        },
        bioimpedancia: {
          if (_numero(_agua.text) != null) 'agua_pct': _numero(_agua.text)!,
          if (_numero(_visceral.text) != null)
            'gordura_visceral': _numero(_visceral.text)!,
        },
        testes: {
          if (_numero(_rmCarga.text) != null &&
              _numero(_rmReps.text) != null)
            'um_rm_kg': umRmEpley(
                _numero(_rmCarga.text)!, _numero(_rmReps.text)!.toInt()),
          if (_numero(_cooper.text) != null) ...{
            'cooper_m': _numero(_cooper.text)!,
            'vo2': vo2Cooper(_numero(_cooper.text)!),
          },
          if (_numero(_wells.text) != null)
            'wells_cm': _numero(_wells.text)!,
        },
      ),
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

    final aluno = ref.watch(alunoProvider(widget.alunoId)).valueOrNull;

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
              const SectionTitle('Dobras cutâneas (protocolo)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (valor, rotulo) in const [
                    ('', 'Digitar %'),
                    ('pollock3', 'Pollock 3'),
                    ('pollock7', 'Pollock 7'),
                    ('petroski', 'Petroski'),
                  ])
                    ChoiceChip(
                      label: Text(rotulo),
                      selected: _protocolo == valor,
                      onSelected: (_) => setState(() => _protocolo = valor),
                    ),
                ],
              ),
              if (_protocolo.isNotEmpty && aluno != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Sexo: ${aluno.sexo} · ${aluno.idade} anos — dobras em mm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final sitio in _sitiosDoProtocolo(aluno.sexo))
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          controller: _dobras[sitio],
                          keyboardType: TextInputType.number,
                          decoration:
                              dec(_rotuloSitio[sitio]!, sufixo: 'mm'),
                          validator: _validaOpcional,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _calcularGordura(aluno),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calcular % de gordura'),
                ),
              ],
              const SectionTitle('Bioimpedância (opcional)'),
              ParDeMetricas(
                primeiro: TextFormField(
                  controller: _agua,
                  keyboardType: TextInputType.number,
                  decoration: dec('Água corporal', sufixo: '%'),
                  validator: _validaOpcional,
                ),
                segundo: TextFormField(
                  controller: _visceral,
                  keyboardType: TextInputType.number,
                  decoration: dec('Gordura visceral', sufixo: 'nível'),
                  validator: _validaOpcional,
                ),
              ),
              const SectionTitle('Testes (opcional)'),
              ParDeMetricas(
                primeiro: TextFormField(
                  controller: _rmCarga,
                  keyboardType: TextInputType.number,
                  decoration: dec('1RM: carga', sufixo: 'kg'),
                  validator: _validaOpcional,
                  onChanged: (_) => setState(() {}),
                ),
                segundo: TextFormField(
                  controller: _rmReps,
                  keyboardType: TextInputType.number,
                  decoration: dec('1RM: repetições'),
                  validator: _validaOpcional,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_numero(_rmCarga.text) != null &&
                  _numero(_rmReps.text) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '1RM estimado (Epley): '
                    '${umRmEpley(_numero(_rmCarga.text)!, _numero(_rmReps.text)!.toInt()).toStringAsFixed(1)} kg',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: TextFormField(
                  controller: _cooper,
                  keyboardType: TextInputType.number,
                  decoration: dec('Cooper 12min', sufixo: 'm'),
                  validator: _validaOpcional,
                  onChanged: (_) => setState(() {}),
                ),
                segundo: TextFormField(
                  controller: _wells,
                  keyboardType: TextInputType.number,
                  decoration: dec('Banco de Wells', sufixo: 'cm'),
                  validator: _validaOpcional,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (aluno != null &&
                  (_numero(_cooper.text) != null ||
                      _numero(_wells.text) != null))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Builder(builder: (context) {
                    final sexo = aluno.sexo == 'feminino'
                        ? Sexo.feminino
                        : Sexo.masculino;
                    final partes = <String>[
                      if (_numero(_cooper.text) != null)
                        'VO₂ ${vo2Cooper(_numero(_cooper.text)!).toStringAsFixed(1)} '
                            '(${classificacaoVo2(vo2Cooper(_numero(_cooper.text)!), sexo: sexo)})',
                      if (_numero(_wells.text) != null)
                        'Flexibilidade: ${classificacaoWells(_numero(_wells.text)!, sexo: sexo)}',
                    ];
                    return Text(
                      partes.join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    );
                  }),
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
