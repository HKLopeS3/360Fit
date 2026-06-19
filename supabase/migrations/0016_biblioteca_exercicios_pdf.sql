-- Migration: adiciona exercícios do PDF "Treinos do cliente - Next Fit"
-- à biblioteca global da plataforma (empresa_id NULL = disponível para todos).
-- Exercícios já existentes com o mesmo nome são ignorados.

INSERT INTO exercicios (empresa_id, nome, grupo_muscular, equipamento)
SELECT NULL, ex.nome, ex.grupo, ex.equip
FROM (VALUES
  -- Mobilidade / Aquecimento
  ('Alongamento Dorsal Arco Unilateral (Espaldar)', 'Mobilidade',        'Espaldar'),
  ('Mobilidade de Ombro - Diagonal com Elástico',   'Mobilidade',        'Elástico'),
  ('Mobilidade de Escápula e Ombro (Elástico)',      'Mobilidade',        'Elástico'),
  ('Mobilidade de Quadril - Projeção à Frente',      'Mobilidade',        'Solo'),
  ('Mobilidade de Quadril - Projeção Diagonal',      'Mobilidade',        'Solo'),
  ('Flexão de Quadril',                              'Mobilidade',        'Solo'),
  ('Alongamento Peito Unilateral (Espaldar)',         'Mobilidade',        'Espaldar'),
  ('Abdução de Ombros',                              'Mobilidade',        'Solo'),
  ('Mobilidade de Ombro com Bastão',                 'Mobilidade',        'Bastão'),
  -- Core
  ('Prancha Baixa - Isométrica',                     'Core',              'Solo'),
  ('Abdominal Remador - Solo',                       'Core',              'Solo'),
  ('Abdominal - Tocando os Pés',                     'Core',              'Solo'),
  ('Flexão de Braço - Solo',                         'Peito',             'Solo'),
  -- Costas
  ('Puxada Aberta - Pronada',                        'Costas',            'Polia'),
  ('Remada Baixa - Barra Romana - Neutra',           'Costas',            'Barra'),
  ('Remada Cavalinho - Máquina - Neutra',            'Costas',            'Máquina'),
  ('Remada Serrote - Halter',                        'Costas',            'Halter'),
  -- Ombros
  ('Crucifixo Inverso - Peck Deck',                 'Ombros',            'Máquina'),
  ('Elevação Frontal - Halter',                      'Ombros',            'Halter'),
  ('Elevação Lateral - Halter',                      'Ombros',            'Halter'),
  ('Elevação Frontal - Corda - Polia Baixa',         'Ombros',            'Polia'),
  ('Desenvolvimento - Máquina Articulada',           'Ombros',            'Máquina'),
  -- Bíceps
  ('Rosca Scott - Barra Reta - Banco Scott',         'Bíceps',            'Barra'),
  ('Rosca Martelo - Duplo Halter - Em Pé',          'Bíceps',            'Halter'),
  -- Tríceps
  ('Tríceps Pulley - Corda - Polia Alta',           'Tríceps',           'Polia'),
  ('Tríceps Testa - Barra - Banco Reto',            'Tríceps',           'Barra'),
  ('Tríceps Francês - Corda - Polia Baixa - Sentado','Tríceps',          'Polia'),
  -- Peito
  ('Crucifixo - Peck Deck',                          'Peito',             'Máquina'),
  ('Supino Reto - Barra',                            'Peito',             'Barra'),
  ('Supino Inclinado - Máquina Articulada',          'Peito',             'Máquina'),
  ('Supino Declinado - Máquina Articulada',          'Peito',             'Máquina'),
  -- Pernas
  ('Agachamento Guiado - Smith',                     'Quadríceps',        'Smith'),
  ('Extensora - Cadeira Articulada',                 'Quadríceps',        'Máquina'),
  ('Afundo Reverso - Livre',                         'Quadríceps',        'Livre'),
  ('Leg Press 45° - Máquina Articulada',             'Quadríceps',        'Máquina'),
  ('Abdutor - Cadeira Articulada',                   'Abdutores',         'Máquina'),
  ('Cadeira Flexora - Máquina Articulada',           'Posterior de Coxa', 'Máquina'),
  ('Stiff - Duplo Halter',                           'Posterior de Coxa', 'Halter'),
  ('Flexora - Mesa Articulada',                      'Posterior de Coxa', 'Máquina'),
  ('Panturrilha Sentado - Máquina',                  'Panturrilha',       'Máquina'),
  -- Cardio
  ('Caminhada na Esteira com Inclinação',            'Cardio',            'Esteira'),
  ('Caminhada na Esteira',                           'Cardio',            'Esteira'),
  ('Bicicleta Ergométrica',                          'Cardio',            'Bicicleta')
) AS ex(nome, grupo, equip)
WHERE NOT EXISTS (
  SELECT 1 FROM exercicios e2 WHERE e2.nome = ex.nome
);
