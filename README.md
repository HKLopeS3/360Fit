# 360Fit

Plataforma SaaS multi-tenant de gestão fitness, saúde e performance para personal trainers, academias, nutricionistas, fisioterapeutas e estúdios.

## Estado atual

**Fase 1** — app Flutter ([app/](app)) com dados mockados e dois perfis no mesmo app (login de demonstração):

- **Aluno**: treino do dia, evolução com gráficos, agenda, chat e área institucional.
- **Personal**: dashboard, gestão de alunos, prescrição de treinos, agenda e área institucional.

**Fase 2 (preparada)** — backend 100% **Supabase**: scripts SQL com RLS multi-tenant prontos em [supabase/](supabase); o app ativa a integração via `--dart-define` (sem credenciais, continua nos mocks).

## Rodando

```bash
cd app
flutter pub get
flutter run -d chrome
```

## Documentação

| | |
|---|---|
| [docs/visao-produto.md](docs/visao-produto.md) | Visão do produto, perfis, módulos, planos e roadmap |
| [docs/arquitetura.md](docs/arquitetura.md) | Arquitetura frontend Flutter + Supabase |
| [docs/modelo-de-dados.md](docs/modelo-de-dados.md) | Modelo de dados e estratégia multi-tenant (RLS) |
| [docs/guia-dev.md](docs/guia-dev.md) | Como rodar, estrutura, convenções e ativação do Supabase |
| [docs/politicas/](docs/politicas) | Política de privacidade, termos de uso e exclusão de conta |

## Contato

- Email: contatoflorestaja@hotmail.com
- Telefone/WhatsApp: (87) 99971-0850
