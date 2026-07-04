import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('proprietario cadastra cliente pela API', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar cliente'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
    await tester.enterText(find.byType(TextFormField).at(1), '11999990000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente Ana Souza cadastrado.'), findsOneWidget);
    expect(find.text('Proximas acoes'), findsOneWidget);
  });

  testWidgets('proprietario confirma um pagamento pendente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar pagamento manual'));
    await tester.pumpAndSettle();

    expect(find.text('Joao Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pagamento pendente.'), findsOneWidget);
  });

  testWidgets('profissional conclui atendimento pela API', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Profissional'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do atendimento'), findsOneWidget);

    await tester.tap(find.text('Concluir atendimento'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimento concluido'), findsOneWidget);

    await tester.tap(find.text('Voltar para a agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimentos de hoje'), findsOneWidget);
  });

  testWidgets('cliente percorre o fluxo completo de agendamento pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher servico'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher profissional'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar horario'), findsOneWidget);

    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();

    expect(find.text('Agendamento confirmado'), findsWidgets);

    await tester.tap(find.text('Voltar ao inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Novo agendamento'), findsOneWidget);
  });

  testWidgets('proprietario cria conta do estabelecimento pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.text('Criar conta do estabelecimento'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Novo Salao');
    await tester.enterText(find.byType(TextFormField).at(1), '11999998888');
    await tester.enterText(find.byType(TextFormField).at(2), 'Fulano Dono');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'fulano@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), 'senhaforte1');

    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Proprietario'), findsOneWidget);
    expect(find.text('MRR previsto'), findsOneWidget);
  });

  testWidgets('proprietario cadastra servico no catalogo pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catalogo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cadastrar servico'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Manicure');
    await tester.enterText(find.byType(TextFormField).at(1), '40');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Servico Manicure cadastrado.'), findsOneWidget);
  });

  testWidgets(
    'proprietario cadastra profissional com servicos habilitados pela API',
    (tester) async {
      await pumpMobileApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Catalogo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profissionais'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cadastrar profissional'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Bruna Lima');
      await tester.tap(find.widgetWithText(FilterChip, 'Corte masculino'));
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Profissional Bruna Lima cadastrado.'), findsOneWidget);
    },
  );

  testWidgets(
    'proprietario cria plano com profissionais habilitados pela API',
    (tester) async {
      await pumpMobileApp(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Gestor'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar plano de assinatura'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Diamante');
      await tester.enterText(find.byType(TextFormField).at(1), '250,00');

      expect(find.text('Profissionais habilitados'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Ana Souza'));

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Plano Diamante criado.'), findsOneWidget);
    },
  );

  testWidgets('cliente troca de plano pela API', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plano Bronze'));
    await tester.pumpAndSettle();
    expect(find.text('Minha assinatura'), findsOneWidget);

    await tester.tap(find.text('Trocar de plano'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher plano'), findsOneWidget);

    await tester.tap(find.text('Prata'));
    await tester.pumpAndSettle();
    expect(find.text('Plano Prata ativado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Minha assinatura'), findsOneWidget);
  });

  testWidgets('cliente cancela um agendamento pela API', (tester) async {
    await pumpMobileApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cliente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus agendamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Corte masculino'), findsOneWidget);

    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Cancelar agendamento'),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(FilledButton, 'Cancelar agendamento'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agendamento cancelado'), findsOneWidget);

    await tester.tap(find.text('Voltar para a agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Meus agendamentos'), findsOneWidget);
  });
}
