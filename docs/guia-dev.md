# Guia de Desenvolvimento

## Pré-requisitos

- Flutter 3.44+ (`C:\dev\flutter` nesta máquina, já no PATH).
- Alvo atual: **web** (Chrome). Android/iOS exigem instalar os toolchains.

## Rodando

```bash
cd app
flutter pub get
flutter run -d chrome            # desenvolvimento
flutter run -d web-server --release --web-port=8077   # demo estável
```

> No Windows desta máquina a porta 5757 é reservada pelo sistema; use 8077 (já configurada em `.claude/launch.json`).

## Qualidade

```bash
flutter analyze   # deve retornar zero issues
flutter test      # smoke tests de navegação
```

## Estrutura de pastas

```
app/lib/
├── main.dart                 # bootstrap (intl pt_BR, ProviderScope, Supabase se configurado)
├── app/                      # MaterialApp, router (go_router), tema (ThemeExtension)
├── core/
│   ├── config/               # AppConfig (dart-define), contatos institucionais
│   ├── models/               # modelos de domínio
│   └── mock/                 # fixtures da Fase 1
├── data/
│   ├── providers.dart        # providers Riverpod (escolhem mock × Supabase)
│   └── repositories/         # interfaces + implementações mock e supabase
├── features/                 # telas por área (auth, aluno, personal, institucional)
└── shared/                   # widgets reutilizáveis (AsyncView, MetricCard, …)
```

Convenções: código e identificadores de domínio em pt-BR (`Treino`, `alunoId`); arquivos `snake_case`; uma tela por arquivo; UI nunca importa `core/mock` nem implementações concretas de repositório — só interfaces via providers.

## Ativando o Supabase (Fase 2)

1. Crie um projeto em [supabase.com](https://supabase.com) (região São Paulo).
2. No **SQL Editor**, execute na ordem os arquivos de [`supabase/migrations/`](../supabase/migrations/) e depois [`supabase/seed.sql`](../supabase/seed.sql).
3. Em *Project Settings → API*, copie a **URL** e a **anon key**.
4. Rode com:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=SUA_ANON_KEY
```

Sem esses defines o app usa os mocks — é o modo padrão de desenvolvimento. A anon key é pública por design; a segurança vem das políticas RLS (nunca desabilite RLS em tabela nova).

## Documentação

| Documento | Conteúdo |
|---|---|
| [visao-produto.md](visao-produto.md) | Visão SaaS, perfis, módulos, planos, roadmap |
| [arquitetura.md](arquitetura.md) | Camadas do app + Supabase, segurança, decisões |
| [modelo-de-dados.md](modelo-de-dados.md) | Tabelas, RLS multi-tenant, mapeamento mock→real |
| [politicas/](politicas/) | Privacidade, termos e exclusão de conta (lojas) |
