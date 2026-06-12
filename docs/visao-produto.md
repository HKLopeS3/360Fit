# 360Fit — Visão de Produto

Plataforma SaaS multi-tenant de gestão fitness, saúde e performance.

## Público-alvo

Personal trainers, academias, nutricionistas, fisioterapeutas, assessorias esportivas, estúdios de treinamento e clínicas multidisciplinares.

## Modelo multi-tenant

Cada cliente (empresa) possui seu próprio ambiente; os dados **nunca** se misturam entre empresas.

```
Academia Alpha                 Academia Beta
├── Personal João              ├── Personal Lucas
├── Personal Maria             ├── Nutricionista Carla
├── Nutricionista Ana          └── Fisioterapeuta Marcos
└── Fisioterapeuta Pedro
```

## Perfis de usuário

| Perfil | Descrição | Permissões principais |
|---|---|---|
| **Super Administrador** | Operador da plataforma | Assinaturas, financeiro global, clientes, planos, relatórios globais, controle de uso |
| **Administrador da Empresa** | Academia, clínica ou assessoria | Contratar profissionais, gerenciar equipes, dashboard completo, relatórios financeiros, controle de alunos |
| **Profissional** | Personal, nutricionista ou fisioterapeuta | Permissões específicas da sua área |
| **Aluno/Paciente** | Cliente final | Acesso aos próprios dados |

## Módulos profissionais

- **Personal Trainer**: prescrição de treinos, evolução de carga, avaliação física, agendamentos, chat, controle de frequência.
- **Nutricionista**: plano alimentar, refeições, receitas, controle de água e peso, avaliações nutricionais, bioimpedância.
- **Fisioterapeuta**: anamnese, diagnósticos, exercícios corretivos, evolução clínica, laudos, relatórios.

## Dashboard executivo (academia/clínica)

- **Comercial**: novos alunos, cancelamentos, receita mensal e recorrente.
- **Operacional**: frequência, treinos realizados, agendamentos.
- **Performance**: alunos ativos, alunos em risco de evasão, evolução média.

## Planos SaaS

| | **Basic** R$ 49,90/mês | **Pro** R$ 99,90/mês | **Premium** R$ 249,90/mês |
|---|---|---|---|
| Alunos | até 50 | até 300 | ilimitados |
| App do aluno, treinos, agenda, chat | ✔ | ✔ | ✔ |
| Avaliação física, notificações, dashboard básico | ✔ | ✔ | ✔ |
| Avaliações avançadas, comparativos corporais | — | ✔ | ✔ |
| Biblioteca de exercícios, vídeos, assinatura digital | — | ✔ | ✔ |
| Áreas nutricional e fisioterapêutica | — | ✔ | ✔ |
| IA para evolução, integração WhatsApp | — | ✔ | ✔ |
| Profissionais ilimitados, multiunidades | — | — | ✔ |
| Dashboard executivo, financeiro, CRM | — | — | ✔ |
| **White Label** (logo, nome, cores, domínio, app próprio) | — | — | ✔ |
| API aberta, integrações, automações, suporte prioritário | — | — | ✔ |

## Módulo financeiro (futuro)

Cobranças e assinaturas recorrentes via PIX, cartão e boleto. Integrações candidatas: Stripe, Mercado Pago, Asaas, PagSeguro.

## CRM de alunos (futuro)

Funil: Lead → Contato → Avaliação → Matrícula → Aluno Ativo → Renovação.

## Inteligência artificial (futuro)

- **Personal**: progressão de carga, novos exercícios, deload, ajustes de treino.
- **Nutricionista**: ajustes calóricos, distribuição de macros, estratégias.
- **Fisioterapeuta**: exercícios corretivos, protocolos, evolução clínica.

## Visão de longo prazo

Ecossistema completo de saúde e performance conectando academias, profissionais, alunos, smartwatches, balanças inteligentes e IA de acompanhamento — arquitetura preparada para dezenas de milhares de profissionais e centenas de milhares de alunos sem reconstrução.

## Roadmap

1. **Fase 1 (atual)** — App Flutter (Aluno + Personal), backend Supabase ativo. Suíte do Personal entregue: avaliação profissional (Pollock/Petroski, bioimpedância, PAR-Q, fotogrametria com grade, 1RM/Cooper/Wells), prescrição avançada (cadência, métodos, periodização macro/meso/micro, vídeos, substituição dinâmica, cronômetro com alerta), feedback PSE/dor com dashboard de alertas (sumidos, vencimentos, aniversários, inadimplentes), retenção (fotos antes/depois, medalhas, água, mensalidades manuais) e feed social moderado com curtidas. Também: execução guiada de treino com cronômetro e histórico/calendário de frequência; avaliações físicas com medidas e comparativo de evolução; agenda interativa (criar/remarcar/cancelar/confirmar presença); cadastro e edição de alunos; perfil do aluno com registro rápido de peso; notificações in-app; área institucional e políticas das lojas. *Os dados mock vivem em memória — não persistem entre recargas; persistência real chega com o Supabase.*
2. **Fase 2** — Backend **Supabase**: Auth, PostgreSQL com RLS multi-tenant, Realtime (chat) e Storage. Ver [arquitetura.md](arquitetura.md).
3. **Fase 3** — Módulos Nutrição e Fisioterapia, dashboard executivo, perfil Admin da Empresa.
4. **Fase 4** — Financeiro, CRM, White Label, IA, publicação nas lojas.
