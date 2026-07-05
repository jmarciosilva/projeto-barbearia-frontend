# Roadmap de Desenvolvimento - Mobile

Este documento guia e audita a evolucao do app Flutter do Clube do Salao. Toda fase deve ser marcada aqui com status, telas entregues, testes executados, pendencias e decisao de continuidade.

Fonte da verdade de produto: `clube-do-salao-especificacao-produto.md`. Toda fase nova ou revisada deve referenciar a secao correspondente da especificacao.

## Legenda de status

- `Nao iniciado`: ainda nao entrou em desenvolvimento.
- `Em andamento`: fase ou item em implementacao.
- `Em auditoria`: implementacao concluida, aguardando revisao tecnica/funcional.
- `Aprovado`: criterios de aceite atendidos.
- `Bloqueado`: impedimento externo ou decisao pendente.

## Regras de auditoria

- Nenhuma fase deve ser aprovada sem `flutter analyze` e `flutter test`.
- Telas novas devem respeitar os tres perfis quando aplicavel: proprietario/gerente, profissional e cliente.
- Fluxos criticos devem ser validados em mobile antes de novas features.
- Integracoes com API devem registrar endpoint, estado de loading, erro e sucesso.

## Fase 0 - Fundacao e Validacao

Status: `Em auditoria`

Objetivo: entregar app unico para proprietario/gerente, profissional e cliente, validando recorrencia, agenda, atendimento avulso e pagamento manual.

### Escopo mobile

- [x] Setup Flutter
- [x] App unico
- [x] Navegacao inicial por perfil
- [x] Dashboard inicial do proprietario
- [x] Visao inicial do profissional
- [x] Visao inicial do cliente
- [x] Abas de agenda, planos e clientes
- [x] Smoke test inicial de widget
- [x] Comentarios de manutencao em portugues do Brasil
- [x] Tratamento global de excecoes do aplicativo
- [x] Commit e rollback para alteracoes locais de estado
- [x] Testes visuais por golden file em viewport mobile
- [x] Correcao de overflow nos cards de metricas do proprietario
- [x] Autenticacao real com API
- [x] Persistencia de token
- [x] Onboarding de estabelecimento
- [x] Cadastro de profissionais
- [x] Cadastro de servicos
- [x] Servicos habilitados por profissional (spec 4.1: restricao de quem executa cada servico)
- [x] Cadastro de clientes
- [x] Criacao de planos
- [x] Profissionais habilitados por plano (spec 4.2: restricao de quem atende assinantes de cada plano)
- [x] Contratacao/troca de assinatura pelo proprio cliente
- [x] Agenda com dados reais para proprietario e profissional (profissional auto-escopado a propria agenda pela API)
- [x] Autoedicao de perfil do profissional (especialidade/telefone; comissao continua exclusiva do proprietario)
- [x] Agendamento real pelo cliente (com validacao das regras do plano: dia, horario, limite de uso, conflito)
- [x] Cancelamento e remarcacao de agendamento
- [x] Confirmacao manual de pagamento
- [x] Estados de loading, vazio e erro
- [x] Agendamento avulso pelo cliente sem assinatura ativa: escolhe profissional e horario especificos (mesmo fluxo de agendamento de hoje, sem vinculo a plano) e paga o preco de catalogo do servico via confirmacao manual de pagamento (reaproveita a tela ja existente)
- [x] Fila de espera para atendimento no estabelecimento: cliente sem assinatura pede para ser atendido "quando tiver vaga", sem escolher profissional nem horario
- [x] Tela do dono/profissional para visualizar a fila de espera e atribuir manualmente um horario vago a um cliente da fila, virando um agendamento avulso normal (com cobranca)

### Criterios de aceite

