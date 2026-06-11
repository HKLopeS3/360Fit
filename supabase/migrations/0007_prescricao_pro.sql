-- 360Fit — Migration 0007: prescrição avançada e periodização

-- variáveis avançadas do item de treino
alter table treino_itens
  add column cadencia text not null default '',          -- ex.: 4010
  add column metodo text not null default 'normal',      -- normal|bi_set|drop_set|cluster|rest_pause
  add column agrupamento int not null default 0;         -- itens com mesmo nº > 0 são executados juntos

-- vídeo demonstrativo do exercício
alter table exercicios
  add column video_url text not null default '';

-- ================================================================= programas

create table programas (
  id          uuid primary key default gen_random_uuid(),
  empresa_id  uuid not null references empresas (id) on delete cascade,
  aluno_id    uuid not null references alunos (id) on delete cascade,
  nome        text not null,
  objetivo    text not null default '',
  -- periodização
  macrociclo  text not null default '',
  mesociclo   text not null default '',
  microciclo  text not null default '',
  inicio      date not null default current_date,
  fim         date not null,
  observacoes text not null default '',
  criado_em   timestamptz not null default now()
);

create index idx_programas_aluno on programas (aluno_id, inicio);
alter table programas enable row level security;

create policy "leitura de programas" on programas for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de programas" on programas for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

alter table treinos
  add column programa_id uuid references programas (id) on delete set null;
