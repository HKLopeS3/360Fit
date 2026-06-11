import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Linha do tempo de fotos de evolução com comparador lado a lado.
class FotosEvolucaoScreen extends ConsumerStatefulWidget {
  const FotosEvolucaoScreen({super.key});

  @override
  ConsumerState<FotosEvolucaoScreen> createState() =>
      _FotosEvolucaoScreenState();
}

class _FotosEvolucaoScreenState extends ConsumerState<FotosEvolucaoScreen> {
  int? _antes;
  int? _depois;
  bool _enviando = false;

  Future<void> _adicionar() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (arquivo == null || !mounted) return;
    final obsController = TextEditingController();
    final observacao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nota da foto (opcional)'),
        content: TextField(
          controller: obsController,
          decoration: const InputDecoration(
            hintText: 'ex.: fim do primeiro ciclo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(obsController.text.trim()),
            child: const Text('Salvar foto'),
          ),
        ],
      ),
    );
    if (observacao == null || !mounted) return;
    setState(() => _enviando = true);
    final bytes = await arquivo.readAsBytes();
    await ref.read(evolucaoRepositoryProvider).salvarFotoEvolucao(
        alunoId: alunoLogadoId, bytes: bytes, observacao: observacao);
    ref.invalidate(fotosEvolucaoProvider(alunoLogadoId));
    if (mounted) setState(() => _enviando = false);
  }

  Widget _foto(FotoAluno f, {BoxFit fit = BoxFit.cover}) =>
      f.bytes != null
          ? Image.memory(Uint8List.fromList(f.bytes!), fit: fit)
          : Image.network(f.url ?? '', fit: fit,
              errorBuilder: (contexto, erro, pilha) =>
                  const Center(child: Icon(Icons.broken_image)));

  @override
  Widget build(BuildContext context) {
    final fotosAsync = ref.watch(fotosEvolucaoProvider(alunoLogadoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Fotos de evolução')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enviando ? null : _adicionar,
        icon: _enviando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo),
        label: const Text('Nova foto'),
      ),
      body: PaginaCentralizada(
        child: AsyncView(
          value: fotosAsync,
          builder: (fotos) {
            if (fotos.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Registre sua primeira foto e acompanhe a '
                    'transformação ao longo do tempo. 📸',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final antes = fotos[_antes ?? 0];
            final depois = fotos[_depois ?? fotos.length - 1];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (fotos.length >= 2) ...[
                  const SectionTitle('Antes × Depois'),
                  SizedBox(
                    height: 280,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ComparadorLado(
                            rotulo: fmtDiaMes.format(antes.data),
                            child: _foto(antes),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ComparadorLado(
                            rotulo: fmtDiaMes.format(depois.data),
                            child: _foto(depois),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque numa foto da linha do tempo para usá-la como '
                    '"antes"; toque longo para "depois".',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SectionTitle('Linha do tempo'),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width < 500 ? 3 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    for (final (i, f) in fotos.indexed)
                      GestureDetector(
                        onTap: () => setState(() => _antes = i),
                        onLongPress: () => setState(() => _depois = i),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _foto(f),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.black54,
                                  padding: const EdgeInsets.all(3),
                                  child: Text(
                                    fmtDiaMes.format(f.data),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ComparadorLado extends StatelessWidget {
  const _ComparadorLado({required this.rotulo, required this.child});

  final String rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: child),
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(6),
            child: Text(rotulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