- [x] `flutter analyze` executa sem erros
- [x] `flutter test` executa sem erros
- [x] Teste automatizado cobre commit e rollback de estado local
- [x] Teste automatizado cobre troca de perfil antes do dashboard
- [x] Golden tests cobrem entrada, proprietario, profissional e cliente
- [x] Login funcional com token Sanctum
- [x] Proprietario consegue cadastrar cliente, servico, profissional e plano
- [x] Cliente consegue solicitar agendamento permitido pelo plano
- [x] Profissional consegue visualizar agenda do dia
- [x] App validado em Android
- [ ] App validado em iOS ou simulador iOS quando disponivel
- [x] Cliente sem assinatura consegue solicitar e pagar um agendamento avulso com profissional e horario especificos
- [x] Cliente sem assinatura consegue entrar na fila de espera do estabelecimento sem escolher profissional/horario
- [x] Dono/profissional consegue ver a fila de espera e transformar um cliente da fila em agendamento avulso ao ter um horario livre

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-03 | Codex | Parcial aprovado | `flutter analyze` e `flutter test` passaram | Integrar API, autenticar, persistir token e implementar fluxos reais |
| 2026-07-03 | Codex | Parcial aprovado | Handler global de excecoes, transacao local de estado, comentarios em PT-BR e testes passaram | Ainda falta aplicar o padrao nos fluxos reais quando a API for integrada |
| 2026-07-03 | Codex | Parcial aprovado | Golden tests em 390x844 passaram e overflow dos cards de metricas foi corrigido | Testar em dispositivo Android real quando o SDK estiver configurado |
| 2026-07-03 | Claude | Parcial aprovado | Login real com Sanctum + persistencia de token (`flutter_secure_storage`); `RoleGatePage` virou tela de login (com atalhos para as 3 contas de demo do seed); proprietario 100% real (metricas, agenda, planos, clientes, pagamentos) contra a API real, com loading/erro/vazio em cada tela; validado ponta a ponta no emulador Android contra o backend real — pagamento confirmado pelo app apareceu no banco com o `paid_at` correto; `flutter analyze` limpo e 15/15 testes passando (nova suite usa `MockClient` para simular o backend, sem depender de servidor real nem platform channels) | Profissional e cliente continuam mockados (proxima etapa); sem cadastro de profissional/servico nem contratacao de assinatura pelo app; iOS nao testado |
| 2026-07-03 | Claude | Parcial aprovado | Profissional e cliente ligados a API real: backend ganhou `GET /me/client`, `GET /me/professional`, `PATCH /me/professional` e `GET /appointments` auto-escopado por profissional (20/20 testes de backend); app mostra agenda real do profissional, autoedicao de perfil (sem comissao), assinatura/historico real do cliente e fluxo completo de agendamento contra a API; validado ponta a ponta no emulador — edicao de especialidade persistiu no banco, tentativa de agendar fora do dia permitido pelo plano retornou o erro real da API na tela, e um agendamento avulso valido foi aceito; `flutter analyze` limpo e 15/15 testes passando | Onboarding de estabelecimento, cadastro de profissional/servico e contratacao/troca de plano pelo cliente continuam sem tela no app; cancelamento/remarcacao de agendamento ainda nao existe; iOS nao testado |
| 2026-07-04 | Claude | Parcial aprovado | Fechados os itens restantes da Fase 0. Backend: `AppointmentController` passou a validar as restricoes de servico-por-profissional (spec 4.1) e profissional-por-plano (spec 4.2) na hora de agendar (antes so existiam no cadastro); `ProfessionalController::update` ganhou sync de `service_ids` sem apagar em updates parciais; `GET /appointments` e `GET /subscription-plans` passaram a aceitar o papel `customer` (escopado ao proprio cliente e a planos ativos, respectivamente) — sem isso o cliente nao tinha como listar planos pra assinar nem ver o proprio agendamento pra cancelar; 32/32 testes de backend passando (8 novos em `PhaseZeroBookingRestrictionsTest`). App: onboarding cria estabelecimento+dono via `POST /auth/register-owner` e loga direto; nova aba "Catalogo" (com sub-abas Servicos/Profissionais) para o dono cadastrar e editar catalogo, com selecao de servicos habilitados por profissional; `NewPlanPage` ganhou selecao de profissionais habilitados; cliente ganhou fluxo completo de assinar/trocar/cancelar plano (`ChoosePlanPage` + `ClientSubscriptionsRepository`) e tela "Meus agendamentos" para cancelar/remarcar os proprios horarios; dono/profissional ganharam cancelar/remarcar na tela de detalhe do atendimento existente; `flutter analyze` limpo e 21/21 testes passando (golden de login e do dashboard do proprietario atualizados para refletir a nova aba e o link de cadastro) | iOS/simulador iOS continua sem validacao — ambiente desta sessao nao tem Mac disponivel |
| 2026-07-04 | Claude | Aprovado | Validacao ponta a ponta em emulador Android real contra o backend real (nao mockado), cobrindo os fluxos novos da linha anterior: onboarding criou tenant+dono reais e autenticou direto; cadastro de servico e de profissional com servico habilitado persistiram e refletiram na edicao do profissional; plano criado com servico e profissional habilitados persistiu; cliente assinou o plano, tentou agendar com um profissional fora da lista do plano e recebeu o erro real da API ("Profissional nao atende este plano" — spec 4.2 confirmada em producao), agendou com o profissional correto, remarcou e cancelou o proprio agendamento pela tela "Meus agendamentos"; dono tambem remarcou e cancelou o mesmo tipo de agendamento pela agenda (mesma tela `AppointmentDetailPage`, com o botao extra "Concluir atendimento" visivel so para dono/profissional). Um bug real foi encontrado e corrigido nessa validacao: o bottom sheet de remarcacao (`AppointmentDetailPage._pickRescheduleSlot`) estourava a altura do modal e lancava uma excecao de overflow porque a lista de horarios usava `Column` dentro de um container de altura limitada; corrigido trocando para `ListView` (agora rola em vez de estourar), e reconfirmado sem overflow tanto na visao do cliente quanto na do dono apos a correcao. `flutter analyze` limpo e 21/21 testes passando apos a correcao | iOS/simulador iOS continua sem validacao — ambiente desta sessao nao tem Mac disponivel |
| 2026-07-04 | Claude | Parcial aprovado | Backend do agendamento avulso e da fila de espera implementado (mobile ainda pendente). `AppointmentController::store` agora cria automaticamente um `Payment` pendente (preco de catalogo do servico) sempre que o agendamento nao tem `client_subscription_id` e o servico tem `price_cents` — reaproveita a tela de confirmacao manual de pagamento ja existente, sem precisar de UI nova. Migration adicionou `client_id`/`appointment_id` (nullable) em `payments`; `PaymentController` passou a aceitar e derivar esses campos. Nova tabela/model `WaitlistEntry` e `WaitlistController` (`GET/POST /waitlist`, `PATCH /waitlist/{id}` para cancelar, `POST /waitlist/{id}/assign` exclusivo do staff) implementam a fila: cliente entra sem escolher profissional/horario, dono/profissional atribuem manualmente um horario livre — a atribuicao reaproveita as mesmas checagens de `POST /appointments` (restricao de servico por profissional e conflito de horario) via uma trait nova (`CreatesAppointments`) compartilhada entre os dois controllers. 9 testes novos em `PhaseZeroAvulsoAndWaitlistTest` (41/41 testes de backend passando); `docs/api.md` atualizado com as novas secoes e duas notas desatualizadas corrigidas (`GET /appointments` e `GET /subscription-plans` ja aceitavam `customer` desde a linha anterior, mas a doc ainda dizia que nao) | Telas do app (agendar avulso e entrar/ver fila) ainda nao existem; sem validacao em dispositivo real ainda |
| 2026-07-04 | Claude | Parcial aprovado | Concluido o lado do app para agendamento avulso e fila de espera. Agendamento avulso ja funcionava de graca no fluxo de agendamento existente (o app so envia `client_subscription_id` quando o cliente tem plano ativo); a tela de confirmacao final agora mostra o valor pendente de pagamento quando a API retorna um `payment` no agendamento avulso, e a lista de pagamentos pendentes do dono distingue avulso ("Servico - forma de pagamento") de assinatura. Fila de espera ganhou tela nova no cliente ("Fila de espera" na aba Agendar: `MyWaitlistPage` lista e cancela, `JoinWaitlistPage` so pede servico e observacao — sem profissional/horario, por definicao do produto) e no dono/profissional (FAB "Fila de espera" na Agenda compartilhada: `ManageWaitlistPage` lista quem esta aguardando, `AssignWaitlistPage` escolhe profissional quando a entrada nao tem preferencia e um horario fixo de hoje, chamando o `assign` do backend). Novo `WaitlistRepository`/`WaitlistEntryModel`; `PaymentModel`/`AppointmentModel` passaram a ler os campos novos da API. `flutter analyze` limpo e 23/23 testes passando (2 novos cenarios cobrindo entrar/sair da fila e o dono atribuir horario) | Fluxo de agendamento avulso com pagamento pendente nao foi exercitado por teste de widget dedicado (o mock de login sempre associa o cliente demo a uma assinatura ativa); nao validado em dispositivo real nesta sessao; iOS continua sem validacao |
| 2026-07-04 | Claude | Aprovado | Validacao ponta a ponta em emulador Android real contra o backend real, cobrindo agendamento avulso e fila de espera. Criado cliente sem assinatura ("Maria Avulsa"); agendou com profissional e horario especificos e a tela final mostrou "Agendamento avulso: R$ 60,00 pendentes de pagamento no salao" — confirmado no banco (`Payment` criado com `client_id`/`appointment_id` corretos); dono viu o item em "Pagamentos pendentes" com o rotulo do servico e confirmou o pagamento, refletindo `status=paid`. Cliente entrou na fila de espera (so servico + observacao, sem profissional/horario); dono viu a entrada com "Qualquer profissional", escolheu Ana QA e um horario livre (o padrao as 09:00 colidia com o agendamento avulso anterior, confirmando que o `assign` aplica a mesma checagem de conflito) — a entrada virou agendamento de verdade com pagamento avulso automatico, e a tela do cliente passou a mostrar "Atendimento marcado" com o profissional atribuido. Cliente tambem cancelou uma segunda entrada da fila, refletindo "Cancelado" apos recarregar. Nenhum bug encontrado; `flutter analyze` limpo, 23/23 testes do app e 41/41 do backend passando | iOS/simulador iOS continua sem validacao — ambiente desta sessao nao tem Mac disponivel |

