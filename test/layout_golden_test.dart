import 'package:clube_do_salao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _mobileSize = Size(390, 844);

void main() {
  Future<void> pumpMobileApp(WidgetTester tester) async {
    tester.view.physicalSize = _mobileSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ClubeDoSalaoApp());
    await tester.pumpAndSettle();
  }

  testWidgets('captura layout da escolha de perfil', (tester) async {
    await pumpMobileApp(tester);

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/role_gate_mobile.png'),
    );
  });

  testWidgets('captura layout do proprietario', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/owner_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do profissional', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Profissional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/professional_dashboard_mobile.png'),
    );
  });

  testWidgets('captura layout do cliente', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClubeDoSalaoApp),
      matchesGoldenFile('goldens/customer_dashboard_mobile.png'),
    );
  });
}
