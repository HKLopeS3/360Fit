-- Adiciona coluna capa_url ao perfil do profissional.
-- A capa é exibida como banner/mural no dashboard dos alunos vinculados.
alter table perfis add column if not exists capa_url text;
