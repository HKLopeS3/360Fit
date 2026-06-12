# Modelo de Dados — PostgreSQL (Supabase)

SQL completo em [`supabase/migrations/`](../supabase/migrations/); seed de demonstração em [`supabase/seed.sql`](../supabase/seed.sql).

## Diagrama (entidades principais)

```
empresas 1──n perfis (1──1 auth.users)
empresas 1──n alunos n──1 perfis (profissional responsável)
alunos   1──n treinos 1──n treino_itens n──1 exercicios
alunos   1──n agendamentos
alunos   1──n mensagens
alunos   1──n avaliacoes_fisicas / registros_peso / registros_carga
```

## Tabelas

| Tabela | Campos-chave | Observações |
|---|---|---|
| `empresas` | id, nome, plano (basic/pro/premium), tokens de marca | Tenant raiz; tokens de marca alimentam o White Label |
| `perfis` | id = `auth.users.id`, empresa_id, papel, nome, email | Criada por trigger no signup; `papel`: super_admin, admin_empresa, profissional, aluno |
| `alunos` | id, empresa_id, perfil_id?, profissional_id, objetivo, … | `perfil_id` nulo até o aluno ativar o acesso ao app |
| `exercicios` | id, empresa_id?, nome, grupo_muscular, equipamento | `empresa_id` nulo = biblioteca global da plataforma |
| `treinos` | id, empresa_id, aluno_id, nome, foco, dias_semana int[] | |
| `treino_itens` | treino_id, exercicio_id, ordem, series, repeticoes, carga_kg, descanso_seg, **cadencia**, **metodo**, **agrupamento** | Métodos: bi_set/drop_set/cluster/rest_pause (0007) |
| `agendamentos` | id, empresa_id, aluno_id, profissional_id, tipo, data_hora, local, **status** | `tipo`: treino/avaliacao/consulta; `status`: pendente/confirmado/cancelado (migration 0005) |
| `mensagens` | id, empresa_id, aluno_id, autor_perfil_id, texto, criada_em | Realtime habilitado |
| `avaliacoes_fisicas` | id, empresa_id, aluno_id, data, peso_kg, gordura_pct, massa_magra_kg, **medidas jsonb**, **observacoes** | Dado sensível de saúde; medidas = circunferências em cm |
| `treinos_concluidos` | id, empresa_id, aluno_id, treino_id, nome_treino, data, duracao_min, **pse**, **dor_articular**, **dor_relato** | Execuções + feedback Borg/dor (migrations 0004/0008) |
| `anamneses` | aluno_id, parq jsonb, lesoes, cirurgias, medicamentos, horas_sono, habitos | PAR-Q digital (0006) |
| `fotos_postura` / `fotos_evolucao` | aluno_id, data, angulo/observacao, url | Fotogrametria e linha do tempo (0006/0009); buckets próprios |
| `programas` | aluno_id, nome, objetivo, macro/meso/microciclo, inicio, fim | Periodização (0007); `treinos.programa_id` |
| `agua_registros` | aluno_id, data, copos (unique aluno+dia) | Hidratação (0009) |
| `mensalidades` | aluno_id, competencia, valor, vencimento, pago_em | Financeiro manual (0009) |
| `postagens` / `curtidas` | aluno_id, texto, foto_url, status pendente/aprovada/rejeitada | Feed moderado (0010); bucket fotos-feed |
| `series_realizadas` | conclusao_id, indice_item, serie, carga_kg, repeticoes | Séries efetivamente feitas em cada conclusão |
| `registros_peso` | id, empresa_id, aluno_id, data, peso_kg | |
| `registros_carga` | id, empresa_id, aluno_id, exercicio_id, data, carga_kg | |

Convenções: `snake_case`, `id uuid default gen_random_uuid()`, `criado_em timestamptz default now()`, FKs com `on delete cascade` a partir do aluno.

## Estratégia multi-tenant (RLS)

Funções auxiliares (schema `private`, `security definer`) evitam recursão nas políticas:

- `private.empresa_do_usuario()` → `empresa_id` do perfil autenticado
- `private.papel_do_usuario()` → papel do perfil autenticado
- `private.aluno_do_usuario()` → id em `alunos` quando o usuário é aluno

Regras por papel (aplicadas em todas as tabelas de negócio):

| Papel | Leitura | Escrita |
|---|---|---|
| aluno | apenas linhas do próprio `aluno_id` | mensagens próprias; conclusão de treino e séries; registro do próprio peso; confirmação de presença em agendamento |
| profissional | linhas de alunos com `profissional_id = auth.uid()` | treinos, agendamentos, avaliações, mensagens dos seus alunos |
| admin_empresa | tudo da `empresa_id` dele | tudo da empresa (inclusive alunos e equipe) |
| super_admin | global (via `service_role`, fora do app) | global |

**Toda tabela tem `enable row level security` + políticas explícitas.** A chave `anon` sem sessão não lê nada.

## Mapeamento mock → Supabase

Os modelos Dart (`app/lib/core/models/models.dart`) correspondem 1:1 às tabelas; os repositórios Supabase fazem o de/para de `snake_case` ↔ campos Dart. O seed reproduz os dados dos mocks (Carlos Mendes, João Silva, 8 alunos, 30 exercícios) para a transição ser visualmente idêntica.
