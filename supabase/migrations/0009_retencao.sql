-- 360Fit — Migration 0009: retenção (fotos de evolução, água) e financeiro manual

-- ========================================================== fotos de evolução

create table fotos_evolucao (
  id         uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  aluno_id   uuid not null references alunos (id) on delete cascade,
  data       date not null default current_date,
  url        text not null,
  observacao text not null default '',
  criado_em  timestamptz not null default now()
);

create index idx_fotos_evolucao_aluno on fotos_evolucao (aluno_id, data);
alter table fotos_evolucao enable row level security;

create policy "leitura de fotos evolucao" on fotos_evolucao for select
  using (private.pode_ver_aluno(aluno_id));
-- o próprio aluno (ou a equipe) registra fotos
create policy "registro de fotos evolucao" on fotos_evolucao for insert
  with check (private.pode_ver_aluno(aluno_id)
              and empresa_id = private.empresa_do_usuario());

insert into storage.buckets (id, name, public)
values ('fotos-evolucao', 'fotos-evolucao', false)
on conflict (id) do nothing;

create policy "membros leem fotos evolucao storage"
  on storage.objects for select
  using (bucket_id = 'fotos-evolucao'
         and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);

create policy "membros sobem fotos evolucao storage"
  on storage.objects for insert
  with check (bucket_id = 'fotos-evolucao'
              and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);

-- ====================================================================== água

create table agua_registros (
  id         uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  aluno_id   uuid not null references alunos (id) on delete cascade,
  data       date not null default current_date,
  copos      int not null default 0,
  unique (aluno_id, data)
);

alter table agua_registros enable row level security;

create policy "leitura de agua" on agua_registros for select
  using (private.pode_ver_aluno(aluno_id));
create policy "aluno registra agua" on agua_registros for all
  using (aluno_id = private.aluno_do_usuario())
  with check (aluno_id = private.aluno_do_usuario()
              and empresa_id = private.empresa_do_usuario());

-- ============================================================== mensalidades

create table mensalidades (
  id          uuid primary key default gen_random_uuid(),
  empresa_id  uuid not null references empresas (id) on delete cascade,
  aluno_id    uuid not null references alunos (id) on delete cascade,
  competencia date not null,          -- 1º dia do mês de referência
  valor       numeric(10,2) not null,
  vencimento  date not null,
  pago_em     date,
  criado_em   timestamptz not null default now(),
  unique (aluno_id, competencia)
);

create index idx_mensalidades_aluno on mensalidades (aluno_id, competencia);
alter table mensalidades enable row level security;

create policy "aluno le as proprias mensalidades" on mensalidades for select
  using (private.pode_ver_aluno(aluno_id));
create policy "equipe gerencia mensalidades" on mensalidades for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());
