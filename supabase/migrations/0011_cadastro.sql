-- 360Fit — Migration 0011: cadastro real de profissionais e alunos
-- com login próprio via código de convite.
--
-- Fluxo:
--   - signUp sem `codigo_convite` no metadata  -> novo profissional:
--     cria uma `empresas` nova e o perfil como `admin_empresa` (dono
--     do próprio tenant).
--   - signUp com `codigo_convite` válido -> aluno: vincula à empresa
--     do profissional que gerou o código, papel `aluno`, e marca
--     `alunos.perfil_id` = novo usuário, limpando o código.

alter table alunos add column if not exists codigo_convite text unique;

-- Permite validar um código de convite (sem expor dados do aluno) antes
-- do signUp, para a tela de cadastro mostrar erro de forma amigável.
create or replace function public.validar_codigo_convite(codigo text)
returns boolean
language sql
security definer set search_path = public
as $$
  select exists (
    select 1 from alunos
    where codigo_convite = codigo and perfil_id is null
  );
$$;

grant execute on function public.validar_codigo_convite(text) to anon, authenticated;

create or replace function public.handle_novo_usuario()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_codigo     text := new.raw_user_meta_data ->> 'codigo_convite';
  v_nome       text := coalesce(new.raw_user_meta_data ->> 'nome', '');
  v_aluno      alunos;
  v_empresa_id uuid;
  v_papel      papel_usuario := 'admin_empresa';
begin
  if v_codigo is not null then
    select * into v_aluno from alunos
      where codigo_convite = v_codigo and perfil_id is null;

    if v_aluno.id is null then
      raise exception 'Código de convite inválido';
    end if;

    v_empresa_id := v_aluno.empresa_id;
    v_papel := 'aluno';
    if v_nome = '' then
      v_nome := v_aluno.nome;
    end if;
  else
    insert into empresas (nome) values (coalesce(nullif(v_nome, ''), 'Minha empresa'))
    returning id into v_empresa_id;
  end if;

  insert into perfis (id, empresa_id, papel, nome, email)
  values (new.id, v_empresa_id, v_papel, v_nome, new.email);

  if v_aluno.id is not null then
    update alunos set perfil_id = new.id, codigo_convite = null
      where id = v_aluno.id;
  end if;

  return new;
end;
$$;
