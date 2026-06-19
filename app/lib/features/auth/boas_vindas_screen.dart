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

  /// Retorna true se o usuário ainda não viu a tela.
  static bool deveExibir(String userId) =>
      html.window.localStorage[_chave(userId)] == null;

  static void marcarVisto(String userId) =>
      html.window.localStorage[_chave(userId)] = '1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessao = ref.watch(sessaoProvider);
    if (sessao == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    final isPersonal = sessao.perfil == PerfilUsuario.personal;
    final destino =
        isPersonal ? '/personal/dashboard' : '/aluno/hoje';

    void continuar() {
      marcarVisto(sessao.id);
      context.go(destino);
    }

    final brand = context.brand;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: brand.gradientePrimario,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Logo(isPersonal: isPersonal),
                    const SizedBox(height: 32),
                    Text(
                      'Bem-vindo(a),',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sessao.nome,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPersonal ? 'Profissional de Educação Física' : 'Aluno',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _InfoCards(isPersonal: isPersonal),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: brand.primaria,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: continuar,
                        child: const Text('Começar agora'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.isPersonal});
  final bool isPersonal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: Icon(
        isPersonal ? Icons.sports : Icons.fitness_center,
        size: 52,
        color: Colors.white,
      ),
    );
  }
}

class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.isPersonal});
  final bool isPersonal;

  @override
  Widget build(BuildContext context) {
    final itens = isPersonal
        ? [
            (Icons.group_outlined, 'Gerencie seus alunos',
                'Acompanhe evolução, frequência e alertas de todos em um só lugar.'),
            (Icons.assignment_outlined, 'Prescreva treinos',
                'Monte programas personalizados com a biblioteca de exercícios.'),
            (Icons.trending_up_outlined, 'Acompanhe resultados',
                'Avaliações físicas, histórico de cargas e comparativos visuais.'),
          ]
        : [
            (Icons.fitness_center_outlined, 'Seu treino de hoje',
                'Siga o programa do seu personal com guia série a série.'),
            (Icons.timeline_outlined, 'Veja sua evolução',
                'Gráficos de peso, medidas e histórico de treinos completados.'),
            (Icons.chat_bubble_outline, 'Fale com seu personal',
                'Chat direto para tirar dúvidas e receber orientações.'),
          ];

    return Column(
      children: itens
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$1, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
