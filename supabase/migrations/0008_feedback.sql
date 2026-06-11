-- 360Fit — Migration 0008: feedback pós-treino (PSE e dor)

alter table treinos_concluidos
  add column pse int not null default 0,            -- Escala de Borg 0–10
  add column dor_articular boolean not null default false,
  add column dor_relato text not null default '';
