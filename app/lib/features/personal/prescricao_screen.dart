import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

const _nomesDias = {
  DateTime.monday: 'Seg',
  DateTime.tuesday: 'Ter',
  DateTime.wednesday: 'Qua',
  DateTime.thursday: 'Qui',
  DateTime.friday: 'Sex',
  DateTime.saturday: 'Sáb',
  DateTime.sunday: 'Dom',
};

/// Montagem/edição de treino de um aluno a partir da biblioteca de exercícios.
class PrescricaoScreen extends ConsumerStatefulWidget {
  const PrescricaoScreen({super.key});

  @override
  ConsumerState<PrescricaoScreen> createState() => _PrescricaoScreenState();
}

class _PrescricaoScreenState extends ConsumerState<PrescricaoScreen> {
  String? _alunoId;
  Treino? _treino;
  bool _salvando = false;

  void _selecionarTreino(Treino treino) => setState(() => _treino = treino);

  void _novoTreino(String alunoId, int quantidadeExistente) {
    final letra = String.fromCharCode('A'.codeUnitAt(0) + quantidadeExistente);
    setState(() {
      _treino = Treino(
        id: 't-novo-${DateTime.now().millisecondsSinceEpoch}',
        alunoId: alunoId,
        nome: 'Treino $letra',
        foco: 'Novo treino',
        diasSemana: const [DateTime.monday],
        itens: const [],
      );
    });
  }

  Future<void> _adicionarExercicio() async {
    final exercicio = await showModalBottomSheet<Exercicio>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SeletorExercicio(),
    );
    if (exercicio == null || _treino == null) return;
    setState(() {
      _treino = _treino!.copyWith(itens: [
        ..._treino!.itens,
        ItemTreino(
          exercicioId: exercicio.id,
          series: 3,
          repeticoes: '10-12',
          cargaKg: 0,
        ),
      ]);
    });
  }

  Future<void> _editarItem(int indice) async {
    final item = _treino!.itens[indice];
    final editado = await showDialog<ItemTreino>(
      context: context,
      builder: (_) => _EditarItemDialog(item: item),
    );
    if (editado == null) return;
    final itens = List.of(_treino!.itens);
    itens[indice] = editado;
    setState(() => _treino = _treino!.copyWith(itens: itens));
  }

  void _removerItem(int indice) {
    final itens = List.of(_treino!.itens)..removeAt(indice);
    setState(() => _treino = _treino!.copyWith(itens: itens));
  }

  Future<void> _editarTreino() async {
    final editado = await showDialog<Treino>(
      context: context,
      builder: (_) => _EditarTreinoDialog(treino: _treino!),
    );
    if (editado == null) return;
    setState(() => _treino = editado);
  }

  Future<void> _salvar() async {
    if (_treino == null) return;
    setState(() => _salvando = true);
    await ref.read(treinoRepositoryProvider).salvar(_treino!);
    ref.invalidate(treinosDoAlunoProvider(_treino!.alunoId));
    ref.invalidate(treinoDoDiaProvider);
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_treino!.nome} salvo com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescrição de treino'),
        actions: const [LogoutButton()],
      ),
      floatingActionButton: _treino == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _adicionarExercicio,
              icon: const Icon(Icons.add),
              label: const Text('Exercício'),
            ),
      body: PaginaCentralizada(
        child: AsyncView(
        value: alunosAsync,
        builder: (alunos) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            DropdownButtonFormField<String>(
              value: _alunoId,
              decoration: InputDecoration(
                labelText: 'Aluno',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                for (final a in alunos)
                  DropdownMenuItem(value: a.id, child: Text(a.nome)),
              ],
              onChanged: (id) => setState(() {
                _alunoId = id;
                _treino = null;
              }),
            ),
            if (_alunoId != null) ...[
              const SectionTitle('Treinos do aluno'),
              _ListaTreinos(
                alunoId: _alunoId!,
                selecionadoId: _treino?.id,
                aoSelecionar: _selecionarTreino,
                aoCriarNovo: (qtd) => _novoTreino(_alunoId!, qtd),
              ),
            ],
            if (_treino != null) ...[
              SectionTitle(
                'Exercícios — ${_treino!.nome}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Editar nome, subtítulo e dias',
                      onPressed: _editarTreino,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _salvando || _treino!.itens.isEmpty
                          ? null
                          : _salvar,
                      icon: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_treino!.foco} · ${_treino!.diasSemana.map((d) => _nomesDias[d]).join(', ')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (_treino!.itens.isEmpty)
                const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'Treino vazio. Toque em "Exercício" para adicionar da biblioteca.'),
                  ),
                ),
              for (final (i, item) in _treino!.itens.indexed)
                _ItemPrescricaoTile(
                  item: item,
                  aoEditar: () => _editarItem(i),
                  aoRemover: () => _removerItem(i),
                ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _ListaTreinos extends ConsumerWidget {
  const _ListaTreinos({
    required this.alunoId,
    required this.selecionadoId,
    required this.aoSelecionar,
    required this.aoCriarNovo,
  });

  final String alunoId;
  final String? selecionadoId;
  final void Function(Treino) aoSelecionar;
  final void Function(int quantidadeExistente) aoCriarNovo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treinosAsync = ref.watch(treinosDoAlunoProvider(alunoId));
    return AsyncView(
      value: treinosAsync,
      builder: (treinos) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in treinos)
            ChoiceChip(
              label: Text('${t.nome} · ${t.foco}'),
              selected: t.id == selecionadoId,
              onSelected: (_) => aoSelecionar(t),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Novo treino'),
            onPressed: () => aoCriarNovo(treinos.length),
          ),
        ],
      ),
    );
  }
}

