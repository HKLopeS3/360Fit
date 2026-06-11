import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../data/providers.dart';
import '../../shared/widgets.dart';
import 'form_aluno_screen.dart';

class AlunosScreen extends ConsumerStatefulWidget {
  const AlunosScreen({super.key});

  @override
  ConsumerState<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends ConsumerState<AlunosScreen> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus alunos'),
        actions: const [LogoutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FormAlunoScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo aluno'),
      ),
      body: PaginaCentralizada(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: InputDecoration(
                hintText: 'Buscar aluno…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: AsyncView(
              value: alunosAsync,
              builder: (alunos) {
                final filtrados = alunos
                    .where((a) => a.nome
                        .toLowerCase()
                        .contains(_busca.trim().toLowerCase()))
                    .toList();
                if (filtrados.isEmpty) {
                  return const Center(child: Text('Nenhum aluno encontrado.'));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final aluno in filtrados)
                      Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: IniciaisAvatar(aluno.iniciais),
                          title: Text(aluno.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${aluno.objetivo} · ${aluno.frequenciaSemanal}x/semana'),
                          trailing: aluno.riscoEvasao
                              ? Tooltip(
                                  message: 'Risco de evasão',
                                  child: Icon(Icons.warning_amber,
                                      color: context.brand.alerta),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.go('/personal/alunos/${aluno.id}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}
