import 'package:fit360_app/app/router.dart';
import 'package:fit360_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Renderiza as principais telas em mobile (375), tablet (768) e
/// desktop (1280). Qualquer overflow de layout falha o teste.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  const tamanhos = {
    'mobile 375x812': Size(375, 812),
    'tablet 768x1024': Size(768, 1024),
    'desktop 1280x800': Size(1280, 800),
  };

  Future<void> bombear(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: nome, value: tamanho) in tamanhos.entries) {
    testWidgets('sem overflow em $nome', (tester) async {
      tester.view.physicalSize = tamanho * tester.view.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ProviderScope(child: Fit360App()));
      // O GoRouter é global; garante que cada cenário começa no login.
      router.go('/login');
      await tester.pumpAndSettle();

      // ------------------------------------------------------------- aluno
      await tester.tap(find.text('Entrar como Aluno'));
      await bombear(tester);
      for (final aba in ['Evolução', 'Agenda', 'Chat', 'Mais', 'Hoje']) {
        await tester.tap(find.text(aba).last);
        await bombear(tester);
      }

      // logout pela aba Hoje
      await tester.tap(find.byIcon(Icons.logout).first);
      await tester.pumpAndSettle();

      // ---------------------------------------------------------- personal
      await tester.tap(find.text('Entrar como Personal'));
      await bombear(tester);
      for (final aba in ['Alunos', 'Prescrição', 'Agenda', 'Mais']) {
        await tester.tap(find.text(aba).last);
        await bombear(tester);
      }

      // detalhe de um aluno (tela com pares de métricas)
      await tester.tap(find.text('Alunos').last);
      await bombear(tester);
      await tester.tap(find.text('Ricardo Almeida'));
      await bombear(tester);
      expect(find.text('Perfil do aluno'), findsOneWidget);
    });
  }
}
