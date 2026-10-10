-- ============================================================
--  Boutique · Esquema de base de datos (Supabase / PostgreSQL)
--  Ejecuta todo este archivo en:  Supabase → SQL Editor → New query
-- ============================================================

-- ---------- Tablas ----------

-- Configuración del negocio (una sola fila)
create table if not exists app_settings (
  id            int primary key default 1,
  business_name text not null default 'Mi Boutique',
  logo_url      text,
  whatsapp      text default '',   -- a donde llegan los pedidos del catálogo
  constraint single_row check (id = 1)
);
insert into app_settings (id) values (1) on conflict (id) do nothing;

-- Clientes
create table if not exists clients (
  id         bigint generated always as identity primary key,
  name       text not null,
  phone      text default '',
  note       text default '',
  created_at timestamptz default now()
);

-- Productos (prendas)
create table if not exists products (
  id         bigint generated always as identity primary key,
  name       text not null,
  category   text default 'General',
  price      numeric not null default 0,
  min_stock  int not null default 0,
  photos     text[] not null default '{}',   -- URLs públicas en Storage
  created_at timestamptz default now()
);

-- Variantes (talla / color) con stock propio
create table if not exists variants (
  id         bigint generated always as identity primary key,
  product_id bigint not null references products(id) on delete cascade,
  talla      text default '',
  color      text default '',
  stock      int not null default 0
);
create index if not exists idx_variants_product on variants(product_id);

-- Ventas
create table if not exists sales (
  id          bigint generated always as identity primary key,
  created_at  timestamptz default now(),
  client_id   bigint references clients(id) on delete set null,
  client_name text default 'Mostrador',
  payment     text default 'Efectivo',
  subtotal    numeric not null default 0,
  discount    numeric not null default 0,
  total       numeric not null default 0,
  -- Estado: 'activa' | 'devuelta' (cliente devolvió) | 'anulada' (error de registro)
  status      text not null default 'activa',
  void_reason text,          -- 'devolucion' | 'anulacion'
  void_note   text,          -- nota libre opcional
  voided_at   timestamptz
);

-- Ítems de cada venta
create table if not exists sale_items (
  id         bigint generated always as identity primary key,
  sale_id    bigint not null references sales(id) on delete cascade,
  product_id bigint references products(id) on delete set null,
  variant_id bigint references variants(id) on delete set null,  -- para devolver stock exacto
  name       text not null,
  variant    text default '',
  price      numeric not null default 0,
  qty        int not null default 1
);
create index if not exists idx_items_sale on sale_items(sale_id);

-- ---------- Seguridad (RLS): solo usuarios con sesión ----------

alter table app_settings enable row level security;
alter table clients      enable row level security;
alter table products     enable row level security;
alter table variants     enable row level security;
alter table sales        enable row level security;
alter table sale_items   enable row level security;

do $$
declare t text;
begin
  foreach t in array array['app_settings','clients','products','variants','sales','sale_items']
  loop
    execute format('drop policy if exists "auth all" on %I;', t);
    execute format('create policy "auth all" on %I for all to authenticated using (true) with check (true);', t);
  end loop;
end $$;

-- ---------- Venta atómica (inserta venta + ítems y descuenta stock) ----------

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
revoke execute on function create_sale(bigint,text,text,numeric,numeric,numeric,jsonb) from anon;
grant execute on function create_sale(bigint,text,text,numeric,numeric,numeric,jsonb) to authenticated;

-- ---------- Descartar venta (devuelve stock + marca devuelta/anulada) ----------

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

  for it in select * from sale_items where sale_id = p_sale_id
  loop
    v_var_id := it.variant_id;

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
revoke execute on function void_sale(bigint,text,text) from anon;
grant execute on function void_sale(bigint,text,text) to authenticated;

-- (Supabase da EXECUTE a "anon" en las funciones nuevas, además de a PUBLIC: por eso
--  create_sale y void_sale, que son security definer, se le revocan explícitamente.)

-- ---------- Catálogo público (lo único que ve un visitante sin sesión) ----------
-- Nombre, logo y WhatsApp de la tienda + prendas con stock (solo sus variantes con stock).

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

-- ---------- Storage: políticas para el bucket 'product-photos' ----------
-- (Primero crea el bucket PÚBLICO llamado  product-photos  en Storage)

do $$
begin
  execute 'drop policy if exists "boutique_read"   on storage.objects';
  execute 'drop policy if exists "boutique_insert" on storage.objects';
  execute 'drop policy if exists "boutique_update" on storage.objects';
  execute 'drop policy if exists "boutique_delete" on storage.objects';

  execute 'create policy "boutique_read"   on storage.objects for select to public        using (bucket_id = ''product-photos'')';
  execute 'create policy "boutique_insert" on storage.objects for insert to authenticated  with check (bucket_id = ''product-photos'')';
  execute 'create policy "boutique_update" on storage.objects for update to authenticated  using (bucket_id = ''product-photos'')';
  execute 'create policy "boutique_delete" on storage.objects for delete to authenticated  using (bucket_id = ''product-photos'')';
end $$;

-- ¡Listo! Crea tu usuario en  Authentication → Users → Add user  (email + contraseña).
