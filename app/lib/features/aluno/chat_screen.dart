import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';

/// Conversa do aluno logado com o personal.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, this.alunoId = alunoLogadoId, this.comoAluno = true});

  /// Conversa exibida (no perfil do personal, o aluno selecionado).
  final String alunoId;

  /// true quando quem digita é o aluno; false quando é o personal.
  final bool comoAluno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversaAsync = ref.watch(conversaProvider(alunoId));

    return Scaffold(
      appBar: AppBar(
        title: Text(comoAluno ? 'Chat com o personal' : 'Chat com o aluno'),
        actions: comoAluno ? const [LogoutButton()] : null,
      ),
      body: PaginaCentralizada(
        child: Column(
          children: [
            Expanded(
              child: AsyncView(
                value: conversaAsync,
                builder: (mensagens) => ListView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final m in mensagens.reversed)
                      _Balao(mensagem: m, minha: m.doAluno == comoAluno),
                  ],
                ),
              ),
            ),
            _CampoMensagem(alunoId: alunoId, comoAluno: comoAluno),
          ],
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.mensagem, required this.minha});

  final Mensagem mensagem;
  final bool minha;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: minha ? scheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem.texto,
              style: TextStyle(color: minha ? Colors.white : null),
            ),
            const SizedBox(height: 4),
            Text(
              fmtHora.format(mensagem.dataHora),
              style: TextStyle(
                fontSize: 11,
                color: minha ? Colors.white70 : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoMensagem extends ConsumerStatefulWidget {
  const _CampoMensagem({required this.alunoId, required this.comoAluno});

  final String alunoId;
  final bool comoAluno;

  @override
  ConsumerState<_CampoMensagem> createState() => _CampoMensagemState();
}

class _CampoMensagemState extends ConsumerState<_CampoMensagem> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    _controller.clear();
    await ref
        .read(conversaProvider(widget.alunoId).notifier)
        .enviar(texto, doAluno: widget.comoAluno);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Escreva uma mensagem…',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
              ),
            ),
            IconButton.filled(
              onPressed: _enviar,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
