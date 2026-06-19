// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/brand_theme.dart';
import '../../core/models/models.dart';
import '../../data/providers.dart';

/// Tela de boas-vindas exibida uma única vez por usuário após o primeiro login.
/// O estado "já viu" é salvo em localStorage (chave: bv_<userId>).
class BoasVindasScreen extends ConsumerWidget {
  const BoasVindasScreen({super.key});

  static String _chave(String userId) => 'bv_$userId';

  static bool deveExibir(String userId) =>
      html.window.localStorage[_chave(userId)] == null;

  static void marcarVisto(String userId) =>
      html.window.localStorage[_chave(userId)] = '1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    if (sessao == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    final isPersonal = sessao.perfil == PerfilUsuario.personal;
    final destino = isPersonal ? '/personal/dashboard' : '/aluno/hoje';

    void continuar() {
      marcarVisto(sessao.id);
      context.go(destino);
    }

    final brand = context.brand;

    final itens = isPersonal
        ? [
            _Item(
              icone: Icons.group_outlined,
              titulo: 'Gerencie seus alunos',
              descricao:
                  'Acompanhe evolução, frequência e alertas em um só lugar.',
              cor: const Color(0xFF00897B),
            ),
            _Item(
              icone: Icons.assignment_outlined,
              titulo: 'Prescreva treinos',
              descricao:
                  'Monte programas personalizados com a biblioteca completa.',
              cor: const Color(0xFF00ACC1),
            ),
            _Item(
              icone: Icons.trending_up_outlined,
              titulo: 'Acompanhe resultados',
              descricao:
                  'Avaliações físicas, histórico de cargas e comparativos.',
              cor: const Color(0xFF43A047),
            ),
          ]
        : [
            _Item(
              icone: Icons.fitness_center_outlined,
              titulo: 'Seu treino de hoje',
              descricao:
                  'Siga o programa do seu personal com guia série a série.',
              cor: const Color(0xFF00897B),
            ),
            _Item(
              icone: Icons.timeline_outlined,
              titulo: 'Veja sua evolução',
              descricao:
                  'Gráficos de peso, medidas e histórico de treinos.',
              cor: const Color(0xFF00ACC1),
            ),
            _Item(
              icone: Icons.chat_bubble_outline,
              titulo: 'Fale com seu personal',
              descricao:
                  'Chat direto para tirar dúvidas e receber orientações.',
              cor: const Color(0xFF43A047),
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // ── Header gradiente ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: brand.gradientePrimario,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white38, width: 2),
                          ),
                          child: Icon(
                            isPersonal
                                ? Icons.sports_outlined
                                : Icons.fitness_center,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bem-vindo(a)!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sessao.nome,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            isPersonal
                                ? 'Profissional de Educação Física'
                                : 'Aluno',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Cards de funcionalidades ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'O que você pode fazer aqui:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final item in itens) ...[
                          _CardItem(item: item),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),

                        // ── Botão começar ─────────────────────────────
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: brand.primaria,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: continuar,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Começar agora'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.cor,
  });
  final IconData icone;
  final String titulo;
  final String descricao;
  final Color cor;
}

class _CardItem extends StatelessWidget {
  const _CardItem({required this.item});
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icone, color: item.cor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.descricao,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
              color: item.cor.withValues(alpha: 0.4), size: 18),
        ],
      ),
    );
  }
}
