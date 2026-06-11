-- 360Fit — Migration 0005: status de agendamento + confirmação pelo aluno

create type status_agendamento as enum ('pendente', 'confirmado', 'cancelado');

alter table agendamentos
  add column status status_agendamento not null default 'pendente';

-- O aluno pode confirmar a própria presença (update restrito à linha dele).
create policy "aluno confirma presenca"
  on agendamentos for update
  using (aluno_id = private.aluno_do_usuario())
  with check (aluno_id = private.aluno_do_usuario());