## Fase 1 - Planos SaaS e Controle de Acesso

Status: `Em auditoria`

Objetivo: implementar o modelo de negocio do produto (especificacao, secao 3) — trial e os 3 tiers pagos do SaaS, com limites e liberacao de funcionalidade por plano. Sem esta fase o app nao tem como cobrar pelo proprio uso nem limitar/liberar recursos por tier, o que hoje bloqueia qualquer avanco comercial real.

### Escopo previsto

- [x] Cadastro de estabelecimento inicia trial de 30 dias sem cartao, liberando funcionalidades do Premium com limites reduzidos (ate 3 profissionais, ate 20 clientes assinantes, 1 unidade)
- [x] Selecao/upgrade de plano SaaS pelo proprietario: Basico (R$79,99), Intermediario (R$129,99), Premium (R$199,99)
- [x] `PlanGate` centralizado no backend (feature flags + limites por tier) espelhado no app: funcionalidade fora do plano aparece bloqueada com explicacao, nao apenas escondida
- [x] Limites por plano aplicados e visiveis (profissionais, clientes assinantes ativos, unidades/filiais)
- [x] Regra de downgrade (spec 3.5): registros excedentes ficam inativos, nunca removidos, ate o dono decidir ou fazer upgrade
- [ ] Multiplas unidades/filiais no mesmo painel (exclusivo do tier Premium) — decisao de escopo: nesta fase so o limite existe e fica visivel (`tenants.units_count`, sempre 1 hoje); nao ha CRUD de unidade nem nada operacional (agenda/clientes) escopado por unidade ainda
- [x] Aviso de fim de trial e bloqueio gracioso ao expirar sem upgrade

