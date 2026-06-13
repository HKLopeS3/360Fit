import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Credenciais dos usuários de demonstração (servidos pelo
/// `MockAuthRepository`, que ignora a senha e decide o perfil pelo email).
const emailAluno = 'carlos.mendes@email.com';
const emailPersonal = 'joao.silva@360fit.com.br';
const senhaDemo = 'demo360fit';

/// Preenche o formulário de login (email/senha) e toca em "Entrar",
/// aguardando a navegação para a home do perfil correspondente.
Future<void> entrarComo(WidgetTester tester, String email) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'), senhaDemo);
  await tester.tap(find.text('Entrar'));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}
