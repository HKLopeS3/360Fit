-- 360Fit — Migration 0010: feed social com moderação do personal

create type status_postagem as enum ('pendente', 'aprovada', 'rejeitada');

create table postagens (
  id              uuid primary key default gen_random_uuid(),
  empresa_id      uuid not null references empresas (id) on delete cascade,
  aluno_id        uuid not null references alunos (id) on delete cascade,
  autor_perfil_id uuid references perfis (id) on delete set null,
  texto           text not null default '',
  foto_url        text not null default '',
  status          status_postagem not null default 'pendente',
  motivo_rejeicao text not null default '',
  criada_em       timestamptz not null default now(),
  moderada_em     timestamptz
);

create index idx_postagens_empresa on postagens (empresa_id, status, criada_em);
alter table postagens enable row level security;

-- aluno vê as aprovadas da empresa e as próprias (qualquer status)
create policy "leitura do feed" on postagens for select
  using (
    empresa_id = private.empresa_do_usuario()
    and (status = 'aprovada'
         or aluno_id = private.aluno_do_usuario()
         or private.papel_do_usuario() in ('profissional', 'admin_empresa'))
  );

create policy "aluno publica a propria postagem" on postagens for insert
  with check (
    aluno_id = private.aluno_do_usuario()
    and empresa_id = private.empresa_do_usuario()
    and autor_perfil_id = auth.uid()
  );

create policy "equipe modera postagens" on postagens for update
  using (empresa_id = private.empresa_do_usuario()
         and private.papel_do_usuario() in ('profissional', 'admin_empresa'));

-- ==================================================================== curtidas

create table curtidas (
  postagem_id uuid not null references postagens (id) on delete cascade,
  perfil_id   uuid not null references perfis (id) on delete cascade,
  criada_em   timestamptz not null default now(),
  primary key (postagem_id, perfil_id)
);

alter table curtidas enable row level security;

create policy "leitura de curtidas" on curtidas for select
  using (exists (select 1 from postagens p
                 where p.id = postagem_id
                   and p.empresa_id = private.empresa_do_usuario()));

create policy "curtir como si mesmo" on curtidas for insert
  with check (
    perfil_id = auth.uid()
    and exists (select 1 from postagens p
                where p.id = postagem_id and p.status = 'aprovada'
                  and p.empresa_id = private.empresa_do_usuario())
  );

create policy "descurtir a propria curtida" on curtidas for delete
  using (perfil_id = auth.uid());

-- ======================================================================= fotos

insert into storage.buckets (id, name, public)
values ('fotos-feed', 'fotos-feed', false)
on conflict (id) do nothing;

create policy "membros leem fotos do feed"
  on storage.objects for select
  using (bucket_id = 'fotos-feed'
         and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);

create policy "membros sobem fotos do feed"
  on storage.objects for insert
  with check (bucket_id = 'fotos-feed'
              and (storage.foldername(name))[1] = private.empresa_do_usuario()::text);