### Criterios de aceite

- [x] Tenant novo comeca em trial e ve a contagem regressiva dos 30 dias
- [x] Proprietario consegue trocar de plano SaaS pelo app
- [x] Funcionalidade fora do plano contratado fica bloqueada de forma visivel e compreensivel para usuario leigo
- [x] Downgrade nao apaga dados nem trava o proprietario em tela de erro sem explicacao

### Decisoes

| Data | Decisao | Motivo |
|---|---|---|
| 2026-07-04 | Multi-unidade fica so como limite numerico visivel nesta fase, sem CRUD nem funcionalidade operacional real | Nenhuma entidade de unidade/filial existia no banco; construir de verdade exigiria re-escopar agenda/clientes/profissionais por unidade, um esforco de fase propria. Confirmado com o usuario antes de implementar |
| 2026-07-04 | Trial vencido bloqueia toda escrita (POST/PATCH/PUT/DELETE) com HTTP 402 e mensagem clara; leitura nunca e afetada | Confirmado com o usuario: "bloqueio gracioso" significa nunca esconder dados nem travar em tela de erro sem explicacao, mas a escrita real so deve voltar quando o dono escolher um plano |
| 2026-07-04 | Troca de plano SaaS e efetiva na hora, sem cobranca real via gateway ainda | Gateway de pagamento fica para fase futura; nesta fase o objetivo e o modelo de dados/regras de negocio (limites, downgrade, bloqueio) |

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-03 | Claude | Nao iniciado | Auditoria da especificacao vs. roadmap encontrou a lacuna: backend hoje so tem uma tabela `saas_subscriptions` esqueleto (`plan_name` fixo "Plano Fundador", sem os 4 tiers, sem tabela de `plan_features`/limites) | Toda a fase — desenho de schema (`plan_features`), `PlanGate`, telas de trial/upgrade/downgrade no app |
| 2026-07-04 | Claude | Parcial aprovado | Backend: nova tabela de referencia `saas_plans` (trial/basico/intermediario/premium com preco e limites, seedada na propria migration) e `saas_subscriptions.saas_plan_id` linkando cada tenant ao seu tier; `SaasSubscription` ganhou atributos calculados (`effective_status`, `trial_days_remaining`, `limits`, `usage`) sempre embutidos em `GET /tenant`/login/`GET /me`; `PlanGate` (`app/Support/PlanGate.php`) centraliza contagem de uso, checagem de limite e a regra de downgrade (spec 3.5) — reaproveitada por `ProfessionalController::store` e `ClientSubscriptionController::store/subscribeSelf` pra rejeitar criacao acima do limite (422) e pela troca de plano pra desativar automaticamente o excedente mais novo (profissional vira `is_active:false`, assinatura de cliente vira `status:paused`) mantendo os registros mais antigos ativos, sem apagar nada; nova rota `GET /saas-plans` e `PATCH /saas-subscription` (so `owner`); middleware `EnsureTenantPlanIsActive` bloqueia toda escrita com HTTP 402 quando o trial vence sem upgrade, liberando so leitura, logout e a propria troca de plano. 7 testes novos em `PhaseUmSaasPlansTest` (48/48 testes de backend passando). App: `TenantRepository`/`SaasSubscriptionRepository` novos; `OwnerHomePage` ganhou banner de trial/expirado (com dias restantes) e tile "Meu plano"; nova `SaasPlanPage` mostra o tier atual (limites e uso: "X de Y profissionais/assinantes/unidades") e lista os 3 tiers pagos pra trocar, reaproveitando o mesmo padrao visual da troca de plano do cliente; mensagens de limite atingido e de trial expirado chegam prontas da API e aparecem inline nos formularios existentes, sem necessidade de tratamento especial tela a tela. `flutter analyze` limpo e 24/24 testes passando (golden do dashboard do proprietario atualizado pela nova tile) | Multi-unidade so tem o limite visivel, sem funcionalidade real (decisao de escopo, ver secao Decisoes); troca de plano SaaS ainda nao cobra de verdade, gateway fica para fase futura; sem validacao em dispositivo real ainda |

