import 'package:clube_do_salao/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';

/// Publico da central de ajuda: cada papel ve um roteiro diferente das
/// principais tarefas do app, sem depender do enum `UserRole` (definido em
/// `main.dart`) para nao criar import cruzado.
enum HelpAudience { owner, professional, customer }

/// Tela estatica de referencia, acessivel a qualquer momento pelo icone de
/// ajuda na barra superior (nao so durante o onboarding). Publico-alvo tem
/// baixa familiaridade com tecnologia, entao o conteudo fica em passos
/// curtos e na ordem em que costumam ser feitos.
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key, required this.audience});

  final HelpAudience audience;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Central de ajuda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: switch (audience) {
          HelpAudience.owner => _ownerSections,
          HelpAudience.professional => _professionalSections,
          HelpAudience.customer => _customerSections,
        },
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title),
          Card(
            child: Column(
              children: [
                for (final step in steps)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(step),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _ownerSections = [
  _HelpSection(
    title: 'Para começar',
    steps: [
      'Cadastre os serviços do seu salão em "Catálogo > Serviços" (nome, duração e preço).',
      'Cadastre os profissionais em "Catálogo > Profissionais" e escolha quais serviços cada um realiza.',
      'Crie um plano de assinatura em "Criar plano de assinatura", escolhendo os serviços e profissionais liberados para quem assinar.',
      'Compartilhe o código ou QR de convite em "Convidar clientes" para os clientes se cadastrarem sozinhos.',
    ],
  ),
  _HelpSection(
    title: 'No dia a dia',
    steps: [
      'Acompanhe a agenda do salão na aba "Agenda".',
      'Confirme pagamentos manuais (PIX, cartão, dinheiro ou fiado) em "Confirmar pagamento manual".',
      'Acompanhe saldos de fiado em aberto em "Gestão do fiado".',
      'Veja produção e comissão dos profissionais em "Comissões profissionais".',
      'Atenda quem está na fila de espera direto pelo botão "Fila de espera" na Agenda.',
    ],
  ),
  _HelpSection(
    title: 'Sua assinatura do Clube do Salão',
    steps: [
      'Acompanhe seu trial ou plano contratado do próprio app em "Meu plano".',
      'Altere seu e-mail ou senha de acesso em "Meus dados de acesso".',
    ],
  ),
];

const _professionalSections = [
  _HelpSection(
    title: 'Para começar',
    steps: [
      'Veja seus atendimentos do dia na aba "Hoje".',
      'Consulte sua agenda completa na aba "Agenda".',
      'Edite sua especialidade e telefone na aba "Perfil".',
    ],
  ),
  _HelpSection(
    title: 'No dia a dia',
    steps: [
      'Acompanhe atendimentos realizados, comissão prevista e adiantamentos na aba "Perfil".',
    ],
  ),
];

const _customerSections = [
  _HelpSection(
    title: 'Para começar',
    steps: [
      'Escolha um plano de assinatura do salão na aba "Clube".',
      'Agende, cancele ou remarque horários na aba "Agendar".',
      'Sem assinatura? Peça um atendimento avulso ou entre na fila de espera pela aba "Agendar".',
    ],
  ),
  _HelpSection(
    title: 'No dia a dia',
    steps: [
      'Acompanhe pagamentos pendentes e já efetuados na aba "Pagamentos".',
      'Veja plano atual e histórico de atendimentos na aba "Perfil".',
    ],
  ),
];
