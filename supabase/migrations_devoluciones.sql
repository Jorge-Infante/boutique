-- ============================================================
--  Boutique · Migración: descartar ventas (devolución / anulación)
--  Ejecuta TODO este archivo en:  Supabase → SQL Editor → New query
--  Es seguro re-ejecutarlo (usa IF NOT EXISTS / OR REPLACE).
-- ============================================================

-- ---------- 1) Estado de la venta ----------
-- 'activa' (default) | 'devuelta' (el cliente trajo la mercancía) | 'anulada' (error de registro)
alter table sales add column if not exists status      text not null default 'activa';
alter table sales add column if not exists void_reason text;   -- 'devolucion' | 'anulacion'
alter table sales add column if not exists void_note   text;   -- nota libre opcional
alter table sales add column if not exists voided_at   timestamptz;

-- ---------- 2) Guardar la variante vendida en cada ítem ----------
-- Necesario para devolver el stock a la variante EXACTA al descartar la venta.
alter table sale_items add column if not exists variant_id bigint references variants(id) on delete set null;

-- ---------- 3) create_sale ahora PERSISTE variant_id ----------
create or replace function create_sale(
  p_client_id   bigint,
  p_client_name text,
  p_payment     text,
  p_subtotal    numeric,
  p_discount    numeric,
  p_total       numeric,
  p_items       jsonb
) returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sale_id bigint;
  it        jsonb;
begin
  insert into sales(client_id, client_name, payment, subtotal, discount, total)
  values (p_client_id, p_client_name, p_payment, p_subtotal, p_discount, p_total)
  returning id into v_sale_id;

  for it in select * from jsonb_array_elements(p_items)
  loop
    insert into sale_items(sale_id, product_id, variant_id, name, variant, price, qty)
    values (
      v_sale_id,
      nullif(it->>'product_id','')::bigint,
      nullif(it->>'variant_id','')::bigint,
      it->>'name',
      coalesce(it->>'variant',''),
      (it->>'price')::numeric,
      (it->>'qty')::int
    );

    if coalesce(it->>'variant_id','') <> '' then
      update variants
        set stock = greatest(0, stock - (it->>'qty')::int)
        where id = (it->>'variant_id')::bigint;
    end if;
  end loop;

  return v_sale_id;
end;
$$;

revoke all on function create_sale(bigint,text,text,numeric,numeric,numeric,jsonb) from public;
grant execute on function create_sale(bigint,text,text,numeric,numeric,numeric,jsonb) to authenticated;

-- ---------- 4) void_sale: descartar una venta y devolver el stock ----------
-- Devuelve al stock todos los ítems y marca la venta como devuelta/anulada.
-- Es idempotente: si la venta ya no está 'activa', lanza error (no re-suma stock).
create or replace function void_sale(
  p_sale_id bigint,
  p_reason  text,          -- 'devolucion' | 'anulacion'
  p_note    text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  it       record;
  v_var_id bigint;
begin
  -- Bloquea la fila para evitar doble descarte simultáneo
  select status into v_status from sales where id = p_sale_id for update;

  if v_status is null then
    raise exception 'La venta % no existe', p_sale_id;
  end if;
  if v_status <> 'activa' then
    raise exception 'La venta % ya fue descartada', p_sale_id;
  end if;
  if p_reason not in ('devolucion', 'anulacion') then
    raise exception 'Motivo inválido: %', p_reason;
  end if;

  -- Devuelve el stock de cada ítem
  for it in select * from sale_items where sale_id = p_sale_id
  loop
    v_var_id := it.variant_id;

    -- Respaldo para ventas antiguas (sin variant_id): intenta ubicar la variante por texto
    if v_var_id is null and it.product_id is not null then
      select v.id into v_var_id
        from variants v
        where v.product_id = it.product_id
          and coalesce(nullif(concat_ws(' · ', nullif(v.talla,''), nullif(v.color,'')), ''), 'Única') = it.variant
        limit 1;
    end if;

    if v_var_id is not null then
      update variants set stock = stock + it.qty where id = v_var_id;
    end if;
  end loop;

  update sales
    set status      = case when p_reason = 'devolucion' then 'devuelta' else 'anulada' end,
        void_reason = p_reason,
        void_note   = p_note,
        voided_at   = now()
    where id = p_sale_id;
end;
$$;

revoke all on function void_sale(bigint,text,text) from public;
grant execute on function void_sale(bigint,text,text) to authenticated;

-- ¡Listo! Ya puedes descartar ventas desde la app.
