# Clube do Salão — App Mobile

App **Flutter mobile-only** (Android/iOS) do Clube do Salão: um SaaS multi-tenant de gestão por **assinatura mensal** para barbearias, salões de beleza, clínicas de estética, estúdios de unhas/sobrancelhas, spas e negócios similares. Não existe painel web administrativo — toda a operação (dono, profissional, cliente e administrador da plataforma) acontece dentro deste único app, que troca as telas conforme o papel do usuário logado.

Faz parte de um monorepo maior:

```
PROJETO_BARBEARIA/
├── backend/    # API Laravel 12 (PHP 8.3), Sanctum, multi-tenant, MySQL
├── landing/    # Site institucional (PHP)
├── mobile/     # Este app Flutter
└── store_assets/
```

## Stack de desenvolvimento

- **Framework:** Flutter / Dart `^3.11.4`
- **Gerenciamento de estado:** nenhum pacote externo — `ChangeNotifier` + `ListenableBuilder`/`setState`. A peça central é `AuthSession` (`lib/services/auth_session.dart`), instanciada uma vez em `main.dart` e injetada manualmente via construtor nas páginas (sem `Provider`/`Riverpod`/`Bloc`/`GetX`).
- **Navegação:** `Navigator` 1.0 padrão (`MaterialPageRoute`), sem `go_router`. O roteamento de topo é um `switch` sobre o `AuthStatus`/papel do usuário em `main.dart`, que decide entre splash, onboarding, `LoginPage` ou `DashboardShell` (com abas variando por papel).
- **HTTP/API:** pacote `http`, encapsulado em `ApiClient` (`lib/services/api_client.dart`) — timeout de 15s, tratamento de erros de validação do Laravel, variantes `postQueueable`/`patchQueueable` que enfileiram a mutação offline em caso de falha de rede. Acima do `ApiClient` há uma camada de *repositories* (um por entidade: `ClientsRepository`, `AppointmentsRepository`, `PaymentsRepository`, `SubscriptionPlansRepository`, `ProfessionalsRepository`, `TenantRepository`, `SaasSubscriptionRepository`, `ServicesRepository`, `WaitlistRepository`, `ClientSubscriptionsRepository`, `OnboardingRepository`, `AdminRepository`, `DashboardRepository`).
- **Backend:** API própria em Laravel 12 (`../backend`), autenticação via Sanctum (token Bearer), multi-tenant por `tenant_id`. Base URL resolvida automaticamente por ambiente (`ApiClient.baseUrl`): produção `https://app.clubedosalaoapp.com.br/api`, emulador Android `http://10.0.2.2:8000/api`, demais debug/desktop/web `http://localhost:8000/api`, ou override via `--dart-define=API_BASE_URL=...`.
- **Armazenamento local:**
  - `flutter_secure_storage` — token de autenticação e checklist de onboarding.
  - `sqflite` — banco `clube_do_salao_offline.db` com tabelas `queued_mutations` (fila de mutações offline) e `response_cache` (cache de respostas `GET`); há implementações "noop" para Web, onde `sqflite` não roda.
- **Offline-first:** `connectivity_plus` monitora a conexão; mutações (`POST`/`PATCH`) feitas offline são enfileiradas e reenviadas quando a conexão volta; leituras usam cache de resposta.
- **Outros pacotes:** `qr_flutter` e `share_plus` (QR/link de convite de cliente), `app_links` (deep link `clubedosalao://convite/{codigo}`), `flutter_localizations` (pt-BR).
- **Testes:** `flutter_test` com suíte ampla em `test/` — fluxos mock, onboarding, configurações de conta, timeline do dia, fila de mutações offline, cache de resposta, além de **golden tests** de layout (`layout_golden_test.dart`, imagens em `test/goldens/`). `flutter analyze` e `flutter test` devem passar antes de qualquer entrega.
- **Plataformas:** Android e iOS são o foco real; Web/Windows/Linux/macOS estão escaffoldados mas com funcionalidades degradadas (sem fila offline real).

### Arquitetura de pastas (`lib/`)

Separação por camada técnica (não é feature-first nem Clean Architecture formal):

```
lib/
├── main.dart          # bootstrap, tema, roteamento por papel, DashboardShell
├── core/               # exceptions, transações de estado local, error reporting
├── models/             # ~19 DTOs (fromJson), sem lógica de persistência
├── pages/              # telas agrupadas por papel/fluxo (owner, professional, customer, admin, onboarding...)
├── services/            # repositories (1 por entidade) + auth/token
│   └── offline/         # fila de mutações, cache de resposta, monitor de conectividade
├── support/             # tipos de negócio (barbershop, beauty_salon, aesthetic_clinic...)
└── widgets/             # design system interno (AppScaffold, AppHeroMetric, AppActionTile...)
```

Interfaces abstratas (`TokenStorage`, `ConnectivityMonitor`, `MutationQueueStorage`, `ResponseCache`) têm implementação real e implementação fake/noop, permitindo testar sem platform channels.

## Regras de negócio

### Papéis de usuário (um único app, quatro papéis)

| Papel | Foco | Abas principais |
|---|---|---|
| **Owner (Dono)** | Cadastra estabelecimento, profissionais, serviços e planos; acompanha financeiro; gerencia assinaturas de clientes | Início, Agenda, Catálogo, Planos, Clientes |
| **Professional (Profissional)** | Vê a própria agenda e disponibilidade, confirma atendimentos, acompanha comissão | Hoje, Agenda, Perfil |
| **Customer (Cliente)** | Assina plano, agenda/cancela horário, acompanha histórico e pagamentos | Clube, Agendar, Pagamentos, Perfil |
| **Admin (Plataforma)** | Visão global de todos os estabelecimentos, sem pertencer a um salão específico | Início, Salões |

