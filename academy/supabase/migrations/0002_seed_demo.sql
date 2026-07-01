-- ============================================================
-- 360Fit Academy — Migration 0002: Dados de demonstração
-- Executar APÓS criar a conta gestor via app (SignUp).
-- Substitua 'SEU_AUTH_USER_ID' pelo UUID do usuário criado.
-- ============================================================

-- Este seed é opcional — serve para popular a academia demo
-- com dados realistas para apresentação/teste.

-- Passo 1: copie o ID da academia criada pelo trigger após o signup:
-- SELECT id FROM academias LIMIT 1;
-- e substitua abaixo:

do $$
declare
  v_academia_id uuid;
  v_plano_mensal uuid;
  v_plano_tri    uuid;
  v_plano_anual  uuid;
  v_aluno1       uuid;
  v_aluno2       uuid;
  v_aluno3       uuid;
  v_aluno4       uuid;
  v_contrato1    uuid;
begin
  -- Pega a primeira academia (a demo)
  select id into v_academia_id from academias order by created_at limit 1;

  if v_academia_id is null then
    raise notice 'Nenhuma academia encontrada. Faça o cadastro primeiro via app.';
    return;
  end if;

  -- ── Planos ──────────────────────────────────────────────────
  insert into planos (academia_id, nome, tipo, duracao_dias, valor)
  values (v_academia_id, 'Musculação Mensal',     'mensal',     30,  120.00) returning id into v_plano_mensal;

  insert into planos (academia_id, nome, tipo, duracao_dias, valor)
  values (v_academia_id, 'Musculação Trimestral', 'trimestral', 90,  320.00) returning id into v_plano_tri;

  insert into planos (academia_id, nome, tipo, duracao_dias, valor)
  values (v_academia_id, 'Plano Anual Completo',  'anual',      365, 900.00) returning id into v_plano_anual;

  -- ── Turmas ──────────────────────────────────────────────────
  insert into turmas (academia_id, nome, professor, sala, hora_inicio, hora_fim, dias_semana, vagas)
  values
    (v_academia_id, 'Musculação Manhã',  'Prof. Anderson', 'Sala A',       '06:00', '07:00', '{1,3,5}', 30),
    (v_academia_id, 'Spinning',          'Prof. Carla',    'Sala B',       '07:00', '08:00', '{2,4}',   20),
    (v_academia_id, 'Funcional',         'Prof. Roberto',  'Área Externa', '08:30', '09:30', '{1,3,5}', 15),
    (v_academia_id, 'Yoga',              'Prof. Marina',   'Sala C',       '09:00', '10:00', '{2,4,6}', 12),
    (v_academia_id, 'Musculação Tarde',  'Prof. Anderson', 'Sala A',       '17:00', '18:00', '{1,3,5}', 30),
    (v_academia_id, 'Zumba',             'Prof. Fernanda', 'Sala B',       '18:00', '19:00', '{2,4,6}', 25),
    (v_academia_id, 'Musculação Noite',  'Prof. Lucas',    'Sala A',       '19:00', '20:00', '{1,2,3,4,5}', 30),
    (v_academia_id, 'Pilates',           'Prof. Beatriz',  'Sala C',       '10:00', '11:00', '{1,3,5}', 10);

  -- ── Alunos ──────────────────────────────────────────────────
  insert into alunos (academia_id, nome, email, telefone, cpf, data_nascimento, sexo, objetivo, professor, ativo)
  values (v_academia_id, 'Mariana Costa', 'mariana@email.com', '(11) 99999-0001',
          '123.456.789-00', '1995-03-22', 'feminino', 'Emagrecimento', 'Prof. Anderson', true)
  returning id into v_aluno1;

  insert into alunos (academia_id, nome, email, telefone, cpf, data_nascimento, sexo, objetivo, professor, ativo)
  values (v_academia_id, 'Carlos Mendes', 'carlos@email.com', '(11) 99999-0002',
          '234.567.890-11', '1990-07-15', 'masculino', 'Hipertrofia', 'Prof. Lucas', true)
  returning id into v_aluno2;

  insert into alunos (academia_id, nome, email, telefone, cpf, data_nascimento, sexo, objetivo, professor, ativo)
  values (v_academia_id, 'Fernanda Lima', 'fernanda@email.com', '(11) 99999-0003',
          '345.678.901-22', '1998-11-05', 'feminino', 'Condicionamento', 'Prof. Anderson', true)
  returning id into v_aluno3;

  insert into alunos (academia_id, nome, email, telefone, cpf, data_nascimento, sexo, objetivo, professor, ativo)
  values (v_academia_id, 'Rafael Santos', 'rafael@email.com', '(11) 99999-0004',
          '456.789.012-33', '1985-02-28', 'masculino', 'Hipertrofia', 'Prof. Lucas', true)
  returning id into v_aluno4;

  -- ── Contratos (o trigger gera mensalidades automaticamente) ──
  insert into contratos (academia_id, aluno_id, plano_id, inicio, fim, situacao)
  values (v_academia_id, v_aluno1, v_plano_mensal,
          current_date - 18, current_date + 12, 'ativo')
  returning id into v_contrato1;

  insert into contratos (academia_id, aluno_id, plano_id, inicio, fim, situacao)
  values (v_academia_id, v_aluno2, v_plano_tri,
          current_date - 45, current_date + 45, 'ativo');

  insert into contratos (academia_id, aluno_id, plano_id, inicio, fim, situacao)
  values (v_academia_id, v_aluno3, v_plano_mensal,
          current_date - 38, current_date - 8, 'ativo');

  insert into contratos (academia_id, aluno_id, plano_id, inicio, fim, situacao)
  values (v_academia_id, v_aluno4, v_plano_anual,
          current_date - 185, current_date + 180, 'ativo');

  -- Marca 1ª mensalidade da Mariana como paga
  update mensalidades
  set pago_em = now() - interval '5 days', forma_pag = 'pix'
  where aluno_id = v_aluno1
    and vencimento = (select min(vencimento) from mensalidades where aluno_id = v_aluno1);

  -- ── Check-ins de hoje ────────────────────────────────────────
  insert into checkins (academia_id, aluno_id, quando, canal)
  values
    (v_academia_id, v_aluno2, now() - interval '3 hours',   'manual'),
    (v_academia_id, v_aluno4, now() - interval '2.5 hours', 'manual'),
    (v_academia_id, v_aluno1, now() - interval '1.5 hours', 'qrcode');

  raise notice 'Seed concluído para academia %', v_academia_id;
end;
$$;