class _ItemPrescricaoTile extends ConsumerWidget {
  const _ItemPrescricaoTile({
    required this.item,
    required this.aoEditar,
    required this.aoRemover,
  });

  final ItemTreino item;
  final VoidCallback aoEditar;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercicio =
        ref.read(exercicioRepositoryProvider).porId(item.exercicioId);
    final carga =
        item.cargaKg > 0 ? ' · ${item.cargaKg.toStringAsFixed(0)} kg' : '';
    final extras = [
      if (item.cadencia.isNotEmpty) 'cad. ${item.cadencia}',
      if (item.metodo != MetodoTreino.normal)
        '${item.metodo.rotulo}${item.agrupamento > 0 ? ' #${item.agrupamento}' : ''}',
    ].join(' · ');
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(exercicio.nome,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${item.series}x ${item.repeticoes}$carga${extras.isEmpty ? '' : '\n$extras'}'),
        isThreeLine: extras.isNotEmpty,
        onTap: aoEditar,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar séries/carga',
              icon: const Icon(Icons.tune),
              onPressed: aoEditar,
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline),
              onPressed: aoRemover,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeletorExercicio extends ConsumerStatefulWidget {
  const _SeletorExercicio();

  @override
  ConsumerState<_SeletorExercicio> createState() => _SeletorExercicioState();
}

class _SeletorExercicioState extends ConsumerState<_SeletorExercicio> {
  String _busca = '';
  String? _grupo;

