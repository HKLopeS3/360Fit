-- Migration 0014: exclusão de conta pelo próprio usuário
--
-- Cria uma função RPC que o usuário autenticado pode chamar para deletar
-- sua própria conta. A função roda como SECURITY DEFINER (com permissões
-- do owner postgres) e só permite apagar a si mesmo (auth.uid()).
--
-- Após o delete em auth.users os dados em alunos/perfis/empresas são
-- removidos em cascata pelas FKs já existentes.

create or replace function public.excluir_minha_conta()
returns void
language plpgsql
security definer set search_path = public, auth
as $$
begin
  -- Garante que o caller está autenticado
  if auth.uid() is null then
    raise exception 'Não autenticado';
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.excluir_minha_conta() to authenticated;
