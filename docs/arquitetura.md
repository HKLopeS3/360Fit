# Arquitetura — Frontend Flutter + Backend Supabase

## Visão geral

O 360Fit é **frontend-first**: toda a lógica de apresentação vive no app Flutter; o backend é 100% **Supabase** (BaaS sobre PostgreSQL), sem servidor próprio.

```
┌────────────────────────────────────────────┐
│              App Flutter (web/mobile)      │
│                                            │
│  features/ (UI) ── Riverpod providers      │
│        │                                   │
│  data/repositories (interfaces abstratas)  │
│        │                                   │
│  ┌─────┴──────────┐                        │
│  │ Mock*Repository │  Supabase*Repository  │
│  │ (padrão hoje)   │  (ativa com creds)    │
│  └─────────────────┴───────────┬──────────┘
└────────────────────────────────┼───────────┘
                                 │ supabase_flutter
                 ┌───────────────┴───────────────┐
                 │            SUPABASE           │
                 │  Auth (email/senha, OAuth)    │
                 │  PostgreSQL + RLS multi-tenant│
                 │  Realtime (chat, presença)    │
                 │  Storage (avatares, mídias)   │
                 │  Edge Functions (futuro: IA,  │
                 │   webhooks de pagamento)      │
                 └───────────────────────────────┘
```

## Camadas do app

| Camada | Pasta | Responsabilidade |
|---|---|---|
| UI | `app/lib/features/` | Telas e widgets; nunca acessa dados diretamente |
| Estado | `app/lib/data/providers.dart` | Providers Riverpod; escolhem a implementação de repositório |
| Contrato | `app/lib/data/repositories/repositories.dart` | Interfaces abstratas (AuthRepository, TreinoRepository…) |
| Dados (mock) | `app/lib/data/repositories/mock_repositories.dart` | Implementação em memória (Fase 1) |
| Dados (real) | `app/lib/data/repositories/supabase_repositories.dart` | Implementação Supabase (Fase 2) |
| Domínio | `app/lib/core/models/` | Modelos imutáveis |
| Config | `app/lib/core/config/` | `AppConfig` (credenciais via `--dart-define`), contatos institucionais |

## Seleção de backend

`AppConfig.usarSupabase` é verdadeiro quando o build recebe:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Sem as credenciais o app funciona integralmente com mocks — útil para demos, testes e desenvolvimento offline. A troca acontece apenas nos providers; **nenhuma tela muda**.

## Multi-tenancy

Isolamento por linha (*row-level*): toda tabela de negócio tem `empresa_id`, e políticas **RLS** (Row Level Security) garantem que cada requisição só enxerga dados da empresa do usuário autenticado e conforme o seu papel. Detalhes em [modelo-de-dados.md](modelo-de-dados.md).

A chave `anon` é pública por design; a segurança vem das políticas RLS — por isso **nenhuma tabela fica sem RLS habilitado**.

## Realtime

O chat usa Supabase Realtime: assinatura de `INSERT` em `mensagens` filtrada pela conversa. A UI já consome `Stream`-like updates via Riverpod, então a troca do mock é local ao repositório.

## Storage

Buckets `avatares` e `midias-exercicios`, com políticas que restringem leitura/escrita à empresa do usuário. URLs assinadas para mídia privada.

## Segurança e LGPD

- RLS em todas as tabelas; papel do usuário em `perfis.papel`, nunca confiado ao cliente.
- Exclusão de conta: fluxo no app (aba Mais) + processo descrito em [politicas/exclusao-de-conta.md](politicas/exclusao-de-conta.md).
- Dados sensíveis de saúde (avaliações) ficam restritos ao aluno, ao profissional vinculado e ao admin da empresa.

## Decisões e trade-offs

- **Supabase vs NestJS próprio**: elimina servidor para manter, traz Auth/RLS/Realtime prontos. Lógica de negócio que não couber em SQL/RLS irá para **Edge Functions** (Deno) — ex.: cobranças, IA, webhooks.
- **White Label (Premium)**: o tema já é um `ThemeExtension` parametrizável (`app/lib/app/theme/brand_theme.dart`); no futuro, os tokens virão da tabela `empresas`.