  Future<void> _editarVideo(Exercicio e) async {
    final controller = TextEditingController(text: e.videoUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vídeo — ${e.nome}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'URL do vídeo (YouTube ou link direto)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (url == null) return;
    await ref.read(exercicioRepositoryProvider).definirVideo(e.id, url);
    ref.invalidate(bibliotecaExerciciosProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(url.isEmpty
                ? 'Vídeo removido.'
                : 'Vídeo salvo para ${e.nome}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bibliotecaAsync = ref.watch(bibliotecaExerciciosProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scrollController) => AsyncView(
        value: bibliotecaAsync,
        builder: (biblioteca) {
          final grupos =
              biblioteca.map((e) => e.grupoMuscular).toSet().toList()..sort();
          final filtrados = biblioteca
              .where((e) => _grupo == null || e.grupoMuscular == _grupo)
              .where((e) =>
                  e.nome.toLowerCase().contains(_busca.trim().toLowerCase()))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _busca = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar exercício…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todos'),
                        selected: _grupo == null,
                        onSelected: (_) => setState(() => _grupo = null),
                      ),
                    ),
                    for (final g in grupos)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: _grupo == g,
                          onSelected: (_) => setState(() => _grupo = g),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final e = filtrados[i];
                    return ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(e.nome),
                      subtitle: Text('${e.grupoMuscular} · ${e.equipamento}'),
                      trailing: IconButton(
                        tooltip: e.videoUrl.isEmpty
                            ? 'Adicionar vídeo demonstrativo'
                            : 'Vídeo cadastrado — editar',
                        icon: Icon(
                          e.videoUrl.isEmpty
                              ? Icons.video_call_outlined
                              : Icons.play_circle_fill,
                          color: e.videoUrl.isEmpty
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => _editarVideo(e),
                      ),
                      onTap: () => Navigator.of(context).pop(e),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditarItemDialog extends StatefulWidget {
  const _EditarItemDialog({required this.item});

  final ItemTreino item;

  @override
  State<_EditarItemDialog> createState() => _EditarItemDialogState();
}

class _EditarItemDialogState extends State<_EditarItemDialog> {
  late int _series = widget.item.series;
  late final TextEditingController _repeticoes =
      TextEditingController(text: widget.item.repeticoes);
  late final TextEditingController _carga =
      TextEditingController(text: widget.item.cargaKg.toStringAsFixed(0));
  late final TextEditingController _cadencia =
      TextEditingController(text: widget.item.cadencia);
  late MetodoTreino _metodo = widget.item.metodo;
  late int _agrupamento = widget.item.agrupamento;

  @override
  void dispose() {
    _repeticoes.dispose();
    _carga.dispose();
    _cadencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar exercício'),
      // scrollável para caber em alturas pequenas (teclado aberto, janelas baixas)
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Séries'),
              Row(
                children: [
                  IconButton(
                    onPressed: _series > 1
                        ? () => setState(() => _series--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_series',
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    onPressed: () => setState(() => _series++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          TextField(
            controller: _repeticoes,
            decoration: const InputDecoration(
                labelText: 'Repetições (ex.: 8-12, 15, 45s)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _carga,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Carga (kg)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cadencia,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cadência (ex.: 4010)',
              helperText: 'excêntrica · pausa · concêntrica · pausa',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MetodoTreino>(
            value: _metodo,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Método'),
            items: [
              for (final m in MetodoTreino.values)
                DropdownMenuItem(value: m, child: Text(m.rotulo)),
            ],
            onChanged: (m) =>
                setState(() => _metodo = m ?? MetodoTreino.normal),
          ),
          if (_metodo == MetodoTreino.biSet) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Text('Grupo do bi-set')),
                Row(
                  children: [
                    IconButton(
                      onPressed: _agrupamento > 0
                          ? () => setState(() => _agrupamento--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(_agrupamento == 0 ? '—' : '$_agrupamento'),
                    IconButton(
                      onPressed: () => setState(() => _agrupamento++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.item.copyWith(
              series: _series,
              repeticoes: _repeticoes.text.trim().isEmpty
                  ? widget.item.repeticoes
                  : _repeticoes.text.trim(),
              cargaKg: double.tryParse(_carga.text.replaceAll(',', '.')) ??
                  widget.item.cargaKg,
              cadencia: _cadencia.text.trim(),
              metodo: _metodo,
              agrupamento:
                  _metodo == MetodoTreino.biSet ? _agrupamento : 0,
            ),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _EditarTreinoDialog extends StatefulWidget {
  const _EditarTreinoDialog({required this.treino});

  final Treino treino;

  @override
  State<_EditarTreinoDialog> createState() => _EditarTreinoDialogState();
}

class _EditarTreinoDialogState extends State<_EditarTreinoDialog> {
  late final TextEditingController _nome =
      TextEditingController(text: widget.treino.nome);
  late final TextEditingController _foco =
      TextEditingController(text: widget.treino.foco);
  late final Set<int> _dias = widget.treino.diasSemana.toSet();

  @override
  void dispose() {
    _nome.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar treino'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nome,
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Nome (ex.: Treino A)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _foco,
              decoration: const InputDecoration(
                  labelText: 'Subtítulo (ex.: Peito e Tríceps)'),
            ),
            const SizedBox(height: 12),
            const Text('Dias da semana'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final dia in _nomesDias.entries)
                  FilterChip(
                    label: Text(dia.value),
                    selected: _dias.contains(dia.key),
                    onSelected: (selecionado) => setState(() {
                      if (selecionado) {
                        _dias.add(dia.key);
                      } else {
                        _dias.remove(dia.key);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nome = _nome.text.trim();
            final foco = _foco.text.trim();
            if (nome.isEmpty || _dias.isEmpty) return;
            final diasOrdenados = _dias.toList()..sort();
            Navigator.of(context).pop(widget.treino.copyWith(
              nome: nome,
              foco: foco.isEmpty ? widget.treino.foco : foco,
              diasSemana: diasOrdenados,
            ));
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
