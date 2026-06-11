-- 360Fit — Seed de demonstração (espelha os mocks da Fase 1)
--
-- PASSO 1 (antes deste script): crie 2 usuários em Authentication → Users:
--   joao.silva@360fit.com.br   (personal)
--   carlos.mendes@email.com    (aluno)
-- PASSO 2: execute este script no SQL Editor — os perfis são localizados
--          pelo email, então não é preciso editar nada.

-- ==================================================================== empresa

insert into empresas (id, nome, plano, marca_nome) values
  ('11111111-1111-1111-1111-111111111111', 'Academia Alpha', 'premium', 'Academia Alpha');

-- vincula perfis criados pelo trigger do Auth
update perfis set
  empresa_id = '11111111-1111-1111-1111-111111111111',
  papel = 'profissional',
  nome = 'João Silva'
where email = 'joao.silva@360fit.com.br';

update perfis set
  empresa_id = '11111111-1111-1111-1111-111111111111',
  papel = 'aluno',
  nome = 'Carlos Mendes'
where email = 'carlos.mendes@email.com';

-- ======================================================= biblioteca (global)

insert into exercicios (id, empresa_id, nome, grupo_muscular, equipamento) values
  ('e0000000-0000-0000-0000-000000000001', null, 'Supino reto', 'Peito', 'Barra'),
  ('e0000000-0000-0000-0000-000000000002', null, 'Supino inclinado', 'Peito', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000003', null, 'Crucifixo', 'Peito', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000004', null, 'Crossover', 'Peito', 'Polia'),
  ('e0000000-0000-0000-0000-000000000005', null, 'Puxada frontal', 'Costas', 'Polia'),
  ('e0000000-0000-0000-0000-000000000006', null, 'Remada curvada', 'Costas', 'Barra'),
  ('e0000000-0000-0000-0000-000000000007', null, 'Remada baixa', 'Costas', 'Polia'),
  ('e0000000-0000-0000-0000-000000000008', null, 'Barra fixa', 'Costas', 'Peso corporal'),
  ('e0000000-0000-0000-0000-000000000009', null, 'Agachamento livre', 'Pernas', 'Barra'),
  ('e0000000-0000-0000-0000-000000000010', null, 'Leg press 45°', 'Pernas', 'Máquina'),
  ('e0000000-0000-0000-0000-000000000011', null, 'Cadeira extensora', 'Pernas', 'Máquina'),
  ('e0000000-0000-0000-0000-000000000012', null, 'Mesa flexora', 'Pernas', 'Máquina'),
  ('e0000000-0000-0000-0000-000000000013', null, 'Stiff', 'Pernas', 'Barra'),
  ('e0000000-0000-0000-0000-000000000014', null, 'Panturrilha em pé', 'Pernas', 'Máquina'),
  ('e0000000-0000-0000-0000-000000000015', null, 'Avanço', 'Pernas', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000016', null, 'Desenvolvimento militar', 'Ombros', 'Barra'),
  ('e0000000-0000-0000-0000-000000000017', null, 'Elevação lateral', 'Ombros', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000018', null, 'Elevação frontal', 'Ombros', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000019', null, 'Encolhimento', 'Ombros', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000020', null, 'Rosca direta', 'Bíceps', 'Barra'),
  ('e0000000-0000-0000-0000-000000000021', null, 'Rosca alternada', 'Bíceps', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000022', null, 'Rosca martelo', 'Bíceps', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000023', null, 'Tríceps testa', 'Tríceps', 'Barra'),
  ('e0000000-0000-0000-0000-000000000024', null, 'Tríceps corda', 'Tríceps', 'Polia'),
  ('e0000000-0000-0000-0000-000000000025', null, 'Mergulho no banco', 'Tríceps', 'Peso corporal'),
  ('e0000000-0000-0000-0000-000000000026', null, 'Prancha', 'Core', 'Peso corporal'),
  ('e0000000-0000-0000-0000-000000000027', null, 'Abdominal infra', 'Core', 'Peso corporal'),
  ('e0000000-0000-0000-0000-000000000028', null, 'Elevação de pernas', 'Core', 'Peso corporal'),
  ('e0000000-0000-0000-0000-000000000029', null, 'Esteira (HIIT)', 'Cardio', 'Esteira'),
  ('e0000000-0000-0000-0000-000000000030', null, 'Bicicleta ergométrica', 'Cardio', 'Bicicleta');

-- ====================================================================== alunos

insert into alunos (id, empresa_id, perfil_id, profissional_id, nome, idade, objetivo, inicio, frequencia_semanal, peso_atual_kg, risco_evasao) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   (select id from perfis where email = 'carlos.mendes@email.com'),
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Carlos Mendes', 32, 'Hipertrofia', current_date - 180, 4, 82.4, false),
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Fernanda Costa', 28, 'Emagrecimento', current_date - 95, 3, 67.1, false),
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Ricardo Almeida', 45, 'Condicionamento', current_date - 320, 2, 91.0, true),
  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Juliana Rocha', 24, 'Hipertrofia', current_date - 60, 5, 58.9, false),
  ('a0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Marcos Pereira', 38, 'Emagrecimento', current_date - 40, 1, 104.7, true),
  ('a0000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Patrícia Lima', 51, 'Saúde e mobilidade', current_date - 400, 3, 70.3, false),
  ('a0000000-0000-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Bruno Tavares', 21, 'Hipertrofia', current_date - 15, 4, 74.5, false),
  ('a0000000-0000-0000-0000-000000000008', '11111111-1111-1111-1111-111111111111', null,
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Amanda Souza', 30, 'Preparação para corrida', current_date - 220, 3, 61.8, false);

-- ============================================================ treinos (Carlos)

insert into treinos (id, empresa_id, aluno_id, nome, foco, dias_semana) values
  ('b0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000001', 'Treino A', 'Peito e Tríceps', '{1,4}'),
  ('b0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000001', 'Treino B', 'Costas e Bíceps', '{2,5}'),
  ('b0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'a0000000-0000-0000-0000-000000000001', 'Treino C', 'Pernas e Ombros', '{3,6,7}');

insert into treino_itens (treino_id, exercicio_id, ordem, series, repeticoes, carga_kg, descanso_seg) values
  -- Treino A
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 1, 4, '8-10', 70, 60),
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', 2, 3, '10-12', 24, 60),
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000004', 3, 3, '12-15', 18, 60),
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000023', 4, 3, '10-12', 25, 60),
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000024', 5, 3, '12-15', 30, 60),
  ('b0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000026', 6, 3, '45s', 0, 60),
  -- Treino B
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000005', 1, 4, '8-10', 60, 60),
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000006', 2, 3, '8-10', 50, 60),
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000007', 3, 3, '10-12', 55, 60),
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000020', 4, 3, '10-12', 30, 60),
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000022', 5, 3, '12', 14, 60),
  -- Treino C
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000009', 1, 4, '6-8', 90, 90),
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000010', 2, 4, '10-12', 180, 60),
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000012', 3, 3, '12', 45, 60),
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000014', 4, 4, '15-20', 60, 45),
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000016', 5, 3, '8-10', 40, 60),
  ('b0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000017', 6, 3, '12-15', 10, 45);

-- ====================================================== agenda e evolução

insert into agendamentos (empresa_id, aluno_id, profissional_id, titulo, tipo, data_hora, local) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001',
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Treino acompanhado', 'treino', date_trunc('day', now()) + interval '18 hours 30 minutes', 'Academia Alpha — Unidade Centro'),
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001',
   (select id from perfis where email = 'joao.silva@360fit.com.br'),
   'Avaliação física trimestral', 'avaliacao', date_trunc('day', now()) + interval '2 days 9 hours', 'Sala de avaliação');

insert into registros_peso (empresa_id, aluno_id, data, peso_kg)
select '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001',
       current_date - (11 - g) * 15, 78.0 + g * 0.4
from generate_series(0, 11) as g;

insert into avaliacoes_fisicas (empresa_id, aluno_id, data, peso_kg, gordura_pct, massa_magra_kg) values
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', current_date - 180, 78.0, 21.5, 61.2),
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', current_date - 90, 80.1, 19.2, 64.7),
  ('11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001', current_date - 5, 82.4, 17.8, 67.7);

insert into registros_carga (empresa_id, aluno_id, exercicio_id, data, carga_kg)
select '11111111-1111-1111-1111-111111111111', 'a0000000-0000-0000-0000-000000000001',
       'e0000000-0000-0000-0000-000000000001', current_date - (6 - g) * 25,
       (array[50, 55, 57.5, 60, 65, 67.5, 70])[g + 1]
from generate_series(0, 6) as g;
