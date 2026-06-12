import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Criação de agendamento pelo personal.
class NovoAgendamentoScreen extends ConsumerStatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  ConsumerState<NovoAgendamentoScreen> createState() =>
      _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState
    extends ConsumerState<NovoAgendamentoScreen> {
  String? _alunoId;
  TipoAgendamento _tipo = TipoAgendamento.treino;
  DateTime _data = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _hora = const TimeOfDay(hour: 18, minute: 0);
  final _local =
      TextEditingController(text: 'Academia Alpha — Unidade Centro');
  bool _salvando = false;

  static const _titulos = {
    TipoAgendamento.treino: 'Treino acompanhado',
    TipoAgendamento.avaliacao: 'Avaliação física',
    TipoAgendamento.consulta: 'Conversa de acompanhamento',
  };

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _escolherHora() async {
    final escolhida =
        await showTimePicker(context: context, initialTime: _hora);
    if (escolhida != null) setState(() => _hora = escolhida);
  }

  Future<void> _salvar() async {
    if (_alunoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o aluno.')),
      );
      return;
    }
    setState(() => _salvando = true);
    await ref.read(agendaRepositoryProvider).criar(
          Agendamento(
            id: 'ag-${DateTime.now().millisecondsSinceEpoch}',
            alunoId: _alunoId!,
            titulo: _titulos[_tipo]!,
            tipo: _tipo,
            dataHora: DateTime(
                _data.year, _data.month, _data.day, _hora.hour, _hora.minute),
            local: _local.text.trim(),
          ),
        );
    ref.invalidate(agendaProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agendamento criado!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);

    InputDecoration dec(String rotulo) => InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: AsyncView(
          value: alunosAsync,
          builder: (alunos) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              DropdownButtonFormField<String>(
                value: _alunoId,
                isExpanded: true,
                decoration: dec('Aluno *'),
                items: [
                  for (final a in alunos)
                    DropdownMenuItem(value: a.id, child: Text(a.nome)),
                ],
                onChanged: (v) => setState(() => _alunoId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoAgendamento>(
                initialValue: _tipo,
                isExpanded: true,
                decoration: dec('Tipo'),
                items: [
                  for (final t in TipoAgendamento.values)
                    DropdownMenuItem(value: t, child: Text(_titulos[t]!)),
                ],
                onChanged: (v) =>
                    setState(() => _tipo = v ?? TipoAgendamento.treino),
              ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: OutlinedButton.icon(
                  onPressed: _escolherData,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(DateFormat('dd/MM/y').format(_data)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                  ),
                ),
                segundo: OutlinedButton.icon(
                  onPressed: _escolherHora,
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(
                      '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _local, decoration: dec('Local')),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.event_available),
                label: const Text('Criar agendamento'),
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
