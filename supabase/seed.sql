-- ============================================================
--  Datos de ejemplo (OPCIONAL) para probar la app
--  Ejecútalo DESPUÉS de schema.sql, en Supabase → SQL Editor
-- ============================================================

insert into clients (name, phone, note) values
  ('María López', '300 123 4567', ''),
  ('Laura Gómez', '310 555 8899', 'Prefiere tallas S');

-- Producto 1
with p as (
  insert into products (name, category, price, min_stock, photos)
  values ('Camiseta básica', 'Camisetas', 35000, 4, '{}') returning id)
insert into variants (product_id, talla, color, stock)
select id, t, c, s from p, (values
  ('S','Blanco',8), ('M','Blanco',10), ('S','Negro',5), ('M','Negro',4)
) as v(t,c,s);

-- Producto 2
with p as (
  insert into products (name, category, price, min_stock, photos)
  values ('Jean clásico azul', 'Pantalones', 89000, 3, '{}') returning id)
insert into variants (product_id, talla, color, stock)
select id, t, c, s from p, (values
  ('28','Azul',2), ('30','Azul',4), ('32','Azul',2)
) as v(t,c,s);

-- Producto 3
with p as (
  insert into products (name, category, price, min_stock, photos)
  values ('Vestido largo elegante', 'Vestidos', 120000, 3, '{}') returning id)
insert into variants (product_id, talla, color, stock)
select id, t, c, s from p, (values
  ('S','Rojo',3), ('M','Rojo',4), ('L','Rojo',3), ('S','Negro',2), ('M','Negro',2)
) as v(t,c,s);

-- Producto 4
with p as (
  insert into products (name, category, price, min_stock, photos)
  values ('Blusa manga larga', 'Blusas', 55000, 3, '{}') returning id)
insert into variants (product_id, talla, color, stock)
select id, t, c, s from p, (values
  ('M','Rosa',6), ('L','Rosa',6)
) as v(t,c,s);

-- Producto 5 (accesorio sin tallas/colores)
with p as (
  insert into products (name, category, price, min_stock, photos)
  values ('Gorra', 'Accesorios', 28000, 8, '{}') returning id)
insert into variants (product_id, talla, color, stock)
select id, 'Única', '', 30 from p;