### Duas camadas de "assinatura" (não confundir)

1. **Assinatura SaaS** (`SaasSubscriptionModel`) — o **estabelecimento** pagando pelo uso do sistema.
2. **Assinatura de cliente** (`ClientSubscriptionModel`) — o **cliente final** pagando o estabelecimento por um plano de serviços.

### Planos SaaS (o estabelecimento contrata)

| Plano | Preço | Profissionais | Assinantes ativos | Unidades |
|---|---|---|---|---|
| Trial (30 dias, sem cartão) | grátis | até 3 | até 20 | 1 |
| Básico | R$ 79,99/mês | até 3 | até 100 | 1 |
| Intermediário | R$ 129,99/mês | até 8 | até 400 | 1 |
| Premium | R$ 199,99/mês | ilimitado | ilimitado | ilimitado |

- O Trial libera recursos do Premium com limites reduzidos, como estratégia de conversão.
- **Downgrade nunca bloqueia**: registros mais antigos dentro do novo limite continuam ativos; excedentes ficam **inativos**, nunca são removidos automaticamente — o dono decide manualmente o que desativar.
- Selo "Salão Fundador" (`Tenant.isFounder`), concedido manualmente por um admin, suprime avisos de trial vencendo.

### Planos de assinatura do cliente (núcleo do produto)

Cada plano (`SubscriptionPlanModel`) define:
- `usageLimit` — limite de usos mensais (`null` = ilimitado).
- `allowedWeekdays` + faixa de horário (`allowedStartTime`/`allowedEndTime`) em que o plano pode ser usado.
- Serviços inclusos, cada um com quantidade incluída e percentual de desconto (`PlanServiceModel`).
- Profissionais habilitados a atender assinantes do plano.
- `isActive` — o dono pode ativar/desativar o plano sem excluí-lo.
- Uso é contado **por mês calendário** (`usagesThisMonth()`), mesma convenção do backend.
- Inadimplência (`paymentStatus: overdue`) ou plano vencido bloqueia automaticamente novo agendamento/uso.

### Agendamentos (`AppointmentModel`)

- Verificação automática de conflito de horário por profissional, respeitando o horário de trabalho individual de cada profissional por dia da semana.
- Pode ou não estar vinculado a uma assinatura de cliente (`clientSubscriptionId` nulo = agendamento avulso, cobrado pelo preço de catálogo do serviço).
- Dono/profissional pode agendar manualmente em nome de um cliente.
- Cancelamento com motivo (`cancellationReason`); status `canceled`/`no_show` não contam para a receita prevista do dia (`countsTowardExpectedRevenue`).

### Fila de espera (`WaitlistEntryModel`)

Pedido de atendimento no estabelecimento feito por cliente **sem** assinatura, sem profissional/horário fixo escolhido. O dono/profissional atribui manualmente uma vaga, convertendo o pedido em agendamento avulso normal.

### Pagamentos (`PaymentModel`)

- 100% **manuais** dentro do app (sem gateway de pagamento integrado): PIX, cartão de crédito, cartão de débito, dinheiro, fiado, outro.
- `isAvulso` distingue pagamento de agendamento sem plano vs. mensalidade de plano.
- Suporta pagamento **parcial**, com múltiplos recebimentos (`receipts`) e cálculo de saldo restante (`remainingCents`).

### Profissionais, serviços e clientes

- **Profissional** (`ProfessionalModel`): comissão percentual (editável só pelo dono), serviços que pode executar, horários de trabalho por dia da semana.
- **Serviço** (`ServiceModel`): nome, duração, preço, ativo/inativo.
- **Cliente** (`ClientModel`): dados de contato, status, assinaturas.

### Estabelecimento (`TenantModel`)

Nome, tipo de negócio (`barbershop`, `beauty_salon`, `aesthetic_clinic`, `nails`, `brows_lashes`, `spa`, `other`), horário de funcionamento e pausa, dia de pagamento dos profissionais (padrão dia 5), código de convite (link/QR para autocadastro de clientes) e assinatura SaaS vigente.

### Painel Inteligente do Proprietário

Analytics dedicados: agendamentos do dia por status, receita esperada hoje, receita recorrente e avulsa do mês, débito em aberto, risco de não-retorno de cliente, ocupação de agenda por profissional/dia, desempenho por profissional (bruto, comissão, adiantamentos, líquido).

### Administração da plataforma

Visão global para o admin: total de tenants (ativos, em trial, expirados, fundadores), receita projetada, total de usuários, e detalhe de cada estabelecimento.

### Fora de escopo no MVP

- Painel web administrativo (deliberadamente — tudo é mobile).
- Integração com WhatsApp API e Google Calendar.
- Gateways de pagamento automatizados (cobrança recorrente via Asaas está prevista no backend, mas ainda não implementada no app; hoje todo pagamento é confirmado manualmente).
- Fidelidade/pontos, avaliações pós-atendimento, controle de estoque, marketing automation, BI avançado e IA — descritos na especificação de produto e no roadmap (fases 6 a 10), mas ainda **não implementados** no código.

> Regras de negócio detalhadas: ver `clube-do-salao-especificacao-produto.md`. Status de desenvolvimento por fase: ver `roadmap.md`.

## Rodando o projeto

```bash
flutter pub get
flutter run
```

Para apontar para um backend em outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_HOST:8000/api
```

Rodar os testes:

```bash
flutter analyze
flutter test
```
