import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Fotogrametria: fotos posturais por ângulo com grade de alinhamento.
class FotosPosturaScreen extends ConsumerStatefulWidget {
  const FotosPosturaScreen({
    super.key,
    required this.alunoId,
    required this.nomeAluno,
  });

  final String alunoId;
  final String nomeAluno;

  @override
  ConsumerState<FotosPosturaScreen> createState() =>
      _FotosPosturaScreenState();
}

class _FotosPosturaScreenState extends ConsumerState<FotosPosturaScreen> {
  static const _rotulos = {
    AnguloFoto.frente: 'Frente',
    AnguloFoto.costas: 'Costas',
    AnguloFoto.perfilDireito: 'Perfil D',
    AnguloFoto.perfilEsquerdo: 'Perfil E',
  };

  bool _enviando = false;

  Future<void> _adicionar(AnguloFoto angulo) async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    setState(() => _enviando = true);
    await ref.read(evolucaoRepositoryProvider).salvarFotoPostura(
        alunoId: widget.alunoId, angulo: angulo, bytes: bytes);
    ref.invalidate(fotosPosturaProvider(widget.alunoId));
    if (!mounted) return;
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Foto (${_rotulos[angulo]}) salva!')),
    );
  }

  void _ampliar(FotoAluno foto) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${_rotulos[foto.angulo]} · ${fmtDiaMes.format(foto.data)}/${foto.data.year}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: _FotoComGrade(foto: foto, ampliada: true),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotosAsync = ref.watch(fotosPosturaProvider(widget.alunoId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Postura — ${widget.nomeAluno}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PaginaCentralizada(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionTitle('Adicionar foto'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final angulo in AnguloFoto.values)
                  ActionChip(
                    avatar: _enviando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo, size: 18),
                    label: Text(_rotulos[angulo]!),
                    onPressed: _enviando ? null : () => _adicionar(angulo),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'A grade sobreposta ajuda a marcar desvios (escoliose, '
              'hipercifose, valgo). Use fundo neutro e enquadre o corpo todo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SectionTitle('Fotos registradas'),
            AsyncView(
              value: fotosAsync,
              builder: (fotos) => fotos.isEmpty
                  ? const Card(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            Text('Nenhuma foto ainda. Adicione acima. 📸'),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width < 500 ? 2 : 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                      children: [
                        for (final foto in fotos)
                          GestureDetector(
                            onTap: () => _ampliar(foto),
                            child: Card(
                              color: Colors.white,
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      child: _FotoComGrade(foto: foto)),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${_rotulos[foto.angulo]} · ${fmtDiaMes.format(foto.data)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto com grade de fotogrametria sobreposta.
class _FotoComGrade extends StatelessWidget {
  const _FotoComGrade({required this.foto, this.ampliada = false});

  final FotoAluno foto;
  final bool ampliada;

  @override
  Widget build(BuildContext context) {
    final imagem = foto.bytes != null
        ? Image.memory(Uint8List.fromList(foto.bytes!),
            fit: ampliada ? BoxFit.contain : BoxFit.cover)
        : Image.network(foto.url ?? '',
            fit: ampliada ? BoxFit.contain : BoxFit.cover,
            errorBuilder: (contexto, erro, pilha) =>
                const Center(child: Icon(Icons.broken_image)));
    return Stack(
      fit: StackFit.expand,
      children: [
        imagem,
        CustomPaint(painter: _GradePainter()),
      ],
    );
  }
}

class _GradePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linha = Paint()
      ..color = const Color(0x8800E5FF)
      ..strokeWidth = 1;
    final central = Paint()
      ..color = const Color(0xCCFF1744)
      ..strokeWidth = 1.6;

    // grade 4×6
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linha);
    }
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linha);
    }
    // linha de prumo central
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), central);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
