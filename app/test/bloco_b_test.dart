import 'package:fit360_app/app/router.dart';
import 'package:fit360_app/core/mock/mock_database.dart';
import 'package:fit360_app/core/models/models.dart';
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

  Future<void> entrarComo(WidgetTester tester, String botao) async {
    await tester.pumpWidget(const ProviderScope(child: Fit360App()));
    router.go('/login');
    await tester.pumpAndSettle();
    await tester.tap(find.text(botao));
    await bombear(tester);
  }

  testWidgets('aluno confirma presença na agenda', (tester) async {
    tester.view.physicalSize =
        const Size(420, 1100) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await entrarComo(tester, 'Entrar como Aluno');

    await tester.tap(find.text('Agenda').last);
    await bombear(tester);
    expect(find.text('Confirmar presença'), findsWidgets);
    await tester.tap(find.text('Confirmar presença').first);
    await bombear(tester);
    expect(find.text('Confirmado'), findsWidgets);
  });

  testWidgets('personal cria agendamento e cancela outro', (tester) async {
    tester.view.physicalSize =
        const Size(420, 1100) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await entrarComo(tester, 'Entrar como Personal');

    await tester.tap(find.text('Agenda').last);
    await bombear(tester);

    // Cria agendamento para a Juliana.
    await tester.tap(find.text('Agendar'));
    await bombear(tester);
    await tester.tap(find.text('Aluno *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juliana Rocha').last);
    await tester.pumpAndSettle();
    await rolarETocar(tester, find.text('Criar agendamento'));
    await bombear(tester);
    expect(find.text('Agenda da semana'), findsOneWidget);
    expect(find.textContaining('Juliana Rocha'), findsWidgets);

    // Cancela um agendamento futuro via menu (os de hoje cedo saem do
    // filtro de "próximos" ao recarregar).
    await tester.scrollUntilVisible(
      find.byType(PopupMenuButton<String>).last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar agendamento').last);
    await bombear(tester);
    // O card cancelado pode ficar fora da viewport após o recarregamento;
    // valida direto na fonte de dados mock.
    expect(
      MockDatabase.instance.agendamentos
          .any((a) => a.status == StatusAgendamento.cancelado),
      isTrue,
    );
    // Drena o timer de latência simulada do recarregamento da agenda.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  });

  testWidgets('personal cadastra aluno novo e ele aparece na lista',
      (tester) async {
    tester.view.physicalSize =
        const Size(420, 1100) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await entrarComo(tester, 'Entrar como Personal');

    await tester.tap(find.text('Alunos').last);
    await bombear(tester);
    await tester.tap(find.text('Novo aluno'));
    await bombear(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo *'),
        'Tatiane Moraes');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Idade'), '27');
    await rolarETocar(tester, find.text('Cadastrar aluno'));
    await bombear(tester);

    expect(find.text('Meus alunos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tatiane Moraes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tatiane Moraes'), findsOneWidget);
  });

  testWidgets('aluno registra peso e vê notificações', (tester) async {
    tester.view.physicalSize =
        const Size(420, 1100) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await entrarComo(tester, 'Entrar como Aluno');

    // Notificações: sininho com badge → bottom sheet.
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await bombear(tester);
    expect(find.textContaining('Seu treino de hoje'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // fecha o sheet
    await tester.pumpAndSettle();

    // Perfil via aba Mais.
    await tester.tap(find.text('Mais').last);
    await bombear(tester);
    await tester.tap(find.textContaining('Toque para ver e editar'));
    await bombear(tester);
    expect(find.text('Meu perfil'), findsOneWidget);

    // Registro rápido de peso.
    await rolarETocar(tester, find.text('Registrar peso de hoje'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '82,9');
    await tester.tap(find.text('Salvar'));
    await bombear(tester);
    expect(find.textContaining('82,9 kg registrado'), findsOneWidget);
  });
}