## Fase 2 - Cobranca Manual Operacional

Status: `Em andamento`

Objetivo: entregar a primeira versao operacional de cobranca manual: o dono confirma pagamentos no app, escolhe a modalidade usada e pode registrar valores em aberto como fiado.

### Escopo previsto

- [x] Tela de confirmacao manual de pagamento pelo dono
- [x] Modalidades: PIX, cartao credito, cartao debito, dinheiro
- [x] Modalidade fiado, mantendo o pagamento pendente
- [x] Gestao do fiado pelo dono, com saldo pendente e recebimentos parciais
- [x] Tela de status financeiro da assinatura
- [x] Aviso de pagamento pendente
- [x] Historico de pagamentos
- [x] Area do cliente com pagamentos pendentes e efetuados
- [x] Area do profissional com servicos executados na semana/mes, comissao prevista e adiantamentos
- [x] Area do gestor para configurar dia de pagamento e lancar adiantamentos
- [ ] Notificacao push (FCM): confirmacao de agendamento e lembrete de vencimento (spec 3.2/4.3 — incluida ja no tier Basico, por isso vive nesta fase junto com o resto da automacao)

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-04 | Codex | Em andamento | Escopo corrigido a pedido do usuario: primeira versao usa cobranca manual pelo dono, sem gateway. Tela de confirmacao passou a exigir escolha entre PIX, cartao credito, cartao debito, dinheiro e fiado; quando o dono escolhe fiado, o item continua na lista de pendentes | Falta criar visao dedicada de fiados/contas em aberto e validar em dispositivo real |
| 2026-07-04 | Codex | Parcial aprovado | Painel do gestor ganhou "Gestao do fiado" com saldo aberto e lancamento parcial de recebimentos, e "Comissoes profissionais" com dia de pagamento, extrato e adiantamentos; cliente ganhou aba "Pagamentos" separando pendentes e efetuados; perfil profissional passou a mostrar atendimentos da semana/mes, comissao, adiantamentos e valor a receber; `flutter analyze` limpo e testes mockados cobrem fiado parcial e comissao | Falta validacao em dispositivo real e refinamento futuro de relatorios financeiros |

## Fase 3 - Onboarding e Autocadastro

Status: `Em auditoria`

