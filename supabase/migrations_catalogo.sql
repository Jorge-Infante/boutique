-- ============================================================
--  Boutique · Migración: catálogo público + pedidos por WhatsApp
--  Ejecuta TODO este archivo en:  Supabase → SQL Editor → New query
--  Es seguro re-ejecutarlo (usa IF NOT EXISTS / OR REPLACE).
-- ============================================================

-- ---------- 1) WhatsApp de la tienda (a donde llegan los pedidos) ----------
alter table app_settings add column if not exists whatsapp text default '';

-- ---------- 2) Catálogo público ----------
-- Lo ÚNICO que puede leer un visitante sin sesión: nombre, logo y WhatsApp de la tienda,
-- y las prendas con stock (solo sus variantes con stock). Clientes y ventas siguen privados.
-- security definer: lee las tablas sin abrirle la RLS a los anónimos.
create or replace function public_catalog()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'business', (
      select jsonb_build_object('name', s.business_name, 'logo_url', s.logo_url, 'whatsapp', s.whatsapp)
      from app_settings s
      where s.id = 1
    ),
    'products', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'name', p.name,
        'category', p.category,
        'price', p.price,
        'photos', p.photos,
        'variants', (
          select jsonb_agg(jsonb_build_object('id', v.id, 'talla', v.talla, 'color', v.color, 'stock', v.stock) order by v.id)
          from variants v
          where v.product_id = p.id and v.stock > 0
        )
      ) order by p.name)
      from products p
      where exists (select 1 from variants v where v.product_id = p.id and v.stock > 0)
    ), '[]'::jsonb)
  );
$$;

revoke all on function public_catalog() from public;
grant execute on function public_catalog() to anon, authenticated;

-- ---------- 3) Las funciones de venta, solo con sesión ----------
-- Supabase le da EXECUTE a "anon" en las funciones nuevas, además de a PUBLIC. Como
-- create_sale y void_sale son security definer, sin esto un visitante sin sesión podría
-- registrar o descartar ventas con la anon key (que va en el JS público).
revoke execute on function create_sale(bigint,text,text,numeric,numeric,numeric,jsonb) from anon;
revoke execute on function void_sale(bigint,text,text) from anon;

-- ¡Listo! Pon el WhatsApp de la tienda en la app: menú → Datos de la tienda.
