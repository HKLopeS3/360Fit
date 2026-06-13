import 'package:flutter/material.dart';
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

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    await ref.read(sessaoProvider.notifier).atualizarPerfil(
          nome: _nome.text.trim(),
          cref: _cref.text.trim(),
          cpf: _cpf.text.trim(),
          fotoBytes: _novaFoto,
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
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
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
