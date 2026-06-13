-- 360Fit — Limpeza dos dados de demonstração/teste antes do uso real.
--
-- Remove todas as empresas (e, em cascata, perfis, alunos, treinos,
-- agendamentos, avaliações, registros etc. vinculados a elas) e os
-- usuários de Auth correspondentes, mantendo apenas a biblioteca
-- global de exercícios (exercicios.empresa_id is null).
--
-- Execute no SQL Editor do Supabase (service_role).

delete from empresas;

-- Remove os usuários de Auth que ficaram sem perfil (todos, neste ponto).
delete from auth.users
where id not in (select id from perfis);
