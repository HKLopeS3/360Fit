-- 360Fit — Migration 0001: schema base multi-tenant
-- Execute no SQL Editor do Supabase (ou via supabase db push).

-- ====================================================================== tipos

create type papel_usuario as enum ('super_admin', 'admin_empresa', 'profissional', 'aluno');
create type plano_saas as enum ('basic', 'pro', 'premium');
create type tipo_agendamento as enum ('treino', 'avaliacao', 'consulta');

-- =================================================================== empresas

create table empresas (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  plano       plano_saas not null default 'basic',
  -- tokens de marca para White Label (Premium)
  marca_nome  text,
  marca_cores jsonb,
  criado_em   timestamptz not null default now()
);

-- ===================================================================== perfis
-- 1:1 com auth.users; criado por trigger no signup.

create table perfis (
  id         uuid primary key references auth.users (id) on delete cascade,
  empresa_id uuid references empresas (id) on delete cascade,
  papel      papel_usuario not null default 'aluno',
  nome       text not null default '',
  email      text not null default '',
  criado_em  timestamptz not null default now()
);

create or replace function public.handle_novo_usuario()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into perfis (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nome', ''), new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_novo_usuario();

-- ===================================================================== alunos

create table alunos (
  id                  uuid primary key default gen_random_uuid(),
  empresa_id          uuid not null references empresas (id) on delete cascade,
  -- preenchido quando o aluno ativa o acesso ao app
  perfil_id           uuid references perfis (id) on delete set null,
  profissional_id     uuid references perfis (id) on delete set null,
  nome                text not null,
  idade               int,
  objetivo            text not null default '',
  inicio              date not null default current_date,
  frequencia_semanal  int not null default 0,
  peso_atual_kg       numeric(5,1),
  risco_evasao        boolean not null default false,
  criado_em           timestamptz not null default now()
);

create index idx_alunos_empresa on alunos (empresa_id);
create index idx_alunos_profissional on alunos (profissional_id);

-- ================================================================= exercicios
-- empresa_id nulo = biblioteca global da plataforma.

create table exercicios (
  id             uuid primary key default gen_random_uuid(),
  empresa_id     uuid references empresas (id) on delete cascade,
  nome           text not null,
  grupo_muscular text not null,
  equipamento    text not null default '',
  criado_em      timestamptz not null default now()
);

-- ==================================================================== treinos

create table treinos (
  id          uuid primary key default gen_random_uuid(),
  empresa_id  uuid not null references empresas (id) on delete cascade,
  aluno_id    uuid not null references alunos (id) on delete cascade,
  nome        text not null,
  foco        text not null default '',
  dias_semana int[] not null default '{}',   -- 1=segunda … 7=domingo
  criado_em   timestamptz not null default now()
);

create index idx_treinos_aluno on treinos (aluno_id);

create table treino_itens (
  id           uuid primary key default gen_random_uuid(),
  treino_id    uuid not null references treinos (id) on delete cascade,
  exercicio_id uuid not null references exercicios (id),
  ordem        int not null default 0,
  series       int not null default 3,
  repeticoes   text not null default '10-12',
  carga_kg     numeric(6,1) not null default 0,
  descanso_seg int not null default 60
);

create index idx_treino_itens_treino on treino_itens (treino_id);

-- =============================================================== agendamentos

create table agendamentos (
  id              uuid primary key default gen_random_uuid(),
  empresa_id      uuid not null references empresas (id) on delete cascade,
  aluno_id        uuid not null references alunos (id) on delete cascade,
  profissional_id uuid references perfis (id) on delete set null,
  titulo          text not null,
  tipo            tipo_agendamento not null default 'treino',
  data_hora       timestamptz not null,
  local           text not null default '',
  criado_em       timestamptz not null default now()
);

create index idx_agendamentos_aluno on agendamentos (aluno_id);
create index idx_agendamentos_data on agendamentos (empresa_id, data_hora);

-- ================================================================== mensagens

create table mensagens (
  id              uuid primary key default gen_random_uuid(),
  empresa_id      uuid not null references empresas (id) on delete cascade,
  aluno_id        uuid not null references alunos (id) on delete cascade,
  autor_perfil_id uuid references perfis (id) on delete set null,
  texto           text not null,
  criada_em       timestamptz not null default now()
);

create index idx_mensagens_aluno on mensagens (aluno_id, criada_em);

-- habilita realtime para o chat
alter publication supabase_realtime add table mensagens;

-- =================================================================== evolução

create table avaliacoes_fisicas (
  id             uuid primary key default gen_random_uuid(),
  empresa_id     uuid not null references empresas (id) on delete cascade,
  aluno_id       uuid not null references alunos (id) on delete cascade,
  data           date not null default current_date,
  peso_kg        numeric(5,1) not null,
  gordura_pct    numeric(4,1),
  massa_magra_kg numeric(5,1),
  criado_em      timestamptz not null default now()
);

create table registros_peso (
  id         uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas (id) on delete cascade,
  aluno_id   uuid not null references alunos (id) on delete cascade,
  data       date not null default current_date,
  peso_kg    numeric(5,1) not null
);

create table registros_carga (
  id           uuid primary key default gen_random_uuid(),
  empresa_id   uuid not null references empresas (id) on delete cascade,
  aluno_id     uuid not null references alunos (id) on delete cascade,
  exercicio_id uuid not null references exercicios (id),
  data         date not null default current_date,
  carga_kg     numeric(6,1) not null
);

create index idx_avaliacoes_aluno on avaliacoes_fisicas (aluno_id, data);
create index idx_pesos_aluno on registros_peso (aluno_id, data);
create index idx_cargas_aluno on registros_carga (aluno_id, exercicio_id, data);
