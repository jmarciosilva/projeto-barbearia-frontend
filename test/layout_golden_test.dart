import 'package:clube_do_salao/main.dart';
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

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/owner_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do profissional', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/professional_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do cliente', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/customer_dashboard_mobile.png'),
    );
  });
}
