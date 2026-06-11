import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Perfil do aluno: dados, objetivo editável e registro rápido de peso.
class PerfilAlunoScreen extends ConsumerWidget {
  const PerfilAlunoScreen({super.key});

  static const _objetivos = [
    'Hipertrofia',
    'Emagrecimento',
    'Condicionamento',
    'Saúde e mobilidade',
    'Preparação para corrida',
  ];

  Future<void> _registrarPeso(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final peso = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar peso de hoje'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Peso',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
                double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (peso == null) {
      if (context.mounted && controller.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso inválido — use 70,5.')),
        );
      }
      return;
    }
    await ref.read(evolucaoRepositoryProvider).registrarPeso(
        alunoLogadoId, peso);
    ref.invalidate(pesosProvider(alunoLogadoId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Peso de ${peso.toStringAsFixed(1).replaceAll('.', ',')} kg registrado!')),
      );
    }
  }

  Future<void> _editarObjetivo(BuildContext context, WidgetRef ref) async {
    final aluno = ref.read(alunoProvider(alunoLogadoId)).valueOrNull;
    if (aluno == null) return;
    final escolhido = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Meu objetivo'),
        children: [
          for (final o in _objetivos)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(o),
              child: Row(
                children: [
                  Icon(
                    o == aluno.objetivo
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(o)),
                ],
              ),
            ),
        ],
      ),
    );
    if (escolhido == null || escolhido == aluno.objetivo) return;
    await ref
        .read(alunoRepositoryProvider)
        .atualizar(aluno.copyWith(objetivo: escolhido));
    ref.invalidate(alunoProvider(alunoLogadoId));
    ref.invalidate(alunosProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Objetivo atualizado para $escolhido!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    final alunoAsync = ref.watch(alunoProvider(alunoLogadoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: PaginaCentralizada(
        child: AsyncView(
          value: alunoAsync,
          builder: (aluno) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      IniciaisAvatar(aluno.iniciais, raio: 34),
                      const SizedBox(height: 12),
                      Text(aluno.nome,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      if (sessao != null)
                        Text(sessao.email,
                            style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Aluno desde ${DateFormat('MMMM/y').format(aluno.inicio)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ParDeMetricas(
                primeiro: MetricCard(
                  titulo: 'Peso atual',
                  valor: '${aluno.pesoAtualKg.toStringAsFixed(1)} kg',
                  icone: Icons.monitor_weight,
                ),
                segundo: MetricCard(
                  titulo: 'Frequência-alvo',
                  valor: '${aluno.frequenciaSemanal}x',
                  subtitulo: 'por semana',
                  icone: Icons.event_repeat,
                ),
              ),
              const SectionTitle('Meu objetivo'),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(aluno.objetivo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _editarObjetivo(context, ref),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _registrarPeso(context, ref),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: const Text('Registrar peso de hoje'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'O peso registrado alimenta o gráfico da aba Evolução.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
