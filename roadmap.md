# Roadmap de Desenvolvimento - Mobile

Este documento guia e audita a evolucao do app Flutter do Clube do Salao. Toda fase deve ser marcada aqui com status, telas entregues, testes executados, pendencias e decisao de continuidade.

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

Status: `Em andamento`

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
- [ ] Autenticacao real com API
- [ ] Persistencia de token
- [ ] Onboarding de estabelecimento
- [ ] Cadastro de profissionais
- [ ] Cadastro de servicos
- [ ] Cadastro de clientes
- [ ] Criacao de planos
- [ ] Contratacao de assinatura para cliente
- [ ] Agenda com dados reais
- [ ] Agendamento, cancelamento e remarcacao
- [ ] Confirmacao manual de pagamento
- [ ] Estados de loading, vazio e erro
- [ ] Notificacao push via Firebase Cloud Messaging

### Criterios de aceite

- [x] `flutter analyze` executa sem erros
- [x] `flutter test` executa sem erros
- [x] Teste automatizado cobre commit e rollback de estado local
- [x] Teste automatizado cobre troca de perfil antes do dashboard
- [ ] Login funcional com token Sanctum
- [ ] Proprietario consegue cadastrar cliente, servico, profissional e plano
- [ ] Cliente consegue solicitar agendamento permitido pelo plano
- [ ] Profissional consegue visualizar agenda do dia
- [ ] App validado em Android
- [ ] App validado em iOS ou simulador iOS quando disponivel

### Auditoria da fase

| Data | Responsavel | Resultado | Evidencias | Pendencias |
|---|---|---|---|---|
| 2026-07-03 | Codex | Parcial aprovado | `flutter analyze` e `flutter test` passaram | Integrar API, autenticar, persistir token e implementar fluxos reais |
| 2026-07-03 | Codex | Parcial aprovado | Handler global de excecoes, transacao local de estado, comentarios em PT-BR e testes passaram | Ainda falta aplicar o padrao nos fluxos reais quando a API for integrada |

## Fase 1 - Cobranca Automatica e Base Operacional

Status: `Nao iniciado`

Objetivo: refletir no app o status automatico de cobranca e inadimplencia.

### Escopo previsto

- [ ] Tela de status financeiro da assinatura
- [ ] Aviso de pagamento pendente
- [ ] Aviso de assinatura bloqueada
- [ ] Historico de pagamentos
- [ ] Confirmacao visual de pagamento processado por webhook

## Fase 2 - Fidelidade e Avaliacoes

Status: `Nao iniciado`

### Escopo previsto

- [ ] Avaliacao pos-atendimento
- [ ] Tela de pontos
- [ ] Nivel do cliente
- [ ] Beneficios por nivel

## Fase 3 - CRM Avancado e Estoque

Status: `Nao iniciado`

### Escopo previsto

- [ ] Perfil completo do cliente
- [ ] Preferencias
- [ ] Historico ampliado
- [ ] Produtos e estoque para proprietario

## Fase 4 - Marketing Automation

Status: `Nao iniciado`

### Escopo previsto

- [ ] Campanhas simples
- [ ] Cupons
- [ ] Indicacao de amigos
- [ ] Recuperacao de inativos

## Fase 5 - Business Intelligence

Status: `Nao iniciado`

### Escopo previsto

- [ ] Indicadores de MRR, churn e ocupacao
- [ ] Ranking de profissionais
- [ ] Cards executivos para proprietario

## Fase 6 - Portal Web Administrativo

Status: `Nao iniciado`

Observacao: fase predominantemente backend/web. O app mobile pode receber links, alertas ou visoes resumidas caso necessario.

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
