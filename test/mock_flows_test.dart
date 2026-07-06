import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testWidgets('proprietario cadastra cliente pela API', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Cadastrar cliente');
    await tester.tap(find.text('Cadastrar cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar cliente'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Souza');
    await tester.enterText(find.byType(TextFormField).at(1), '11999990000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente Ana Souza cadastrado.'), findsOneWidget);
    expect(find.text('Próximas ações'), findsOneWidget);
  });

  testWidgets('proprietario confirma um pagamento pendente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Confirmar pagamento manual');

    await tester.tap(find.text('Confirmar pagamento manual'));
    await tester.pumpAndSettle();

    expect(find.text('Joao Ribeiro'), findsOneWidget);

    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    expect(find.text('PIX'), findsWidgets);
    expect(find.text('Cartão crédito'), findsOneWidget);
    expect(find.text('Cartão débito'), findsOneWidget);
    expect(find.text('Dinheiro'), findsOneWidget);
    expect(find.text('Fiado'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pagamento pendente.'), findsOneWidget);
  });

  testWidgets('proprietario registra pagamento como fiado', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Confirmar pagamento manual');

    await tester.tap(find.text('Confirmar pagamento manual'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Fiado'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento registrado como fiado.'), findsOneWidget);
    expect(find.text('Joao Ribeiro'), findsOneWidget);
  });

  testWidgets('proprietario lanca recebimento parcial de fiado', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Gestão do fiado');

    await tester.tap(find.text('Gestão do fiado'));
    await tester.pumpAndSettle();

    expect(find.text('Total em aberto'), findsOneWidget);
    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '50,00');
    await tester.tap(find.widgetWithText(FilledButton, 'Lancar recebimento'));
    await tester.pumpAndSettle();

    expect(find.text('Recebimento lancado.'), findsOneWidget);
  });

  testWidgets('proprietario consulta comissao e adiantamento profissional', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await scrollToText(tester, 'Comissoes profissionais');

    await tester.tap(find.text('Comissoes profissionais'));
    await tester.pumpAndSettle();

    expect(find.text('Dia 5'), findsOneWidget);
    await tester.tap(find.text('Ana Souza'));
    await tester.pumpAndSettle();

    expect(find.text('A receber'), findsOneWidget);
    expect(find.text('R\$ 114,00'), findsOneWidget);
    expect(find.text('Adiantamento'), findsOneWidget);
  });

  testWidgets('profissional conclui atendimento pela API', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do atendimento'), findsOneWidget);

    await tester.tap(find.text('Concluir atendimento'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimento concluído'), findsOneWidget);

    await tester.tap(find.text('Voltar para a agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimentos de hoje'), findsOneWidget);
  });

  testWidgets('cliente percorre o fluxo completo de agendamento pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher serviço'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher profissional'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar horário'), findsOneWidget);

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

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sou dono de salão'));
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

    expect(find.text('Proprietário'), findsOneWidget);
    expect(find.text('MRR previsto'), findsOneWidget);
  });

  testWidgets('proprietario cadastra servico no catalogo pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Catalogo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cadastrar serviço'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Manicure');
    await tester.enterText(find.byType(TextFormField).at(1), '40');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Serviço Manicure cadastrado.'), findsOneWidget);
  });

  testWidgets(
    'proprietario cadastra profissional com servicos habilitados pela API',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

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

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await scrollToText(tester, 'Criar plano de assinatura');

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

  testWidgets('proprietario edita um plano existente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Planos'));
    await tester.pumpAndSettle();

    expect(find.text('Bronze'), findsOneWidget);
    await tester.tap(find.text('Bronze'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Bronze'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '119,90');
    await scrollToText(tester, 'Salvar');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Plano atualizado.'), findsOneWidget);
  });

  testWidgets('proprietario edita um servico existente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Catalogo'));
    await tester.pumpAndSettle();

    expect(find.text('Corte masculino'), findsOneWidget);
    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Corte masculino'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), '65,00');
    await scrollToText(tester, 'Salvar');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Serviço atualizado.'), findsOneWidget);
  });

  testWidgets('proprietario edita um cliente existente pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();

    expect(find.text('Joao Ribeiro'), findsOneWidget);
    await tester.tap(find.text('Joao Ribeiro'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Joao Ribeiro'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '11966665555');
    await scrollToText(tester, 'Salvar');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Cliente atualizado.'), findsOneWidget);
  });

  testWidgets('cliente troca de plano pela API', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Plano Bronze'));
    await tester.pumpAndSettle();
    expect(find.text('Minha assinatura'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Pagamento em dia'), findsOneWidget);
    expect(find.text('R\$ 99,90'), findsOneWidget);

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

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

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

    await tester.tap(find.widgetWithText(FilledButton, 'Cancelar agendamento'));
    await tester.pumpAndSettle();

    expect(find.text('Agendamento cancelado'), findsOneWidget);

    await tester.tap(find.text('Voltar para a agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Meus agendamentos'), findsOneWidget);
  });

  testWidgets('cliente entra na fila de espera e sai dela pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fila de espera'));
    await tester.pumpAndSettle();
    expect(find.text('Corte masculino'), findsOneWidget);

    await tester.tap(find.byTooltip('Entrar na fila'));
    await tester.pumpAndSettle();
    expect(find.text('Serviço desejado'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar na fila'));
    await tester.pumpAndSettle();
    expect(find.text('Você entrou na fila'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.text('Fila de espera'), findsWidgets);

    await tester.tap(find.byTooltip('Sair da fila'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair da fila'));
    await tester.pumpAndSettle();

    expect(find.text('Fila de espera'), findsWidgets);
  });

  testWidgets('dono atribui horario da fila de espera pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fila de espera'));
    await tester.pumpAndSettle();
    expect(find.text('Carlos Mendes'), findsOneWidget);

    await tester.tap(find.text('Carlos Mendes'));
    await tester.pumpAndSettle();
    expect(find.text('Escolher profissional'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Atribuir horário'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimento agendado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Fila de espera'), findsWidgets);
  });

  testWidgets('dono cria agendamento manual para um cliente', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo agendamento'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Novo agendamento'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher serviço'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher profissional'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmar horário'), findsOneWidget);
    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();

    expect(find.text('Agendamento confirmado'), findsWidgets);
  });

  testWidgets('dono coloca cliente manualmente na fila de espera', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fila de espera'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Colocar cliente na fila'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AppBar, 'Colocar cliente na fila'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Colocar na fila'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendes entrou na fila de espera.'), findsOneWidget);
  });

  testWidgets('proprietario troca de plano SaaS pela API', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Meu plano'));
    await tester.pumpAndSettle();

    expect(find.text('Planos disponíveis'), findsOneWidget);
    expect(find.text('Plano atual'), findsOneWidget);

    await tester.tap(find.text('Basico'));
    await tester.pumpAndSettle();

    expect(find.text('Plano Basico ativado'), findsOneWidget);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    expect(find.text('Meu plano'), findsWidgets);
  });
}
