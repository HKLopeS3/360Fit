-- 360Fit — Migration 0004: execução de treino e avaliação ampliada

-- ====================================================== treinos concluídos

create table treinos_concluidos (
  id          uuid primary key default gen_random_uuid(),
  empresa_id  uuid not null references empresas (id) on delete cascade,
  aluno_id    uuid not null references alunos (id) on delete cascade,
  treino_id   uuid references treinos (id) on delete set null,
  nome_treino text not null,
  data        timestamptz not null default now(),
  duracao_min int not null default 0
);

create table series_realizadas (
  id            uuid primary key default gen_random_uuid(),
  conclusao_id  uuid not null references treinos_concluidos (id) on delete cascade,
  indice_item   int not null,
  serie         int not null,
  carga_kg      numeric(6,1) not null default 0,
  repeticoes    int not null default 0
);

create index idx_concluidos_aluno on treinos_concluidos (aluno_id, data);
create index idx_series_conclusao on series_realizadas (conclusao_id);

alter table treinos_concluidos enable row level security;
alter table series_realizadas  enable row level security;

create policy "leitura de conclusoes" on treinos_concluidos for select
  using (private.pode_ver_aluno(aluno_id));

-- o próprio aluno registra a conclusão; equipe também pode (ex.: correção)
create policy "registro de conclusao" on treinos_concluidos for insert
  with check (
    private.pode_ver_aluno(aluno_id)
    and empresa_id = private.empresa_do_usuario()
  );

create policy "leitura de series" on series_realizadas for select
  using (exists (select 1 from treinos_concluidos c
                 where c.id = conclusao_id and private.pode_ver_aluno(c.aluno_id)));

create policy "registro de series" on series_realizadas for insert
  with check (exists (select 1 from treinos_concluidos c
                      where c.id = conclusao_id and private.pode_ver_aluno(c.aluno_id)));

-- ===================================================== avaliação ampliada

alter table avaliacoes_fisicas
  add column medidas jsonb not null default '{}'::jsonb,
  add column observacoes text not null default '';

-- aluno também pode registrar o próprio peso (registro rápido no perfil)
create policy "aluno registra o proprio peso" on registros_peso for insert
  with check (
    aluno_id = private.aluno_do_usuario()
    and empresa_id = private.empresa_do_usuario()
  );
