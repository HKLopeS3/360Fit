import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Tela "Meu perfil" do profissional: dados pessoais, CREF/CPF, foto e o
/// código de convite fixo para novos alunos se cadastrarem direto.
class PerfilPersonalScreen extends ConsumerStatefulWidget {
  const PerfilPersonalScreen({super.key});

  @override
  ConsumerState<PerfilPersonalScreen> createState() =>
      _PerfilPersonalScreenState();
}

class _PerfilPersonalScreenState extends ConsumerState<PerfilPersonalScreen> {
  late final _nome =
      TextEditingController(text: ref.read(sessaoProvider)?.nome ?? '');
  late final _cref =
      TextEditingController(text: ref.read(sessaoProvider)?.cref ?? '');
  late final _cpf =
      TextEditingController(text: ref.read(sessaoProvider)?.cpf ?? '');
  Uint8List? _novaFoto;
  Uint8List? _novaCapa;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _cref.dispose();
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _trocarFoto() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    setState(() => _novaFoto = bytes);
  }

  Future<void> _trocarCapa() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    // Abre o ajustador de posição/zoom antes de confirmar
    final ajustado = await _DialogAjusteCapa.mostrar(context, bytes);
    if (ajustado == null) return;
    setState(() => _novaCapa = ajustado);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await ref.read(sessaoProvider.notifier).atualizarPerfil(
          nome: _nome.text.trim(),
          cref: _cref.text.trim(),
          cpf: _cpf.text.trim(),
          fotoBytes: _novaFoto,
          capaBytes: _novaCapa,
        );
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado!')),
    );
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sessaoProvider);

    InputDecoration dec(String rotulo) => InputDecoration(
          labelText: rotulo,
          filled: true,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: PaginaCentralizada(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Center(
              child: GestureDetector(
                onTap: _trocarFoto,
                child: Stack(
                  children: [
                    if (_novaFoto != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: MemoryImage(_novaFoto!),
                      )
                    else if (usuario?.fotoUrl != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(usuario!.fotoUrl!),
                      )
                    else
                      IniciaisAvatar(
                        usuario?.nome.isNotEmpty == true
                            ? usuario!.nome[0].toUpperCase()
                            : '?',
                        raio: 48,
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Dados pessoais'),
            TextFormField(
              controller: _nome,
              decoration: dec('Nome'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            ParDeMetricas(
              primeiro: TextFormField(
                controller: _cref,
                decoration: dec('CREF'),
              ),
              segundo: TextFormField(
                controller: _cpf,
                decoration: dec('CPF'),
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
              label: const Text('Salvar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SectionTitle('Capa do perfil'),
            GestureDetector(
              onTap: _trocarCapa,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E22),
                  borderRadius: BorderRadius.circular(16),
                  image: _novaCapa != null
                      ? DecorationImage(
                          image: MemoryImage(_novaCapa!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.3),
                              BlendMode.darken),
                        )
                      : (usuario?.capaUrl != null
                          ? DecorationImage(
                              image: NetworkImage(usuario!.capaUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.3),
                                  BlendMode.darken),
                            )
                          : null),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.white70, size: 32),
                      const SizedBox(height: 6),
                      Text(
                        _novaCapa != null || usuario?.capaUrl != null
                            ? 'Toque para trocar a capa'
                            : 'Toque para adicionar uma capa',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A capa aparece como mural no dashboard dos seus alunos.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SectionTitle('Código de convite'),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compartilhe este código com novos alunos para que '
                      'criem a própria conta já vinculada a você.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            usuario?.codigoConvite ?? '—',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        if (usuario?.codigoConvite != null)
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () =>
                                _copiarCodigo(usuario!.codigoConvite!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Ajuste de capa (pan/zoom)

/// Altura do banner de capa (px lógicos).
const _kBannerH = 140.0;

class _DialogAjusteCapa extends StatefulWidget {
  const _DialogAjusteCapa({required this.bytes});

  final Uint8List bytes;

  static Future<Uint8List?> mostrar(BuildContext context, Uint8List bytes) =>
      showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _DialogAjusteCapa(bytes: bytes),
      );

  @override
  State<_DialogAjusteCapa> createState() => _DialogAjusteCapaState();
}

class _DialogAjusteCapaState extends State<_DialogAjusteCapa> {
  final _boundaryKey = GlobalKey();
  bool _capturando = false;

  // Transformação atual: escala e deslocamento do centro do container.
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Estado salvo no início do gesto.
  double _scaleBase = 1.0;
  Offset _offsetBase = Offset.zero;
  Offset _focalBase = Offset.zero;

  void _onScaleStart(ScaleStartDetails d) {
    _scaleBase = _scale;
    _offsetBase = _offset;
    _focalBase = d.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _scale = (_scaleBase * d.scale).clamp(0.2, 12.0);
      _offset = _offsetBase + (d.focalPoint - _focalBase);
    });
  }

  Future<void> _confirmar() async {
    setState(() => _capturando = true);
    // Aguarda um frame para garantir que o RepaintBoundary foi pintado.
    await Future.microtask(() {});
    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.of(context).pop(byteData?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    // Área de trabalho: maior que o banner para dar espaço de manobra.
    const workH = _kBannerH * 2.8;
    // Offset vertical do banner dentro da área de trabalho.
    const bannerTop = (workH - _kBannerH) / 2;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Ajustar capa',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Arraste para reposicionar. Pinça (ou scroll) para zoom.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 12),

          // ── Área de trabalho ──────────────────────────────────────────
          ClipRect(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Container(
                height: workH,
                color: const Color(0xFF111111),
                child: Stack(
                  children: [
                    // Imagem transformada (pan + zoom livre)
                    Positioned.fill(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(_offset.dx, _offset.dy)
                          ..scale(_scale),
                        child: Image.memory(
                          widget.bytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),

                    // Overlay escuro fora do frame do banner
                    IgnorePointer(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(color: Colors.black54),
                          ),
                          SizedBox(height: _kBannerH), // janela transparente
                          Expanded(
                            child: Container(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // Borda branca ao redor do frame do banner
                    IgnorePointer(
                      child: Positioned(
                        top: bannerTop,
                        left: 0,
                        right: 0,
                        height: _kBannerH,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),

                    // Hint centralizado na janela
                    IgnorePointer(
                      child: Positioned(
                        top: bannerTop,
                        left: 0,
                        right: 0,
                        height: _kBannerH,
                        child: const Center(
                          child: Text(
                            'Arraste a foto para posicionar',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── RepaintBoundary oculta que captura só o frame ─────────────
          // Renderiza a mesma imagem + mesma transform em tamanho de banner.
          SizedBox(
            height: 0,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: _kBannerH,
              maxWidth: double.infinity,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  return SizedBox(
                    width: w,
                    height: _kBannerH,
                    child: ClipRect(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(_offset.dx, _offset.dy)
                          ..scale(_scale),
                        child: Image.memory(
                          widget.bytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Ações ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _capturando ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _capturando ? null : _confirmar,
                  child: _capturando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Usar esta parte'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
