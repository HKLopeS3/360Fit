import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Cadastro/edição de aluno pelo personal.
class FormAlunoScreen extends ConsumerStatefulWidget {
  const FormAlunoScreen({super.key, this.aluno});

  /// Quando informado, edita; quando nulo, cria.
  final Aluno? aluno;

  @override
  ConsumerState<FormAlunoScreen> createState() => _FormAlunoScreenState();
}

class _FormAlunoScreenState extends ConsumerState<FormAlunoScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.aluno?.nome ?? '');
  late final _idade =
      TextEditingController(text: widget.aluno?.idade.toString() ?? '');
  late final _peso = TextEditingController(
      text: widget.aluno == null
          ? ''
          : widget.aluno!.pesoAtualKg.toStringAsFixed(1).replaceAll('.', ','));
  late String _objetivo = widget.aluno?.objetivo ?? 'Hipertrofia';
  late String _sexo = widget.aluno?.sexo ?? 'masculino';
  late int _frequencia = widget.aluno?.frequenciaSemanal ?? 3;
  late bool _riscoEvasao = widget.aluno?.riscoEvasao ?? false;
  bool _salvando = false;

  static const _objetivos = [
    'Hipertrofia',
    'Emagrecimento',
    'Condicionamento',
    'Saúde e mobilidade',
    'Preparação para corrida',
  ];

  @override
  void dispose() {
    _nome.dispose();
    _idade.dispose();
    _peso.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    final peso =
        double.tryParse(_peso.text.trim().replaceAll(',', '.')) ?? 0;
    final idade = int.tryParse(_idade.text.trim()) ?? 0;
    final repo = ref.read(alunoRepositoryProvider);

    if (widget.aluno == null) {
      await repo.criar(Aluno(
        id: 'a-${DateTime.now().millisecondsSinceEpoch}',
        nome: _nome.text.trim(),
        idade: idade,
        objetivo: _objetivo,
        inicio: DateTime.now(),
        frequenciaSemanal: _frequencia,
        pesoAtualKg: peso,
        riscoEvasao: _riscoEvasao,
        sexo: _sexo,
      ));
    } else {
      await repo.atualizar(widget.aluno!.copyWith(
        nome: _nome.text.trim(),
        idade: idade,
        objetivo: _objetivo,
        frequenciaSemanal: _frequencia,
        pesoAtualKg: peso,
        riscoEvasao: _riscoEvasao,
        sexo: _sexo,
      ));
      ref.invalidate(alunoProvider(widget.aluno!.id));
    }
    ref.invalidate(alunosProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.aluno == null
            ? 'Aluno ${_nome.text.trim()} cadastrado!'
            : 'Dados de ${_nome.text.trim()} atualizados!'),
      ),
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
        title: Text(widget.aluno == null ? 'Novo aluno' : 'Editar aluno'),
      ),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextFormField(
                controller: _nome,
                decoration: dec('Nome completo *'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe o nome do aluno'
                    : null,
              ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: TextFormField(
                  controller: _idade,
                  keyboardType: TextInputType.number,
                  decoration: dec('Idade', sufixo: 'anos'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 10 || n > 110) {
                      return 'Idade inválida';
                    }
                    return null;
                  },
                ),
                segundo: TextFormField(
                  controller: _peso,
                  keyboardType: TextInputType.number,
                  decoration: dec('Peso atual', sufixo: 'kg'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return double.tryParse(v.trim().replaceAll(',', '.')) ==
                            null
                        ? 'Número inválido'
                        : null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sexo,
                isExpanded: true,
                decoration: dec('Sexo (para protocolos de avaliação)'),
                items: const [
                  DropdownMenuItem(
                      value: 'masculino', child: Text('Masculino')),
                  DropdownMenuItem(
                      value: 'feminino', child: Text('Feminino')),
                ],
                onChanged: (v) => setState(() => _sexo = v ?? _sexo),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _objetivo,
                isExpanded: true,
                decoration: dec('Objetivo'),
                items: [
                  for (final o in _objetivos)
                    DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (v) => setState(() => _objetivo = v ?? _objetivo),
              ),
              const SectionTitle('Frequência-alvo por semana'),
              Wrap(
                spacing: 8,
                children: [
                  for (var f = 1; f <= 7; f++)
                    ChoiceChip(
                      label: Text('${f}x'),
                      selected: _frequencia == f,
                      onSelected: (_) => setState(() => _frequencia = f),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: SwitchListTile(
                  title: const Text('Risco de evasão'),
                  subtitle: const Text(
                      'Marque para acompanhar de perto este aluno'),
                  value: _riscoEvasao,
                  onChanged: (v) => setState(() => _riscoEvasao = v),
                ),
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
                label: Text(widget.aluno == null
                    ? 'Cadastrar aluno'
                    : 'Salvar alterações'),
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