Objetivo: eliminar a dependencia do dono cadastrar manualmente cada cliente, permitindo autocadastro do cliente vinculado a um estabelecimento (por convite - codigo/link/QR - ou por escolha em diretorio publico quando nao ha convite), e tornar o onboarding do dono mais autoexplicativo com um checklist de configuracao inicial pos-cadastro. Publico-alvo do dono tem baixa familiaridade com tecnologia, entao o fluxo precisa ser guiado sem travar quem ainda nao tem todos os dados na primeira sessao.

### Escopo previsto

- [x] Tela inicial de escolha de perfil no cadastro a partir do `LoginPage`: "Sou dono de salao" / "Sou cliente"
- [x] Deep link/QR: abrir o convite (`clubedosalao://convite/{codigo}` ou link universal) direto na tela "Voce foi convidado por [Salao]"
- [x] Tela de cadastro do cliente (nome, telefone, e-mail, senha), reaproveitada tanto vindo de convite quanto do diretorio
- [x] Tela de diretorio/busca de saloes ativos para cliente sem convite escolher onde se cadastrar
- [x] Tela do dono para exibir e compartilhar o codigo de convite + QR code gerado localmente, com botao de compartilhar via share sheet nativo (WhatsApp, e-mail, etc)
- [x] Botao de regenerar o codigo de convite na mesma tela
- [x] Checklist de configuracao inicial no dashboard do dono (cadastrar profissional, cadastrar servico, compartilhar convite), dispensavel item a item, some quando todos os itens forem concluidos ou dispensados
- [x] Carrossel de boas-vindas do cliente (3 telas) no primeiro acesso pos-cadastro, dispensavel

### Criterios de aceite

- [x] Cliente consegue abrir um link/QR de convite e completar o proprio cadastro sem ajuda do dono
- [x] Cliente sem convite consegue escolher um salao no diretorio publico e se cadastrar sozinho
- [x] Dono consegue visualizar, compartilhar e regenerar o codigo de convite do proprio salao
- [x] Checklist do dono aparece apos o cadastro do estabelecimento e reflete o progresso conforme os itens sao concluidos ou dispensados
- [x] Fluxos validados em emulador Android contra o backend real

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-05 | Claude | Em auditoria | `ChooseAccountTypePage` (a partir do botao "Criar conta" do `LoginPage`) leva a `RegisterOwnerPage` (dono) ou a `ClientInviteEntryPage` (cliente); esta ultima aceita um codigo de convite (`GET /tenants/by-invite-code/{code}`) e mostra `InviteConfirmationPage` antes do cadastro, ou encaminha para `TenantDirectoryPage` (`GET /tenants/directory`, com busca client-side) quando o cliente nao tem codigo; ambos os caminhos convergem em `ClientRegisterPage`, que chama `AuthSession.registerClient` (`POST /auth/register-client`) e ja autentica. Deep link `clubedosalao://convite/{codigo}` tratado via pacote `app_links` (novo intent-filter no `AndroidManifest.xml`, scheme `clubedosalao` host `convite`) abre `ClientInviteEntryPage` direto com o codigo preenchido, pulando a digitacao manual. Apos o autocadastro, `ClientWelcomeCarouselPage` (3 slides, dispensavel) aparece uma unica vez via flag `justRegisteredAsCustomer` na `AuthSession` (nao persistido). Dono ganhou `InviteCodePage` (nova tile "Convidar clientes" no dashboard) com QR gerado localmente (`qr_flutter`), compartilhamento pelo share sheet nativo (`share_plus`) e regeneracao de codigo (`POST /tenant/invite-code/regenerate`); dashboard do dono tambem ganhou um checklist de configuracao (`_OnboardingChecklistCard`) cobrindo profissional/servico cadastrado (calculado direto da API) e convite compartilhado (guardado localmente via `OnboardingChecklistStorage`, novo store injetavel espelhando o padrao do `TokenStorage`), dispensavel a qualquer momento e que some sozinho quando os 3 itens estao concluidos. `flutter analyze` limpo e 32/32 testes passando (5 novos em `client_onboarding_test.dart` cobrindo convite valido/invalido, diretorio e o checklist; goldens do login e do dashboard do dono atualizados pela nova tile). Validado ponta a ponta no emulador Android (`Small Phone`) contra o backend real: cliente se autocadastrou escolhendo "Clube do Salao Demo" no diretorio real, viu o carrossel e chegou ao dashboard sem plano ativo (cenario avulso); dono logado viu o checklist real (profissional/servico ja marcados, convite pendente), abriu `InviteCodePage`, o QR e o codigo bateram com o valor do banco, o share sheet nativo abriu com o texto correto, e o checklist sumiu apos compartilhar; convite por deep link (`adb am start -d "clubedosalao://convite/{codigo}"`) abriu o app direto na tela de confirmacao com os dados reais do tenant | iOS/simulador iOS continua sem validacao — ambiente desta sessao nao tem Mac disponivel; regeneracao de codigo no emulador nao foi reexercitada nesta rodada (ja validada direto na API na fase anterior) |
| 2026-07-05 | Claude | Parcial aprovado | Correcoes de usabilidade reportadas pelo usuario ao testar o autocadastro do cliente sem convite: (1) texto das telas novas (`client_onboarding_pages.dart`, `owner_invite_page.dart`, checklist em `owner_pages.dart`, `RegisterOwnerPage`) recebeu acentuacao correta em portugues — o restante do app (telas ja existentes antes desta fase) segue sem acento, registrado como debito pre-existente separado, fora do escopo desta correcao; (2) campo de telefone do `ClientRegisterPage` ganhou `hintText` com exemplo (`Ex: 11912345678`) e `inputFormatters` (digitos apenas, maximo 11); (3) campo "Confirmar senha" adicionado com validacao de igualdade e alternancia de visibilidade (mesmo padrao aplicado ao campo "Senha"); (4) corrigido bug real de reatividade: `ClientRegisterPage` e `RegisterOwnerPage` liam `authSession.errorMessage`/`authSession.status` direto no `build()` sem escutar `notifyListeners()`, entao um erro da API (ex: telefone duplicado) so aparecia apos algum rebuild por outro motivo — corrigido com `authSession.addListener` chamando `setState` no `initState`/`dispose` de ambas as telas; (5) backend ganhou traducao completa de mensagens de validacao para portugues (`lang/pt_BR/validation.php`, `APP_LOCALE=pt_BR`), corrigindo mensagens que vinham em ingles. `flutter analyze` limpo e 32/32 testes passando. Validado no emulador Android contra o backend real: acentos corretos, mascara de telefone truncou em 11 digitos, confirmacao de senha funcionou, e a mensagem de telefone duplicado ("Este telefone ja esta cadastrado.") apareceu em portugues imediatamente ao tocar em "Criar conta", sem precisar voltar de tela. O "menu hamburguer solto" relatado foi identificado como o teclado virtual do emulador em modo flutuante (aparece em qualquer campo de texto; confirmado por busca no codigo que nao ha `Drawer`/`Menu`/`PopupMenuButton` em nenhuma tela do app) | Acentuacao das telas anteriores a esta fase (owner/customer/professional_pages.dart) permanece pendente como debito tecnico separado |

