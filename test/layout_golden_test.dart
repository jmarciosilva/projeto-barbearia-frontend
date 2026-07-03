import 'package:clube_do_salao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('captura layout do login', (tester) async {
    await pumpMobileApp(tester);

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/login_mobile.png'),
    );
  });

  testWidgets('captura layout do proprietario', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/owner_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do profissional', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Profissional'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/professional_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do cliente', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/customer_dashboard_mobile.png'),
    );
  });
}
