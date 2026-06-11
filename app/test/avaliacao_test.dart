import 'package:fit360_app/app/router.dart';
import 'package:fit360_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> bombear(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

/// Rola até [finder] e afasta-o da borda inferior (FAB/limite da tela)
/// antes de tocar.
Future<void> rolarETocar(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  testWidgets('personal cria avaliação e compara evolução', (tester) async {
    tester.view.physicalSize =
        const Size(420, 1000) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    router.go('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como Personal'));
    await bombear(tester);

    // Abre o detalhe do Carlos.
    await tester.tap(find.text('Alunos').last);
    await bombear(tester);
    await tester.tap(find.text('Carlos Mendes'));
    await bombear(tester);

    // Nova avaliação.
    await rolarETocar(tester, find.text('Nova avaliação'));
    await bombear(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Peso *'), '83,2');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Gordura'), '17,1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Massa magra'), '68,9');
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Cintura'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Cintura'), '84');
    await rolarETocar(tester, find.text('Salvar avaliação'));
    await bombear(tester);

    // Voltou ao detalhe; a nova avaliação aparece.
    expect(find.textContaining('83.2 kg'), findsWidgets);

    // Comparativo: primeira × última com deltas.
    await tester.scrollUntilVisible(
      find.text('Comparar'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Comparar'));
    await bombear(tester);
    expect(find.text('Gordura corporal'), findsOneWidget);
    expect(find.text('Massa magra'), findsOneWidget);
    expect(find.textContaining('▼'), findsWidgets); // gordura caiu
  });

  testWidgets('validação rejeita número inválido', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    router.go('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como Personal'));
    await bombear(tester);
    await tester.tap(find.text('Alunos').last);
    await bombear(tester);
    await tester.tap(find.text('Fernanda Costa'));
    await bombear(tester);
    await rolarETocar(tester, find.text('Nova avaliação'));
    await bombear(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Peso *'), 'abc');
    await rolarETocar(tester, find.text('Salvar avaliação'));
    await tester.pumpAndSettle();
    // Volta ao topo: o erro fica junto do campo Peso (a ListView descarta
    // widgets fora da viewport).
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Número inválido (use 70,5)'), findsOneWidget);
  });
}
