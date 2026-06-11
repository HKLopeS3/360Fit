import 'package:fit360_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> _bombearAteCarregar(WidgetTester tester) async {
  // Avança a latência mock (350ms) e as animações.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  testWidgets('login navega para o perfil do aluno e do personal',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    await tester.pumpAndSettle();

    // Tela de login.
    expect(find.text('Entrar como Aluno'), findsOneWidget);
    expect(find.text('Entrar como Personal'), findsOneWidget);

    // Entra como aluno → aba Hoje.
    await tester.tap(find.text('Entrar como Aluno'));
    await _bombearAteCarregar(tester);
    expect(find.textContaining('Olá, Carlos'), findsOneWidget);
    expect(find.text('Evolução'), findsOneWidget); // bottom nav

    // Sai e entra como personal → dashboard.
    await tester.tap(find.byIcon(Icons.logout).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como Personal'));
    await _bombearAteCarregar(tester);
    expect(find.textContaining('Olá, João'), findsOneWidget);
    expect(find.text('Alunos ativos'), findsOneWidget);

    // Navega para a lista de alunos.
    await tester.tap(find.text('Alunos').last);
    await _bombearAteCarregar(tester);
    expect(find.text('Fernanda Costa'), findsOneWidget);

    // Aba Mais: menu institucional e políticas.
    await tester.tap(find.text('Mais').last);
    await _bombearAteCarregar(tester);
    expect(find.text('Ajuda e perguntas frequentes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Política de privacidade'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Política de privacidade'));
    await _bombearAteCarregar(tester);
    expect(find.textContaining('Última atualização'), findsOneWidget);
  });
}