### Decisoes

| Data | Decisao | Motivo |
|---|---|---|
| 2026-07-05 | Convite do dono ao cliente usa codigo fixo regeneravel, nao um token unico por convite | Simplicidade para dono leigo em tecnologia: reutiliza o mesmo codigo/QR sem precisar gerar um novo a cada pessoa convidada; confirmado com o usuario |
| 2026-07-05 | Cliente avulso sem convite escolhe o salao em um diretorio publico (nome, cidade, tipo de negocio) | Reduz friccao de cadastro para quem nao recebeu convite de ninguem; aceito o tradeoff de expor a existencia de estabelecimentos concorrentes entre si na mesma cidade |
| 2026-07-05 | Cadastro de cliente via convite/diretorio entra ativo direto, sem aprovacao manual do dono | Confirmacao de pagamento ja e manual e feita separadamente pelo dono; bloquear o cadastro em si adicionaria friccao sem reduzir risco financeiro real |
| 2026-07-05 | Onboarding do dono continua formulario unico (`RegisterOwnerPage`), com checklist de configuracao pos-cadastro em vez de wizard obrigatorio em etapas | Dono pode nao ter profissionais/servicos cadastrados ainda na primeira sessao; forcar um wizard em etapas travaria o fluxo para quem ainda nao tem esses dados |
| 2026-07-05 | Deep link usa scheme customizado (`clubedosalao://convite/{codigo}`) em vez de universal link com dominio verificado | Universal/app link exige dominio proprio com arquivo `assetlinks.json` publicado e verificado, indisponivel neste estagio do projeto; o link `https://clubedosalao.app/c/{codigo}` continua funcionando como fallback textual (mostra o codigo para digitacao manual) mesmo sem o dominio existir de fato |
| 2026-07-05 | Checklist do dono guarda "convite compartilhado" e "dispensado" localmente no aparelho (`OnboardingChecklistStorage`), nao no backend | Sao preferencias de interface por sessao/aparelho, nao dado de negocio do tenant; evita criar coluna/endpoint no backend so para isso, mesmo padrao ja usado para o token de autenticacao |

