import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Feed social da academia: alunos postam, o personal modera e publica.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, required this.comoPersonal});

  /// true = mostra a aba de moderação.
  final bool comoPersonal;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  Future<void> _novaPostagem() async {
    final texto = TextEditingController();
    Uint8List? foto;
    final publicar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova postagem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: texto,
                  maxLines: 3,
                  maxLength: 280,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Compartilhe sua conquista…',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (foto != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(foto!,
                        height: 140, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () async {
                    final arquivo = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1280,
                      imageQuality: 85,
                    );
                    if (arquivo == null) return;
                    final bytes = await arquivo.readAsBytes();
                    setState(() => foto = bytes);
                  },
                  icon: const Icon(Icons.photo),
                  label: Text(
                      foto == null ? 'Adicionar foto' : 'Trocar foto'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Enviar para revisão'),
            ),
          ],
        ),
      ),
    );
    if (publicar != true || texto.text.trim().isEmpty || !mounted) return;
    await ref.read(feedRepositoryProvider).publicar(
          alunoId: alunoLogadoId,
          texto: texto.text.trim(),
          fotoBytes: foto,
        );
    ref.invalidate(feedProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Postagem enviada! Seu personal revisa antes de publicar. ✨'),
        ),
      );
    }
  }

  Future<void> _moderar(Postagem p, bool aprovar) async {
    var motivo = '';
    if (!aprovar) {
      final controller = TextEditingController();
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rejeitar postagem'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Motivo (visível ao aluno)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Rejeitar'),
            ),
          ],
        ),
      );
      if (confirmado != true) return;
      motivo = controller.text.trim();
    }
    await ref
        .read(feedRepositoryProvider)
        .moderar(p.id, aprovar: aprovar, motivo: motivo);
    ref.invalidate(feedProvider);
    ref.invalidate(postagensPendentesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(aprovar
                ? 'Postagem de ${p.autorNome} publicada no feed! 🎉'
                : 'Postagem rejeitada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final corpoFeed = _ListaFeed(
      provider: feedProvider,
      vazio: 'O feed ainda está vazio. Seja a primeira pessoa a postar!',
      rodapeStatus: true,
      aoAlternarCurtida: (p) async {
        await ref.read(feedRepositoryProvider).alternarCurtida(p.id);
        ref.invalidate(feedProvider);
      },
    );

    if (!widget.comoPersonal) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feed da academia')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _novaPostagem,
          icon: const Icon(Icons.edit),
          label: const Text('Postar'),
        ),
        body: PaginaCentralizada(maxWidth: 560, child: corpoFeed),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feed da academia'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Feed'),
              Tab(
                child: Consumer(builder: (context, ref, _) {
                  final pendentes = ref
                          .watch(postagensPendentesProvider)
                          .valueOrNull
                          ?.length ??
                      0;
                  return Badge(
                    isLabelVisible: pendentes > 0,
                    label: Text('$pendentes'),
                    child: const Text('Moderação'),
                  );
                }),
              ),
            ],
          ),
        ),
        body: PaginaCentralizada(
          maxWidth: 560,
          child: TabBarView(
            children: [
              corpoFeed,
              _ListaFeed(
                provider: postagensPendentesProvider,
                vazio: 'Nenhuma postagem aguardando revisão. ✅',
                acoesModeracao: _moderar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaFeed extends ConsumerWidget {
  const _ListaFeed({
    required this.provider,
    required this.vazio,
    this.acoesModeracao,
    this.aoAlternarCurtida,
    this.rodapeStatus = false,
  });

  final FutureProvider<List<Postagem>> provider;
  final String vazio;
  final void Function(Postagem, bool aprovar)? acoesModeracao;
  final Future<void> Function(Postagem)? aoAlternarCurtida;
  final bool rodapeStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postagensAsync = ref.watch(provider);
    return AsyncView(
      value: postagensAsync,
      builder: (postagens) => postagens.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(vazio, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final p in postagens)
                  _PostagemCard(
                    postagem: p,
                    acoesModeracao: acoesModeracao,
                    aoAlternarCurtida: aoAlternarCurtida,
                    mostrarStatus: rodapeStatus,
                  ),
              ],
            ),
    );
  }
}

class _PostagemCard extends StatelessWidget {
  const _PostagemCard({
    required this.postagem,
    this.acoesModeracao,
    this.aoAlternarCurtida,
    this.mostrarStatus = false,
  });

  final Postagem postagem;
  final void Function(Postagem, bool aprovar)? acoesModeracao;
  final Future<void> Function(Postagem)? aoAlternarCurtida;
  final bool mostrarStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = postagem;
    final iniciais = p.autorNome
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IniciaisAvatar(iniciais, raio: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.autorNome,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      Text(fmtDataHora.format(p.criadaEm),
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                if (mostrarStatus && p.status == StatusPostagem.pendente)
                  const Chip(
                    label: Text('Em revisão'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.texto),
            if (p.fotoBytes != null || p.fotoUrl != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _abrirFoto(context, p),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: p.fotoBytes != null
                      ? Image.memory(Uint8List.fromList(p.fotoBytes!),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover)
                      : Image.network(p.fotoUrl!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (contexto, erro, pilha) =>
                              const SizedBox(
                                  height: 80,
                                  child: Center(
                                      child: Icon(Icons.broken_image)))),
                ),
              ),
            ],
            const SizedBox(height: 6),
            if (acoesModeracao != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => acoesModeracao!(postagem, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeitar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => acoesModeracao!(postagem, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                  ),
                ],
              )
            else if (aoAlternarCurtida != null &&
                p.status == StatusPostagem.aprovada)
              Row(
                children: [
                  IconButton(
                    tooltip: p.euCurti ? 'Descurtir' : 'Curtir',
                    onPressed: () => aoAlternarCurtida!(postagem),
                    icon: Icon(
                      p.euCurti ? Icons.favorite : Icons.favorite_border,
                      color: p.euCurti ? Colors.red : null,
                    ),
                  ),
                  Text('${p.curtidas}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _abrirFoto(BuildContext context, Postagem p) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => _VisualizadorFoto(
          fotoBytes: p.fotoBytes,
          fotoUrl: p.fotoUrl,
        ),
      ),
    );
  }
}

/// Visualização em tela cheia de uma foto do feed, com zoom/pan.
class _VisualizadorFoto extends StatelessWidget {
  const _VisualizadorFoto({this.fotoBytes, this.fotoUrl});

  final List<int>? fotoBytes;
  final String? fotoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: fotoBytes != null
              ? Image.memory(Uint8List.fromList(fotoBytes!))
              : Image.network(fotoUrl!,
                  errorBuilder: (context, erro, pilha) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64)),
        ),
      ),
    );
  }
}
