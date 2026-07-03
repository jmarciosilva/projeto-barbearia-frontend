# Clube do Salão — Especificação do Produto

> Documento de especificação funcional — v1.0 (pré-desenvolvimento)

---

## 1. Visão Geral

**Produto:** SaaS mobile-only para gestão de barbearias, salões de beleza, clínicas de estética e estúdios, com foco em **assinatura mensal de serviços** em vez de cobrança avulsa por atendimento.

**Diferencial:** o estabelecimento vende um plano (ex: "Corte ilimitado seg-sex por R$100/mês"), e o sistema controla automaticamente validade, uso, bloqueios e renovação.

**Premissa de design:** público-alvo (donos de barbearia/salão) majoritariamente sem prática com computador, apenas celular, e baixa familiaridade com tecnologia. Por isso:
- Zero painel web administrativo — toda a gestão acontece dentro do app mobile.
- App único (Flutter), com três papéis: **Dono/Gerente**, **Profissional**, **Cliente final**.
- Telas simples, uma decisão por vez, onboarding guiado.

**Modelo de negócio:** SaaS multi-tenant, vendido por assinatura mensal para os estabelecimentos, com trial gratuito de 30 dias.

---

## 2. Papéis do Sistema

| Papel | Responsabilidades no app |
|---|---|
| **Dono/Gerente** | Cadastra estabelecimento, profissionais, serviços, planos; acompanha financeiro e relatórios; gerencia assinaturas dos clientes |
| **Profissional** | Vê sua própria agenda, define disponibilidade, confirma atendimentos, acompanha comissão |
| **Cliente final** | Assina plano, agenda/cancela horário, acompanha histórico de uso, paga assinatura |

---

## 3. Estrutura de Planos SaaS

### 3.1 Trial — 30 dias, sem cartão de crédito

Estratégia: o trial libera as funcionalidades do plano **Premium**, mas com limites de uso reduzidos — o suficiente para o dono sentir o valor completo da ferramenta, sem viabilizar operar o negócio de graça indefinidamente. Isso favorece a conversão para o plano pago mais caro (efeito de ancoragem: o cliente se acostuma ao completo e sente perda ao ser rebaixado).

| Limite | Valor |
|---|---|
| Profissionais | até 3 |
| Clientes assinantes ativos | até 20 |
| Agendamentos/mês | ilimitado |
| Unidades/filiais | 1 |
| Funcionalidades | todas do plano Premium |

### 3.2 Plano Básico — R$ 79,99/mês

Foco: gestão essencial do dia a dia do estabelecimento.

**Funcionalidades incluídas:**
- Cadastro de clientes, profissionais e serviços
- Planos de assinatura (criação, benefícios, restrições de uso, dias/horários permitidos, profissionais habilitados)
- Registro automático de utilização a cada atendimento (histórico)
- Bloqueio automático por inadimplência ou plano vencido
- Cobrança recorrente via Asaas
- Agenda por profissional (visualização diária/semanal, verificação de conflito)
- Cancelamento e remarcação de agendamento
- Notificações push (confirmação de agendamento + lembrete)
- Dashboard simples (faturamento do mês, assinantes ativos, agendamentos do dia)

**Não incluído:** fidelidade, avaliações, controle de estoque, relatórios avançados, marketing automation, múltiplas unidades

**Limites:**
| Limite | Valor |
|---|---|
| Profissionais | até 3 |
| Clientes assinantes ativos | até 100 |
| Unidades/filiais | 1 |

### 3.3 Plano Intermediário — R$ 129,99/mês

Foco: ferramentas de retenção e entendimento do cliente.

**Tudo do Básico, mais:**
- Fidelidade/pontos (incluindo clientes sem assinatura ativa)
- Avaliação pós-atendimento (nota + comentário)
- Controle de estoque de produtos (entrada, saída, baixa automática na venda)
- Comissão detalhada por profissional
- Relatórios básicos: mais vendidos, clientes VIP, clientes inadimplentes, horários mais movimentados

**Limites:**
| Limite | Valor |
|---|---|
| Profissionais | até 8 |
| Clientes assinantes ativos | até 400 |
| Unidades/filiais | 1 |

### 3.4 Plano Premium — R$ 199,99/mês

Foco: estabelecimentos em fase de crescimento/escala.

