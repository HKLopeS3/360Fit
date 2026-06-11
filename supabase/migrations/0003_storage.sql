-- 360Fit — Migration 0003: Storage (avatares e mídias de exercícios)
-- Caminho convencionado: <empresa_id>/<arquivo> — as políticas validam a 1ª pasta.

insert into storage.buckets (id, name, public)
values
  ('avatares', 'avatares', false),
  ('midias-exercicios', 'midias-exercicios', false)
on conflict (id) do nothing;

create policy "membros leem avatares da empresa"
  on storage.objects for select
  using (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
  );

create policy "usuario gerencia o proprio avatar"
  on storage.objects for all
  using (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
    and owner = auth.uid()
  )
  with check (
    bucket_id = 'avatares'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
  );

create policy "membros leem midias da empresa"
  on storage.objects for select
  using (
    bucket_id = 'midias-exercicios'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
  );

create policy "equipe gerencia midias da empresa"
  on storage.objects for all
  using (
    bucket_id = 'midias-exercicios'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
    and private.papel_do_usuario() in ('profissional', 'admin_empresa')
  )
  with check (
    bucket_id = 'midias-exercicios'
    and (storage.foldername(name))[1] = private.empresa_do_usuario()::text
  );
