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

  testWidgets('fluxo completo de execução de treino', (tester) async {
    tester.view.physicalSize =
        const Size(420, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    router.go('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar como Aluno'));
    await bombear(tester);

    // Inicia o treino do dia.
    expect(find.text('Iniciar treino'), findsOneWidget);
    await tester.tap(find.text('Iniciar treino'));
    await bombear(tester);

    // Tela de execução: série 1 do primeiro exercício.
    expect(find.textContaining('Série 1 de'), findsOneWidget);
    await tester.tap(find.text('Concluir série'));
    await tester.pump();

    // Entrou em descanso; cronômetro regride com o tempo.
    expect(find.text('Descanso'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Descanso'), findsOneWidget);

    // Pula o descanso e segue para a série 2.
    await tester.tap(find.text('Pular descanso'));
    await tester.pump();
    expect(find.textContaining('Série 2 de'), findsOneWidget);

    // Finaliza incompleto (com confirmação) e vê o resumo.
    await tester.scrollUntilVisible(
      find.text('Finalizar treino'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar treino'));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar treino incompleto?'), findsOneWidget);
    await tester.tap(find.text('Finalizar'));
    await bombear(tester);
    expect(find.text('Treino concluído! 🎉'), findsOneWidget);
    expect(find.text('Volume total'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await bombear(tester);

    // De volta ao Hoje: marcado como concluído.
    expect(find.text('Treino concluído hoje! 🎉'), findsOneWidget);

    // Histórico (via Evolução) lista a conclusão de hoje.
    await tester.tap(find.text('Evolução').last);
    await bombear(tester);
    await tester.tap(find.byIcon(Icons.history));
    await bombear(tester);
    expect(find.text('Histórico de treinos'), findsOneWidget);
    expect(find.textContaining('treino'), findsWidgets);
  });
}
