import 'package:clube_do_salao/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows role gate and opens owner dashboard', (tester) async {
    await tester.pumpWidget(const ClubeDoSalaoApp());

    expect(find.text('Clube do Salao'), findsOneWidget);
    expect(find.text('Entrar como'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('MRR previsto'), findsOneWidget);
    expect(find.text('Assinantes'), findsOneWidget);
  });

  testWidgets('changes role before opening dashboard', (tester) async {
    await tester.pumpWidget(const ClubeDoSalaoApp());

    await tester.tap(find.text('Profissional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Profissional'), findsOneWidget);
    expect(find.text('Atendimentos de hoje'), findsOneWidget);
  });
}
