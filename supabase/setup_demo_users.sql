--- =========================================================================
-- 360Fit - Setup de Usuários Demo
-- =========================================================================
-- 
-- IMPORTANTE: Antes de executar este script, você precisa criar os usuários
-- na seção "Authentication > Users" do Supabase:
--
-- 1. Email: carlos.mendes@email.com
--    Senha: demo360fit
--    Tipo: Aluno
--
-- 2. Email: joao.silva@360fit.com.br
--    Senha: demo360fit
--    Tipo: Personal Trainer
--
-- DEPOIS execute este script no SQL Editor para vincular os perfis e criar dados.
--
-- =========================================================================

-- 1. Criar empresa demo
INSERT INTO empresas (id, nome, plano, marca_nome) 
VALUES (
  '11111111-1111-1111-1111-111111111111', 
  'Academia Alpha', 
  'premium', 
  '360Fit'
)
ON CONFLICT (id) DO UPDATE SET nome = 'Academia Alpha';

-- 2. Atualizar perfis dos usuários criados (pelo trigger do Auth)
UPDATE perfis SET
  empresa_id = '11111111-1111-1111-1111-111111111111',
  papel = 'profissional',
  nome = 'João Silva'
WHERE email = 'joao.silva@360fit.com.br';

UPDATE perfis SET
  empresa_id = '11111111-1111-1111-1111-111111111111',
  papel = 'aluno',
  nome = 'Carlos Mendes'
WHERE email = 'carlos.mendes@email.com';

-- 3. Criar aluno vinculado ao usuário Carlos
INSERT INTO alunos (
  id, empresa_id, perfil_id, profissional_id, 
  nome, idade, objetivo, inicio, frequencia_semanal, peso_atual_kg, risco_evasao
)
VALUES (
  'a0000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  (SELECT id FROM perfis WHERE email = 'carlos.mendes@email.com'),
  (SELECT id FROM perfis WHERE email = 'joao.silva@360fit.com.br'),
  'Carlos Mendes',
  32,
  'Hipertrofia',
  CURRENT_DATE - INTERVAL '180 days',
  4,
  82.4,
  false
)
ON CONFLICT (id) DO NOTHING;

-- 4. Criar mais alguns alunos para o personal treinar
INSERT INTO alunos (id, empresa_id, perfil_id, profissional_id, nome, idade, objetivo, inicio, frequencia_semanal, peso_atual_kg, risco_evasao)
VALUES 
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', null, (SELECT id FROM perfis WHERE email = 'joao.silva@360fit.com.br'), 'Fernanda Costa', 28, 'Emagrecimento', CURRENT_DATE - INTERVAL '95 days', 3, 67.1, false),
  ('a0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', null, (SELECT id FROM perfis WHERE email = 'joao.silva@360fit.com.br'), 'Ricardo Almeida', 45, 'Condicionamento', CURRENT_DATE - INTERVAL '320 days', 2, 91.0, true),
  ('a0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', null, (SELECT id FROM perfis WHERE email = 'joao.silva@360fit.com.br'), 'Juliana Rocha', 24, 'Hipertrofia', CURRENT_DATE - INTERVAL '60 days', 5, 58.9, false)
ON CONFLICT (id) DO NOTHING;

-- 5. Criar biblioteca de exercícios (global, sem empresa)
INSERT INTO exercicios (id, empresa_id, nome, grupo_muscular, equipamento) VALUES
  ('e0000000-0000-0000-0000-000000000001', null, 'Supino reto', 'Peito', 'Barra'),
  ('e0000000-0000-0000-0000-000000000002', null, 'Supino inclinado', 'Peito', 'Halteres'),
  ('e0000000-0000-0000-0000-000000000003', null, 'Puxada frontal', 'Costas', 'Polia'),
  ('e0000000-0000-0000-0000-000000000004', null, 'Remada curvada', 'Costas', 'Barra'),
  ('e0000000-0000-0000-0000-000000000005', null, 'Agachamento livre', 'Pernas', 'Barra'),
  ('e0000000-0000-0000-0000-000000000006', null, 'Leg press 45°', 'Pernas', 'Máquina'),
  ('e0000000-0000-0000-0000-000000000007', null, 'Desenvolvimento militar', 'Ombros', 'Barra'),
  ('e0000000-0000-0000-0000-000000000008', null, 'Rosca direta', 'Bíceps', 'Barra'),
  ('e0000000-0000-0000-0000-000000000009', null, 'Tríceps corda', 'Tríceps', 'Polia'),
  ('e0000000-0000-0000-0000-000000000010', null, 'Prancha', 'Core', 'Peso corporal')
ON CONFLICT (id) DO NOTHING;

-- =========================================================================
-- PRONTO! Você agora pode:
--
-- 1. Fazer login na web como aluno: carlos.mendes@email.com / demo360fit
-- 2. Fazer login na web como personal: joao.silva@360fit.com.br / demo360fit
-- 3. Criar novas contas para testar o fluxo de registro
--
-- =========================================================================