**Tudo do Intermediário, mais:**
- Marketing automation (campanhas de reativação, mensagem automática de aniversário, cupom automático para clientes inativos)
- Relatórios avançados: MRR, churn, LTV, gráficos mensais/anuais
- Múltiplas unidades/filiais no mesmo painel
- Suporte prioritário

**Limites:**
| Limite | Valor |
|---|---|
| Profissionais | ilimitado |
| Clientes assinantes ativos | ilimitado |
| Unidades/filiais | ilimitado |

### 3.5 Regra de downgrade

Quando um estabelecimento migra do trial (Premium) para um plano com limites menores e está acima do novo limite (ex: cadastrou 6 profissionais no trial e foi para o Básico, limite 3):

- **Não bloquear o downgrade.** Os registros mais antigos dentro do limite permanecem ativos; os excedentes ficam inativos (não removidos) até o dono decidir manualmente quais manter ou fazer upgrade novamente.
- Justificativa: evita travar o usuário leigo em uma tela de erro sem entender o motivo.

---

## 4. Especificação Funcional Detalhada (por módulo)

### 4.1 Cadastro
- **Estabelecimento:** nome, endereço, horário de funcionamento, logo
- **Profissionais:** nome, especialidade, horários de trabalho, foto, comissão (%)
- **Serviços:** nome, duração, preço, profissionais habilitados a executar
- **Clientes:** nome, telefone/WhatsApp, foto (opcional), observações

### 4.2 Planos de Assinatura (núcleo do sistema)
- Criação de plano: nome, valor, recorrência (mensal)
- Benefícios: quais serviços o plano inclui
- Restrições: limite de utilizações (numérico ou ilimitado), dias da semana permitidos, faixa de horário permitida, profissionais habilitados
- Assinatura do cliente a um plano
- Geração automática de histórico a cada utilização
- Bloqueio automático de agendamento/uso por inadimplência ou plano vencido
- Renovação automática via cobrança recorrente (Asaas)

### 4.3 Agenda
- Visualização por profissional (diária/semanal)
- Agendamento pelo cliente: escolha de serviço, profissional e horário
- Verificação automática de conflito e intervalo entre atendimentos
- Cancelamento e remarcação
- Confirmação e lembrete via notificação push

### 4.4 Área do Cliente (dentro do app)
- Tela inicial: plano atual, próximo vencimento, utilizações do mês
- Agendar, cancelar, remarcar, renovar assinatura
- Histórico de atendimentos (data, serviço, profissional, avaliação dada)

### 4.5 Financeiro (visível conforme plano)
- Básico: dashboard simples (faturamento do mês, assinantes ativos, agendamentos do dia)
- Intermediário: comissão detalhada por profissional, relatórios básicos
- Premium: MRR, churn, LTV, gráficos mensais/anuais

### 4.6 Fidelidade e Marketing (Intermediário/Premium)
- Pontos por serviço realizado, trocáveis por produtos/descontos/brindes
- Campanhas automáticas: cliente inativo, aniversariante, cupom de reativação (Premium)

---

## 5. Arquitetura Técnica (resumo)

| Camada | Tecnologia |
|---|---|
| Backend | Laravel 12 (PHP 8.3), API REST pura (headless, sem painel web) |
| Autenticação | Laravel Sanctum |
| Banco de dados | MySQL 8 ou PostgreSQL, multi-tenant via `tenant_id` |
| Controle de planos | `plans` + `plan_features` (feature flags e limites), `PlanGate` centralizado |
| Cobrança | Asaas (recorrência) |
| App mobile | Flutter — app único, navegação condicional por papel |
| Notificações | Push (Firebase Cloud Messaging) |

Duas entidades de assinatura separadas no modelo de dados:
- `saas_subscriptions` — estabelecimento paga pelo uso do sistema (Trial/Básico/Intermediário/Premium)
- `client_subscriptions` — cliente final paga o estabelecimento pelo plano de serviço

---

## 6. Fora de escopo no MVP (fica para revisão futura)

- Integração com WhatsApp API (custo/risco a avaliar — possível uso de Evolution API não oficial)
- Múltiplos gateways de pagamento (Mercado Pago, Stripe)
- Integração com Google Calendar
- Painel web administrativo (fora do escopo do produto, por definição)

---

*Documento para revisão. Após validação, o próximo passo é o desenho do schema de banco de dados (migrations Laravel) para o núcleo: tenants, plans, plan_features, clientes, assinaturas e utilizações.*
