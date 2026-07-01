-- ============================================================
-- 360Fit Academy — Migration 0001: Schema inicial
-- Projeto: Supabase independente (academy.360fit)
-- ============================================================

-- ── Extensões ────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ── Schema privado para funções internas ─────────────────────
create schema if not exists private;

-- ============================================================
-- 1. ACADEMIAS
-- Cada conta no sistema representa uma academia.
-- ============================================================
create table academias (
  id            uuid primary key default uuid_generate_v4(),
  nome          text not null,
  cnpj          text,
  telefone      text,
  email         text,
  logo_url      text,
  endereco      text,
  cidade        text,
  estado        text,
  cep           text,
  -- Assinatura do sistema 360Fit Academy
  plano_sistema text not null default 'trial',   -- trial | basic | pro
  assinatura_validade date default (current_date + interval '30 days'),
  created_at    timestamptz not null default now()
);

-- ── RLS ──────────────────────────────────────────────────────
alter table academias enable row level security;

-- Gestor só vê/edita a própria academia
create policy "academia: gestor vê a própria"
  on academias for select
  using (
    id in (
      select academia_id from perfis
      where auth_user_id = auth.uid()
    )
  );

create policy "academia: gestor atualiza a própria"
  on academias for update
  using (
    id in (
      select academia_id from perfis
      where auth_user_id = auth.uid()
        and papel = 'gestor'
    )
  );

-- ============================================================
-- 2. PERFIS (usuários do painel: gestor, recepcionista)
-- ============================================================
create table perfis (
  id            uuid primary key default uuid_generate_v4(),
  auth_user_id  uuid not null references auth.users(id) on delete cascade,
  academia_id   uuid not null references academias(id) on delete cascade,
  nome          text not null,
  email         text not null,
  papel         text not null default 'recepcionista', -- gestor | recepcionista
  foto_url      text,
  ativo         boolean not null default true,
  created_at    timestamptz not null default now(),
  unique (auth_user_id)
);

alter table perfis enable row level security;

create policy "perfis: usuário vê o próprio"
  on perfis for select
  using (auth_user_id = auth.uid());

create policy "perfis: gestor vê todos da academia"
  on perfis for select
  using (
    academia_id in (
      select academia_id from perfis
      where auth_user_id = auth.uid()
        and papel = 'gestor'
    )
  );

create policy "perfis: gestor insere na academia"
  on perfis for insert
  with check (
    academia_id in (
      select academia_id from perfis
      where auth_user_id = auth.uid()
        and papel = 'gestor'
    )
  );

create policy "perfis: usuário atualiza o próprio"
  on perfis for update
  using (auth_user_id = auth.uid());

-- ============================================================
-- 3. PLANOS oferecidos pela academia
-- ============================================================
create table planos (
  id              uuid primary key default uuid_generate_v4(),
  academia_id     uuid not null references academias(id) on delete cascade,
  nome            text not null,                 -- ex: "Mensal Musculação"
  tipo            text not null default 'mensal', -- mensal | trimestral | semestral | anual
  duracao_dias    int  not null default 30,
  valor           numeric(10,2) not null,
  descricao       text,
  ativo           boolean not null default true,
  created_at      timestamptz not null default now()
);

alter table planos enable row level security;

create policy "planos: membros da academia veem"
  on planos for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "planos: gestor gerencia"
  on planos for all
  using (
    academia_id in (
      select academia_id from perfis
      where auth_user_id = auth.uid() and papel = 'gestor'
    )
  );

