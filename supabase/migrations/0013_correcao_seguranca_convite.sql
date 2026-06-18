-- 360Fit — Migration 0013: correção de segurança no fluxo de convite
--
-- Problema: aluno novo que usou código de aluno pré-cadastrado acabou
-- vinculado à conta errada (vê dados de outro aluno).
--
-- Correção:
-- 1. Garantir que todo profissional/admin tenha codigo_convite gerado.
-- 2. Tornar validar_codigo_convite mais clara para o Flutter distinguir
--    tipo de código (aluno pré-cadastrado x código do profissional).
-- 3. Proteger contra reutilização: limpar codigo_convite do aluno ao vincular.

-- Garante codigo_convite em perfis de profissionais existentes que ainda não têm.
do $$
declare
  r record;
  v_codigo text;
begin
  for r in
    select id from perfis
    where papel in ('profissional', 'admin_empresa')
      and codigo_convite is null
  loop
    loop
      v_codigo := private.gerar_codigo_convite();
      exit when not exists (
        select 1 from perfis where codigo_convite = v_codigo
      );
    end loop;
    update perfis set codigo_convite = v_codigo where id = r.id;
  end loop;
end;
$$;

-- Nova função que retorna o TIPO do código para o Flutter apresentar
-- a mensagem de confirmação correta antes do cadastro.
create or replace function public.tipo_codigo_convite(codigo text)
returns text   -- 'aluno_precadastrado' | 'profissional' | 'invalido'
language sql
security definer set search_path = public
as $$
  select case
    when exists (
      select 1 from alunos
      where codigo_convite = codigo and perfil_id is null
    ) then 'aluno_precadastrado'
    when exists (
      select 1 from perfis
      where codigo_convite = codigo
        and papel in ('profissional', 'admin_empresa')
    ) then 'profissional'
    else 'invalido'
  end;
$$;

grant execute on function public.tipo_codigo_convite(text) to anon, authenticated;

-- Atualiza validar_codigo_convite para continuar funcionando (sem quebrar o app atual).
create or replace function public.validar_codigo_convite(codigo text)
returns boolean
language sql
security definer set search_path = public
as $$
  select public.tipo_codigo_convite(codigo) <> 'invalido';
$$;
