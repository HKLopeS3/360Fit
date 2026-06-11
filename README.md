# 360Fit

Plataforma SaaS multi-tenant de gestão fitness, saúde e performance para personal trainers, academias, nutricionistas, fisioterapeutas e estúdios.

## Estado atual

Fase 1 — validação de UX: app mobile Flutter (`app/`) com **dados mockados**, atendendo duas personas no mesmo app:

- **Aluno**: treino do dia, evolução (gráficos), agenda e chat.
- **Personal Trainer**: dashboard, gestão de alunos, prescrição de treinos e agenda.

O login é mockado e apenas alterna o perfil. Não há backend ainda — os dados vêm de repositórios mock (`app/lib/data/repositories/`), desenhados como interfaces abstratas para troca futura pela API NestJS sem alterar a UI.

## Rodando

```bash
cd app
flutter pub get
flutter run -d chrome
```

## Roadmap (visão)

1. **Fase 1** — App Flutter mockado (atual)
2. **Fase 2** — Backend NestJS + PostgreSQL multi-tenant, autenticação real
3. **Fase 3** — Módulos Nutrição e Fisioterapia, dashboard executivo web
4. **Fase 4** — Financeiro, CRM, White Label, IA de acompanhamento
