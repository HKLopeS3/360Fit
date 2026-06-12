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

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  testWidgets('aluno posta, personal modera e o post aparece no feed',
      (tester) async {
    tester.view.physicalSize =
        const Size(420, 1100) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    router.go('/login');
    await tester.pumpAndSettle();

    // Aluno cria a postagem.
    await tester.tap(find.text('Entrar como Aluno'));
    await bombear(tester);
    await tester.tap(find.byIcon(Icons.dynamic_feed_outlined));
    await bombear(tester);
    expect(find.text('Feed da academia'), findsOneWidget);
    await tester.tap(find.text('Postar'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, 'Treino pago hoje! 🔥');
    await tester.tap(find.text('Enviar para revisão'));
    await bombear(tester);
    expect(find.textContaining('enviada'), findsOneWidget);

    // Logout → personal modera.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar como Personal'));
    await bombear(tester);
    await tester.tap(find.byIcon(Icons.dynamic_feed_outlined));
    await bombear(tester);
    await tester.tap(find.text('Moderação'));
    await bombear(tester);
    expect(find.text('Treino pago hoje! 🔥'), findsOneWidget);
    await tester.tap(find.text('Aprovar').first);
    await bombear(tester);

    // Post aprovado aparece no feed com curtidas.
    await tester.tap(find.text('Feed'));
    await bombear(tester);
    expect(find.text('Treino pago hoje! 🔥'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await bombear(tester);
    expect(find.byIcon(Icons.favorite), findsWidgets);
  });
}
