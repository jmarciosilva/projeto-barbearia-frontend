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

    await scrollToTop(tester);
    await scrollToText(tester, 'Próximas ações');
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

  testWidgets(
    'dono ve o card de fiado em aberto no dashboard e abre a lista de devedores',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await scrollToText(tester, 'Fiado em aberto');
      expect(find.text('R\$ 149,90'), findsOneWidget);

      await tester.tap(find.text('Fiado em aberto'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Gestão do fiado'), findsOneWidget);
      expect(find.text('Joao Ribeiro'), findsOneWidget);
    },
  );

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

  testWidgets(
    'dono confirma pagamento logo apos concluir atendimento avulso',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Corte masculino'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhe do atendimento'), findsOneWidget);

      await tester.tap(find.text('Concluir atendimento'));
      await tester.pumpAndSettle();

      expect(find.text('Atendimento concluído'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Confirmar pagamento'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
      await tester.pumpAndSettle();

      expect(find.text('Pagamento confirmado'), findsOneWidget);

      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();

      // Pagamento confirmado tambem fecha a tela de detalhe do atendimento,
      // voltando direto pra Agenda (fluxo fluido pedido pelo usuario).
      expect(find.text('Pagamento confirmado'), findsNothing);
      expect(find.text('Detalhe do atendimento'), findsNothing);
    },
  );

  testWidgets(
    'dono registra pagamento como fiado logo apos concluir atendimento avulso',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Corte masculino'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhe do atendimento'), findsOneWidget);

      await tester.tap(find.text('Concluir atendimento'));
      await tester.pumpAndSettle();

      expect(find.text('Atendimento concluído'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Confirmar pagamento'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Fiado'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
      await tester.pumpAndSettle();

      // Fiado tambem e um desfecho valido do pagamento: deve fechar a tela
      // de detalhe do atendimento e voltar direto pra Agenda, igual ao
      // fluxo de pagamento a vista (bug reportado pelo usuario).
      expect(find.text('Pagamento registrado como fiado.'), findsOneWidget);
      expect(find.text('Detalhe do atendimento'), findsNothing);
    },
  );

  testWidgets('profissional conclui atendimento pela API', (tester) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Corte masculino'));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do atendimento'), findsOneWidget);

    await tester.tap(find.text('Concluir atendimento'));
    await tester.pumpAndSettle();

    expect(find.text('Atendimento concluído'), findsOneWidget);
    // Confirmar pagamento e exclusivo do dono (POST /payments/{id}/mark-paid
    // e role:owner no backend); profissional nunca deve ver esse atalho.
    expect(find.text('Confirmar pagamento'), findsNothing);

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

    await scrollToText(tester, 'Iniciar agendamento');
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

  testWidgets(
    'horario individual do profissional prevalece sobre o horario do salao',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

      await tester.tap(find.text('Agendar'));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Iniciar agendamento');
      await tester.tap(find.text('Iniciar agendamento'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Escolher profissional'), findsOneWidget);

      // Ana Souza (profissional padrao selecionado) tem horario cadastrado
      // ate as 23:00; o horario do salao na fixture nao tem nada
      // configurado (cairia na lista legada, que vai so ate as 17:30).
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar horário'), findsOneWidget);

      // Amanha, pra nao depender do horario em que o teste roda (a lista
      // filtra horarios ja passados so no dia de hoje).
      await tester.tap(find.text('Amanhã'));
      await tester.pumpAndSettle();

      expect(find.text('20:00'), findsOneWidget);
    },
  );

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

    expect(find.text('Proprietário • Fulano'), findsOneWidget);
    expect(find.text('Recorrente do mês'), findsOneWidget);
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
      await scrollToText(tester, 'Salvar');
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

  testWidgets('dono registra pagamento de assinatura pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carlos Mendes'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Registrar pagamento');
    await tester.tap(find.text('Registrar pagamento'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Confirmar pagamento'), findsOneWidget);
    expect(find.text('R\$ 99,90'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);
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

  testWidgets('cliente ve a agenda do salao sem nome de outro cliente', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agenda do salão'));
    await tester.pumpAndSettle();

    expect(find.text('Corte masculino'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Carlos Mendes'), findsNothing);
  });

  testWidgets('cliente atualiza os proprios dados pessoais pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'carlos.mendes@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendes'), findsOneWidget);
    expect(find.text('11988881234'), findsOneWidget);

    await tester.tap(find.text('Editar dados pessoais'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendes'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '11977776666');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Dados atualizados.'), findsOneWidget);

    await tester.tap(find.text('Meus dados de acesso'));
    await tester.pumpAndSettle();

    expect(find.text('Meus dados de acesso'), findsWidgets);
    expect(find.text('Confirme sua senha atual para alterar o e-mail e/ou a senha de acesso ao app.'), findsOneWidget);
  });

  testWidgets('profissional atualiza os proprios dados de perfil pela API', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Editar perfil');
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Ana Souza'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), '11977776666');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil atualizado.'), findsOneWidget);

    await scrollToText(tester, 'Meus dados de acesso');
    await tester.tap(find.text('Meus dados de acesso'));
    await tester.pumpAndSettle();

    expect(find.text('Meus dados de acesso'), findsWidgets);
    expect(find.text('Confirme sua senha atual para alterar o e-mail e/ou a senha de acesso ao app.'), findsOneWidget);
  });

  testWidgets(
    'profissional abre o detalhe dos cards de atendimentos do mes',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

      await tester.tap(find.text('Atendimentos'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Atendimentos do mês'), findsOneWidget);
      expect(find.text('6 atendimentos'), findsOneWidget);
      expect(find.text('Carlos Mendes'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Avulso'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Atendimentos avulsos do mês'),
        findsOneWidget,
      );
      expect(find.text('4 atendimentos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assinatura'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Atendimentos por assinatura do mês'),
        findsOneWidget,
      );
      expect(find.text('2 atendimentos'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Receita gerada'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Receita gerada no mês'), findsOneWidget);
      expect(find.text('R\$ 360,00'), findsOneWidget);
    },
  );

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

    await scrollToText(tester, 'Meu plano');
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

  testWidgets(
    'proprietario abre o extrato de receita prevista hoje e avulsa do mes',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await tester.tap(find.text('Prevista hoje'));
      await tester.pumpAndSettle();

      expect(find.text('Receita prevista hoje'), findsOneWidget);
      expect(find.text('Carlos Mendes'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await scrollToText(tester, 'Avulsa do mês');
      await tester.tap(find.text('Avulsa do mês'));
      await tester.pumpAndSettle();

      expect(find.text('Receita avulsa do mês'), findsOneWidget);
      expect(find.text('Nenhuma receita avulsa confirmada este mês.'), findsOneWidget);
    },
  );

  testWidgets('profissional registra ajuste de horario de um dia', (
    tester,
  ) async {
    await pumpMobileApp(tester);

    await loginAs(tester, email: 'ana.souza@clubedosalao.com', password: 'demo12345');

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    await scrollToText(tester, 'Ajuste de horário');
    await tester.tap(find.text('Ajuste de horário'));
    await tester.pumpAndSettle();

    expect(find.text('Das 10:00 às 18:00'), findsOneWidget);

    await tester.tap(find.text('Registrar ajuste de horário'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar ajuste'));
    await tester.pumpAndSettle();

    expect(find.text('Ajuste de horário'), findsWidgets);
  });

  testWidgets(
    'proprietario ajusta horario do profissional pela tela de ocupacao',
    (tester) async {
      await pumpMobileApp(tester);

      await loginAs(tester, email: 'owner@clubedosalao.com', password: 'demo12345');

      await scrollToText(tester, 'Ocupação da equipe');
      await tester.tap(find.text('Ocupação da equipe'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Souza'), findsOneWidget);

      await tester.tap(find.text('Ana Souza'));
      await tester.pumpAndSettle();

      expect(find.text('Horário de trabalho'), findsOneWidget);
    },
  );
}
