-- Menú fijo por día de Doña Miriam (nov 2026).
-- Se corre en su base (encargos-dona-miriam) el día que se publique la página
-- del «menú de la semana». No borra nada: los platillos viejos quedan apagados.
-- Días: 1 lunes … 6 sábado.
BEGIN;

DO $$
DECLARE
  v_acc UUID := 'ff7a0fa1-1338-439d-8b04-baae18232f94';
BEGIN
  -- Precio y anticipo
  UPDATE menu_config SET precio_charola = 200, anticipo = 100 WHERE account_id = v_acc;

  -- Grupos de la charola: el plato fuerte, la ensalada y la vianda siempre van;
  -- el arroz y el potaje solo algunos días.
  UPDATE negocio_config
     SET data = jsonb_set(COALESCE(data, '{}'::jsonb), '{pedido}', jsonb_build_object(
       'uno', 'charola', 'varios', 'charolas',
       'grupos', '[{"id":"carne","nombre":"Plato fuerte","tipo":"uno"},
                   {"id":"arroz","nombre":"Arroz","tipo":"opcional"},
                   {"id":"potaje","nombre":"Potaje","tipo":"opcional"},
                   {"id":"ensalada","nombre":"Ensalada","tipo":"uno"},
                   {"id":"vianda","nombre":"Vianda","tipo":"uno"},
                   {"id":"extra","nombre":"Extras","tipo":"extra"}]'::jsonb))
   WHERE account_id = v_acc;

  -- Apagar el menú anterior (se puede volver a prender desde el CRM)
  UPDATE menu_items SET disponible = false WHERE account_id = v_acc;

  -- Menú de la semana
  INSERT INTO menu_items (account_id, grupo, nombre, precio, dias, orden, disponible)
  SELECT v_acc, g, n, p, d, o, true FROM (VALUES
    ('carne',    'Pollo en salsa',                     0::numeric, ARRAY[1], 1),
    ('carne',    'Arroz amarillo con carne de puerco', 0, ARRAY[2], 2),
    ('carne',    'Bistec de puerco',                   0, ARRAY[3], 3),
    ('carne',    'Picadillo con papa',                 0, ARRAY[4], 4),
    ('carne',    'Arroz amarillo con jamón',           0, ARRAY[5], 5),
    ('carne',    'Chuleta encebollada',                0, ARRAY[6], 6),
    ('arroz',    'Arroz blanco',                       0, ARRAY[1,4,6], 1),
    ('arroz',    'Arroz congrí',                       0, ARRAY[3], 2),
    ('potaje',   'Potaje de frijoles colorados',       0, ARRAY[1], 1),
    ('potaje',   'Potaje de chícharo',                 0, ARRAY[4], 2),
    ('potaje',   'Potaje de garbanzos',                0, ARRAY[6], 3),
    ('ensalada', 'Ensalada de pepino y tomate',        0, ARRAY[1,5], 1),
    ('ensalada', 'Ensalada de lechuga y tomate',       0, ARRAY[2,4], 2),
    ('ensalada', 'Ensalada de col y tomate',           0, ARRAY[3,6], 3),
    ('vianda',   'Boniato hervido',                    0, ARRAY[1,4], 1),
    ('vianda',   'Papa con mojo',                      0, ARRAY[2,5], 2),
    ('vianda',   'Platanito maduro frito',             0, ARRAY[3], 3),
    ('vianda',   'Tostones',                           0, ARRAY[6], 4),
    ('extra',    'Ración extra de arroz',             40, NULL, 1),
    ('extra',    'Ración extra de potaje',            40, ARRAY[1,4,6], 2)
  ) AS t(g, n, p, d, o)
  ON CONFLICT (account_id, grupo, nombre) DO UPDATE
    SET precio = EXCLUDED.precio, dias = EXCLUDED.dias, orden = EXCLUDED.orden,
        disponible = true, agotado_hasta = NULL, updated_at = now();
END $$;

COMMIT;
