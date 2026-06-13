-- 360Fit — Migration 0012: perfil do profissional e configuração
-- financeira da empresa.
--
-- - `perfis`: dados profissionais (CREF, CPF, foto) e um código de
--   convite fixo do profissional — novos alunos que se cadastrarem com
--   esse código entram automaticamente vinculados a ele/sua empresa,
--   sem precisar de pré-cadastro.
-- - `empresas`: valores de mensalidade cobrada dos alunos + validade, e
--   a validade da assinatura do sistema (informativo, sem gateway).

alter table perfis
  add column if not exists cref           text,
  add column if not exists cpf            text,
  add column if not exists foto_url       text,
  add column if not exists codigo_convite text unique;

alter table empresas
  add column if not exists mensalidade_valor         numeric(10,2) not null default 0,
  add column if not exists mensalidade_validade_dias int not null default 30,
  add column if not exists assinatura_validade       date;

-- Gera um código de 8 caracteres no mesmo alfabeto usado pelo Flutter ao
-- criar `alunos.codigo_convite` (sem I/O/0/1 para evitar ambiguidade).
create or replace function private.gerar_codigo_convite()
returns text
language sql
as $$
  select string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
           (random() * 32)::int + 1, 1),
    ''
  )
  from generate_series(1, 8);
$$;

create or replace function public.validar_codigo_convite(codigo text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from alunos
    where codigo_convite = codigo and perfil_id is null
  ) or exists (
    select 1 from perfis
    where codigo_convite = codigo and papel in ('profissional', 'admin_empresa')
  );
$$;

create or replace function public.handle_novo_usuario()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_codigo       text := new.raw_user_meta_data ->> 'codigo_convite';
  v_nome         text := coalesce(new.raw_user_meta_data ->> 'nome', '');
  v_aluno        alunos;
  v_profissional perfis;
  v_empresa_id   uuid;
  v_papel        papel_usuario := 'admin_empresa';
  v_meu_codigo   text;
begin
  if v_codigo is not null then
    select * into v_aluno from alunos
      where codigo_convite = v_codigo and perfil_id is null;

    if v_aluno.id is not null then
      v_empresa_id := v_aluno.empresa_id;
      v_papel := 'aluno';
      if v_nome = '' then
        v_nome := v_aluno.nome;
      end if;
    else
      select * into v_profissional from perfis
        where codigo_convite = v_codigo
          and papel in ('profissional', 'admin_empresa');

      if v_profissional.id is null then
        raise exception 'Código de convite inválido';
      end if;

      v_empresa_id := v_profissional.empresa_id;
      v_papel := 'aluno';
    end if;
  else
    insert into empresas (nome, assinatura_validade)
      values (coalesce(nullif(v_nome, ''), 'Minha empresa'), current_date + 30)
      returning id into v_empresa_id;

    -- código de convite fixo do profissional, para novos alunos se
    -- cadastrarem direto sem pré-cadastro.
    loop
      v_meu_codigo := private.gerar_codigo_convite();
      exit when not exists (
        select 1 from perfis where codigo_convite = v_meu_codigo
      );
    end loop;
  end if;

  insert into perfis (id, empresa_id, papel, nome, email, codigo_convite)
  values (new.id, v_empresa_id, v_papel, v_nome, new.email, v_meu_codigo);

  if v_aluno.id is not null then
    update alunos set perfil_id = new.id, codigo_convite = null
      where id = v_aluno.id;
  elsif v_profissional.id is not null then
    insert into alunos (empresa_id, profissional_id, perfil_id, nome)
    values (v_empresa_id, v_profissional.id, new.id, v_nome);
  end if;

  return new;
end;
$$;