-- ============================================================
-- 4. ALUNOS
-- ============================================================
create table alunos (
  id               uuid primary key default uuid_generate_v4(),
  academia_id      uuid not null references academias(id) on delete cascade,
  nome             text not null,
  cpf              text,
  email            text,
  telefone         text,
  data_nascimento  date,
  sexo             text,                          -- masculino | feminino | outro
  objetivo         text,
  foto_url         text,
  professor        text,
  -- Endereço
  cep              text,
  logradouro       text,
  numero           text,
  complemento      text,
  bairro           text,
  cidade           text,
  estado           text,
  -- Status
  ativo            boolean not null default true,
  bloqueado        boolean not null default false,
  motivo_bloqueio  text,
  -- QR code de check-in (gerado no cadastro)
  codigo_checkin   text unique default encode(gen_random_bytes(6), 'hex'),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table alunos enable row level security;

create policy "alunos: membros veem da academia"
  on alunos for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "alunos: membros inserem na academia"
  on alunos for insert
  with check (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "alunos: membros atualizam da academia"
  on alunos for update
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "alunos: gestor exclui"
  on alunos for delete
  using (
    academia_id in (
      select academia_id from perfis
      where auth_user_id = auth.uid() and papel = 'gestor'
    )
  );

-- Trigger updated_at
create or replace function private.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger alunos_updated_at
  before update on alunos
  for each row execute function private.set_updated_at();

-- ============================================================
-- 5. CONTRATOS (vínculo aluno ↔ plano)
-- ============================================================
create table contratos (
  id           uuid primary key default uuid_generate_v4(),
  academia_id  uuid not null references academias(id) on delete cascade,
  aluno_id     uuid not null references alunos(id) on delete cascade,
  plano_id     uuid not null references planos(id),
  inicio       date not null default current_date,
  fim          date not null,
  situacao     text not null default 'ativo', -- ativo | encerrado | suspenso | bloqueado | cancelado
  observacoes  text,
  created_at   timestamptz not null default now()
);

alter table contratos enable row level security;

create policy "contratos: membros veem da academia"
  on contratos for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "contratos: membros gerenciam da academia"
  on contratos for all
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 6. MENSALIDADES
-- ============================================================
create table mensalidades (
  id           uuid primary key default uuid_generate_v4(),
  academia_id  uuid not null references academias(id) on delete cascade,
  aluno_id     uuid not null references alunos(id) on delete cascade,
  contrato_id  uuid references contratos(id),
  descricao    text not null default 'Mensalidade',
  valor        numeric(10,2) not null,
  vencimento   date not null,
  pago_em      timestamptz,
  forma_pag    text,  -- dinheiro | pix | cartao | boleto
  observacoes  text,
  created_at   timestamptz not null default now()
);

alter table mensalidades enable row level security;

create policy "mensalidades: membros veem da academia"
  on mensalidades for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "mensalidades: membros gerenciam da academia"
  on mensalidades for all
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 7. TURMAS / AULAS
-- ============================================================
create table turmas (
  id           uuid primary key default uuid_generate_v4(),
  academia_id  uuid not null references academias(id) on delete cascade,
  nome         text not null,
  professor    text,
  sala         text,
  hora_inicio  time not null,
  hora_fim     time,
  dias_semana  int[] not null default '{}', -- 1=seg … 7=dom (ISO)
  vagas        int not null default 20,
  cor          text default '#6C3FC5',       -- cor no calendário
  ativo        boolean not null default true,
  created_at   timestamptz not null default now()
);

alter table turmas enable row level security;

create policy "turmas: membros veem da academia"
  on turmas for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "turmas: membros gerenciam da academia"
  on turmas for all
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 8. INSCRIÇÕES (aluno ↔ turma)
-- ============================================================
create table inscricoes (
  id          uuid primary key default uuid_generate_v4(),
  academia_id uuid not null references academias(id) on delete cascade,
  turma_id    uuid not null references turmas(id) on delete cascade,
  aluno_id    uuid not null references alunos(id) on delete cascade,
  ativo       boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (turma_id, aluno_id)
);

alter table inscricoes enable row level security;

create policy "inscricoes: membros gerenciam da academia"
  on inscricoes for all
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 9. CHECK-INS
-- ============================================================
create table checkins (
  id          uuid primary key default uuid_generate_v4(),
  academia_id uuid not null references academias(id) on delete cascade,
  aluno_id    uuid not null references alunos(id) on delete cascade,
  turma_id    uuid references turmas(id),     -- null = entrada livre
  quando      timestamptz not null default now(),
  canal       text default 'manual'           -- manual | qrcode | catraca
);

alter table checkins enable row level security;

create policy "checkins: membros veem da academia"
  on checkins for select
  using (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

create policy "checkins: membros inserem da academia"
  on checkins for insert
  with check (
    academia_id in (
      select academia_id from perfis where auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 10. TRIGGER: novo usuário → cria academia + perfil gestor
-- ============================================================
create or replace function private.handle_novo_usuario_academia()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_academia_id  uuid;
  v_nome         text;
  v_academia_nome text;
begin
  -- Extrai metadados passados no signUp
  v_nome          := coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1));
  v_academia_nome := coalesce(new.raw_user_meta_data->>'academia_nome', v_nome || ' Academia');

  -- Só executa se não veio código de convite (gestor fundador)
  if new.raw_user_meta_data->>'tipo' = 'gestor' then
    -- Cria a academia
    insert into academias (nome, email)
    values (v_academia_nome, new.email)
    returning id into v_academia_id;

    -- Cria o perfil gestor
    insert into perfis (auth_user_id, academia_id, nome, email, papel)
    values (new.id, v_academia_id, v_nome, new.email, 'gestor');

  elsif new.raw_user_meta_data->>'tipo' = 'recepcionista' then
    -- Convite: academia_id deve vir nos metadados
    v_academia_id := (new.raw_user_meta_data->>'academia_id')::uuid;
    insert into perfis (auth_user_id, academia_id, nome, email, papel)
    values (new.id, v_academia_id, v_nome, new.email, 'recepcionista');
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created_academy
  after insert on auth.users
  for each row execute function private.handle_novo_usuario_academia();

-- ============================================================
-- 11. TRIGGER: novo contrato → gera mensalidades automaticamente
-- ============================================================
create or replace function private.gerar_mensalidades_contrato()
returns trigger
language plpgsql security definer
set search_path = public
as $$
declare
  v_plano       record;
  v_vencimento  date;
  v_parcelas    int;
  i             int;
begin
  select * into v_plano from planos where id = new.plano_id;

  -- Número de parcelas = duração / 30 (mínimo 1)
  v_parcelas := greatest(1, v_plano.duracao_dias / 30);

  for i in 1..v_parcelas loop
    v_vencimento := new.inicio + (interval '30 days' * i);
    insert into mensalidades (academia_id, aluno_id, contrato_id, descricao, valor, vencimento)
    values (
      new.academia_id,
      new.aluno_id,
      new.id,
      v_plano.nome || ' — parcela ' || i || '/' || v_parcelas,
      v_plano.valor,
      v_vencimento
    );
  end loop;

  return new;
end;
$$;

create trigger on_contrato_criado
  after insert on contratos
  for each row execute function private.gerar_mensalidades_contrato();

-- ============================================================
-- 12. VIEW: situação financeira dos alunos (útil para dashboard)
-- ============================================================
create or replace view vw_alunos_situacao as
select
  a.id,
  a.academia_id,
  a.nome,
  a.email,
  a.telefone,
  a.ativo,
  a.bloqueado,
  a.foto_url,
  -- última mensalidade em aberto
  (
    select vencimento from mensalidades m
    where m.aluno_id = a.id and m.pago_em is null
    order by vencimento asc limit 1
  ) as prox_vencimento,
  -- situação: emDia | vencendo | inadimplente | semContrato
  case
    when (
      select count(*) from mensalidades m
      where m.aluno_id = a.id and m.pago_em is null
        and m.vencimento < current_date
    ) > 0 then 'inadimplente'
    when (
      select count(*) from mensalidades m
      where m.aluno_id = a.id and m.pago_em is null
        and m.vencimento between current_date and current_date + 5
    ) > 0 then 'vencendo'
    when (
      select count(*) from contratos c
      where c.aluno_id = a.id and c.situacao = 'ativo'
        and c.fim >= current_date
    ) > 0 then 'emDia'
    else 'semContrato'
  end as situacao,
  -- último check-in
  (
    select quando from checkins ci
    where ci.aluno_id = a.id
    order by quando desc limit 1
  ) as ultimo_checkin
from alunos a;

-- ============================================================
-- 13. STORAGE — bucket para fotos de alunos e logo da academia
-- ============================================================
insert into storage.buckets (id, name, public)
values
  ('academia-avatares', 'academia-avatares', true),
  ('academia-logos',    'academia-logos',    true)
on conflict (id) do nothing;

-- Políticas de storage: membros da academia fazem upload
create policy "avatares: upload por membros"
  on storage.objects for insert
  with check (bucket_id = 'academia-avatares' and auth.role() = 'authenticated');

create policy "avatares: leitura pública"
  on storage.objects for select
  using (bucket_id = 'academia-avatares');

create policy "logos: upload por gestor"
  on storage.objects for insert
  with check (bucket_id = 'academia-logos' and auth.role() = 'authenticated');

create policy "logos: leitura pública"
  on storage.objects for select
  using (bucket_id = 'academia-logos');
