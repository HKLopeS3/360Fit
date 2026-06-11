-- 360Fit — Migration 0006: avaliação física profissional

-- protocolos, dobras, bioimpedância e testes na avaliação
alter table avaliacoes_fisicas
  add column protocolo text not null default '',
  add column dobras jsonb not null default '{}'::jsonb,
  add column bioimpedancia jsonb not null default '{}'::jsonb,
  add column testes jsonb not null default '{}'::jsonb;

-- sexo e nascimento do aluno (necessários para os protocolos e aniversários)
alter table alunos
  add column sexo text not null default 'masculino',
  add column nascimento date;

-- ==================================================================== anamnese

create table anamneses (
  id           uuid primary key default gen_random_uuid(),
  empresa_id   uuid not null references empresas (id) on delete cascade,
  aluno_id     uuid not null references alunos (id) on delete cascade,
  data         date not null default current_date,
  parq         jsonb not null default '[]'::jsonb,  -- 7 booleanos
  lesoes       text not null default '',
  cirurgias    text not null default '',
  medicamentos text not null default '',
  horas_sono   int not null default 7,
  habitos      text not null default '',
  criado_em    timestamptz not null default now()
);

create index idx_anamneses_aluno on anamneses (aluno_id, data);
alter table anamneses enable row level security;

create policy "leitura de anamneses" on anamneses for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de anamneses" on anamneses for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

-- ============================================================ fotos posturais

create table fotos_postura (
  id         uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  aluno_id   uuid not null references alunos (id) on delete cascade,
  data       date not null default current_date,
  angulo     text not null,   -- frente | costas | perfilDireito | perfilEsquerdo
  url        text not null,
  criado_em  timestamptz not null default now()
);

create index idx_fotos_postura_aluno on fotos_postura (aluno_id, data);
alter table fotos_postura enable row level security;

create policy "leitura de fotos postura" on fotos_postura for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de fotos postura" on fotos_postura for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

insert into storage.buckets (id, name, public)
values ('fotos-avaliacao', 'fotos-avaliacao', false)
on conflict (id) do nothing;

create policy "membros leem fotos de avaliacao"
  on storage.objects for select
  using (bucket_id = 'fotos-avaliacao'
         and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);

create policy "equipe gerencia fotos de avaliacao"
  on storage.objects for all
  using (bucket_id = 'fotos-avaliacao'
         and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
         and private.papel_do_usuario() in ('profissional', 'admin_empresa'))
  with check (bucket_id = 'fotos-avaliacao'
              and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);
