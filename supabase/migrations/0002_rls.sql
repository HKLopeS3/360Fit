-- 360Fit — Migration 0002: Row Level Security (isolamento multi-tenant)
-- Regras: aluno vê só o que é dele; profissional vê os seus alunos;
-- admin_empresa vê tudo da empresa; super_admin opera via service_role.

-- ======================================================= funções auxiliares
-- security definer para não recursionar nas políticas de `perfis`.

create schema if not exists private;

create or replace function private.empresa_do_usuario()
returns uuid
language sql security definer set search_path = public
stable
as $$
  select empresa_id from perfis where id = auth.uid();
$$;

create or replace function private.papel_do_usuario()
returns papel_usuario
language sql security definer set search_path = public
stable
as $$
  select papel from perfis where id = auth.uid();
$$;

create or replace function private.aluno_do_usuario()
returns uuid
language sql security definer set search_path = public
stable
as $$
  select id from alunos where perfil_id = auth.uid();
$$;

-- Aluno acessível ao usuário atual? (dono, profissional responsável ou admin)
create or replace function private.pode_ver_aluno(p_aluno_id uuid)
returns boolean
language sql security definer set search_path = public
stable
as $$
  select exists (
    select 1
    from alunos a
    where a.id = p_aluno_id
      and a.empresa_id = private.empresa_do_usuario()
      and (
        a.perfil_id = auth.uid()
        or a.profissional_id = auth.uid()
        or private.papel_do_usuario() = 'admin_empresa'
      )
  );
$$;

-- Profissional/admin pode gerenciar (escrever) dados do aluno?
create or replace function private.pode_gerenciar_aluno(p_aluno_id uuid)
returns boolean
language sql security definer set search_path = public
stable
as $$
  select exists (
    select 1
    from alunos a
    where a.id = p_aluno_id
      and a.empresa_id = private.empresa_do_usuario()
      and (
        a.profissional_id = auth.uid()
        or private.papel_do_usuario() = 'admin_empresa'
      )
  );
$$;

-- ============================================================ habilitar RLS

alter table empresas            enable row level security;
alter table perfis              enable row level security;
alter table alunos              enable row level security;
alter table exercicios          enable row level security;
alter table treinos             enable row level security;
alter table treino_itens        enable row level security;
alter table agendamentos        enable row level security;
alter table mensagens           enable row level security;
alter table avaliacoes_fisicas  enable row level security;
alter table registros_peso      enable row level security;
alter table registros_carga     enable row level security;

-- =================================================================== empresas

create policy "membros leem a propria empresa"
  on empresas for select
  using (id = private.empresa_do_usuario());

create policy "admin atualiza a propria empresa"
  on empresas for update
  using (id = private.empresa_do_usuario()
         and private.papel_do_usuario() = 'admin_empresa');

-- ===================================================================== perfis

create policy "usuario le o proprio perfil"
  on perfis for select
  using (id = auth.uid());

create policy "membros leem perfis da empresa"
  on perfis for select
  using (empresa_id is not null
         and empresa_id = private.empresa_do_usuario());

create policy "usuario atualiza o proprio perfil"
  on perfis for update
  using (id = auth.uid());

create policy "admin gerencia perfis da empresa"
  on perfis for update
  using (empresa_id = private.empresa_do_usuario()
         and private.papel_do_usuario() = 'admin_empresa');

-- ===================================================================== alunos

create policy "leitura de alunos"
  on alunos for select
  using (
    empresa_id = private.empresa_do_usuario()
    and (
      perfil_id = auth.uid()
      or profissional_id = auth.uid()
      or private.papel_do_usuario() = 'admin_empresa'
    )
  );

create policy "equipe gerencia alunos"
  on alunos for all
  using (
    empresa_id = private.empresa_do_usuario()
    and private.papel_do_usuario() in ('profissional', 'admin_empresa')
  )
  with check (empresa_id = private.empresa_do_usuario());

-- ================================================================= exercicios

create policy "biblioteca global e da empresa"
  on exercicios for select
  using (empresa_id is null
         or empresa_id = private.empresa_do_usuario());

create policy "equipe gerencia exercicios da empresa"
  on exercicios for all
  using (
    empresa_id = private.empresa_do_usuario()
    and private.papel_do_usuario() in ('profissional', 'admin_empresa')
  )
  with check (empresa_id = private.empresa_do_usuario());

-- ============================================== treinos / itens / evolução
-- mesmo padrão: leitura via pode_ver_aluno, escrita via pode_gerenciar_aluno.

create policy "leitura de treinos"  on treinos for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de treinos"   on treinos for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (private.pode_gerenciar_aluno(aluno_id)
              and empresa_id = private.empresa_do_usuario());

create policy "leitura de itens" on treino_itens for select
  using (exists (select 1 from treinos t
                 where t.id = treino_id and private.pode_ver_aluno(t.aluno_id)));
create policy "gestao de itens"  on treino_itens for all
  using (exists (select 1 from treinos t
                 where t.id = treino_id and private.pode_gerenciar_aluno(t.aluno_id)));

create policy "leitura de agendamentos" on agendamentos for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de agendamentos"  on agendamentos for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

create policy "leitura de avaliacoes" on avaliacoes_fisicas for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de avaliacoes"  on avaliacoes_fisicas for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

create policy "leitura de pesos" on registros_peso for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de pesos"  on registros_peso for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

create policy "leitura de cargas" on registros_carga for select
  using (private.pode_ver_aluno(aluno_id));
create policy "gestao de cargas"  on registros_carga for all
  using (private.pode_gerenciar_aluno(aluno_id))
  with check (empresa_id = private.empresa_do_usuario());

-- ================================================================== mensagens
-- aluno e equipe leem a conversa; quem envia escreve como autor.

create policy "leitura da conversa"
  on mensagens for select
  using (private.pode_ver_aluno(aluno_id));

create policy "envio de mensagem"
  on mensagens for insert
  with check (
    private.pode_ver_aluno(aluno_id)
    and autor_perfil_id = auth.uid()
    and empresa_id = private.empresa_do_usuario()
  );