## Fase 4 - Fidelidade e Avaliacoes

Status: `Nao iniciado`

### Escopo previsto

- [ ] Avaliacao pos-atendimento
- [ ] Tela de pontos
- [ ] Nivel do cliente
- [ ] Beneficios por nivel

## Fase 5 - CRM Avancado e Estoque

Status: `Nao iniciado`

### Escopo previsto

- [ ] Perfil completo do cliente
- [ ] Preferencias
- [ ] Historico ampliado
- [ ] Produtos e estoque para proprietario

## Fase 6 - Marketing Automation

Status: `Nao iniciado`

### Escopo previsto

- [ ] Campanhas simples
- [ ] Cupons
- [ ] Indicacao de amigos
- [ ] Recuperacao de inativos

## Fase 7 - Business Intelligence

Status: `Nao iniciado`

### Escopo previsto

- [ ] Indicadores de MRR, churn e ocupacao
- [ ] Ranking de profissionais
- [ ] Cards executivos para proprietario

## Fase 8 - Inteligencia Artificial

Status: `Nao iniciado`

### Escopo previsto

- [ ] Assistente de agendamento
- [ ] Sugestao de horarios
- [ ] Sugestao de campanhas
- [ ] Alertas de risco de cancelamento

## Decisoes

| Data | Decisao | Motivo | Impacto |
|---|---|---|---|
| 2026-07-03 | Comecar com telas navegaveis sem API | Estabelecer experiencia por perfil rapidamente | Permite validar fluxo antes da integracao |
| 2026-07-03 | App unico para tres perfis | PRD define Flutter como experiencia principal | Menos superficies para manter no lancamento |
| 2026-07-03 | Usar commit/rollback local no mobile | Flutter ainda nao tem banco local nesta fase | Padrao fica pronto para estados otimistas e falhas de API |
| 2026-07-03 | Remover a fase "Portal Web Administrativo" do roadmap | A especificacao do produto (secoes 1 e 6) define "zero painel web administrativo" como decisao de produto, nao como item fora do MVP — mante-la como fase futura contradizia a premissa central (app mobile-only para dono leigo em tecnologia) | Fase 7 (Inteligencia Artificial) mantem o mesmo numero; nenhuma outra fase referenciava o Portal Web |
| 2026-07-03 | Inserir a Fase 1 "Planos SaaS e Controle de Acesso" | A estrutura de trial + 3 tiers pagos + `PlanGate` (secao 3 da especificacao) nao tinha nenhuma fase no roadmap, apesar de ser o nucleo do modelo de negocio | Fases antigas 1-5 foram renumeradas para 2-6; Fase 7 nao muda |
| 2026-07-03 | Remover "Notificacao push via FCM" da Fase 0, manter so na Fase 2 | Item aparecia duplicado sem fase "dona"; push so faz sentido completo junto com lembretes de cobranca/agendamento, nao como parte da fundacao/validacao | Fase 0 nao fica mais bloqueada por um item que nao e essencial para validar o nucleo do produto |
| 2026-07-04 | Adicionar agendamento avulso e fila de espera ao escopo da Fase 0, a pedido do usuario | A especificacao do produto nao cobre atendimento de cliente sem assinatura (nem agendamento avulso nem fila de espera) — sem isso, o app so serve quem ja assinou um plano, deixando de fora um caso de uso real do salao (cliente eventual). Cobranca do avulso reaproveita a confirmacao manual de pagamento ja existente; fila de espera e resolvida manualmente pelo dono/profissional (sem auto-atribuicao) | Fase 0 ganha 3 itens de escopo e 3 criterios de aceite novos; nenhuma fase futura muda de numero |
| 2026-07-05 | Inserir a Fase 3 "Onboarding e Autocadastro", a pedido do usuario apos revisao de usabilidade | Hoje o cliente so entra no sistema se o dono cadastrar manualmente (`POST /clients`), e o onboarding do dono e um formulario unico sem nenhum guia — isso nao atende a expectativa de cliente se autocadastrar via convite/link/QR ou de forma avulsa escolhendo o salao, nem a premissa de produto de onboarding guiado para dono leigo em tecnologia (secao 1 da especificacao) | Fases antigas 3-7 (Fidelidade, CRM, Marketing, BI, IA) foram renumeradas para 4-8 |
