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

Objetivo: entregar app unico para proprietario/gerente, profissional e cliente, validando recorrencia, agenda e pagamento manual.

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

## Fase 1 - Planos SaaS e Controle de Acesso

Status: `Nao iniciado`

Objetivo: implementar o modelo de negocio do produto (especificacao, secao 3) — trial e os 3 tiers pagos do SaaS, com limites e liberacao de funcionalidade por plano. Sem esta fase o app nao tem como cobrar pelo proprio uso nem limitar/liberar recursos por tier, o que hoje bloqueia qualquer avanco comercial real.

### Escopo previsto

- [ ] Cadastro de estabelecimento inicia trial de 30 dias sem cartao, liberando funcionalidades do Premium com limites reduzidos (ate 3 profissionais, ate 20 clientes assinantes, 1 unidade)
- [ ] Selecao/upgrade de plano SaaS pelo proprietario: Basico (R$79,99), Intermediario (R$129,99), Premium (R$199,99)
- [ ] `PlanGate` centralizado no backend (feature flags + limites por tier) espelhado no app: funcionalidade fora do plano aparece bloqueada com explicacao, nao apenas escondida
- [ ] Limites por plano aplicados e visiveis (profissionais, clientes assinantes ativos, unidades/filiais)
- [ ] Regra de downgrade (spec 3.5): registros excedentes ficam inativos, nunca removidos, ate o dono decidir ou fazer upgrade
- [ ] Multiplas unidades/filiais no mesmo painel (exclusivo do tier Premium)
- [ ] Aviso de fim de trial e bloqueio gracioso ao expirar sem upgrade

### Criterios de aceite

- [ ] Tenant novo comeca em trial e ve a contagem regressiva dos 30 dias
- [ ] Proprietario consegue trocar de plano SaaS pelo app
- [ ] Funcionalidade fora do plano contratado fica bloqueada de forma visivel e compreensivel para usuario leigo
- [ ] Downgrade nao apaga dados nem trava o proprietario em tela de erro sem explicacao

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-03 | Claude | Nao iniciado | Auditoria da especificacao vs. roadmap encontrou a lacuna: backend hoje so tem uma tabela `saas_subscriptions` esqueleto (`plan_name` fixo "Plano Fundador", sem os 4 tiers, sem tabela de `plan_features`/limites) | Toda a fase — desenho de schema (`plan_features`), `PlanGate`, telas de trial/upgrade/downgrade no app |

## Fase 2 - Cobranca Automatica e Base Operacional

Status: `Nao iniciado`

Objetivo: substituir a confirmacao manual de pagamento (Fase 0) pela cobranca recorrente real das assinaturas de cliente via Asaas (especificacao, secoes 3, 4.2 e 5), e refletir no app o status automatico de cobranca e inadimplencia.

### Escopo previsto

- [ ] Integracao com Asaas para cobranca recorrente das assinaturas de cliente (`client_subscriptions`)
- [ ] Renovacao automatica da assinatura via webhook Asaas
- [ ] Tela de status financeiro da assinatura
- [ ] Aviso de pagamento pendente
- [ ] Aviso de assinatura bloqueada
- [ ] Historico de pagamentos
- [ ] Confirmacao visual de pagamento processado por webhook
- [ ] Notificacao push (FCM): confirmacao de agendamento e lembrete de vencimento (spec 3.2/4.3 — incluida ja no tier Basico, por isso vive nesta fase junto com o resto da automacao)

## Fase 3 - Fidelidade e Avaliacoes

Status: `Nao iniciado`

### Escopo previsto

- [ ] Avaliacao pos-atendimento
- [ ] Tela de pontos
- [ ] Nivel do cliente
- [ ] Beneficios por nivel

## Fase 4 - CRM Avancado e Estoque

Status: `Nao iniciado`

### Escopo previsto

- [ ] Perfil completo do cliente
- [ ] Preferencias
- [ ] Historico ampliado
- [ ] Produtos e estoque para proprietario

## Fase 5 - Marketing Automation

Status: `Nao iniciado`

### Escopo previsto

- [ ] Campanhas simples
- [ ] Cupons
- [ ] Indicacao de amigos
- [ ] Recuperacao de inativos

## Fase 6 - Business Intelligence

Status: `Nao iniciado`

### Escopo previsto

- [ ] Indicadores de MRR, churn e ocupacao
- [ ] Ranking de profissionais
- [ ] Cards executivos para proprietario

## Fase 7 - Inteligencia Artificial

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
| 2026-07-03 | Remover "Notificacao push via FCM" da Fase 0, manter so na Fase 2 | Item aparecia duplicado sem fase "dona"; push so faz sentido completo junto com o resto da automacao de cobranca/lembrete (Asaas), nao como parte da fundacao/validacao | Fase 0 nao fica mais bloqueada por um item que nao e essencial para validar o nucleo do produto |
