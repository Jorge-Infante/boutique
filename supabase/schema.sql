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
  total       numeric not null default 0
);

-- Ítems de cada venta
create table if not exists sale_items (
  id         bigint generated always as identity primary key,
  sale_id    bigint not null references sales(id) on delete cascade,
  product_id bigint references products(id) on delete set null,
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
    insert into sale_items(sale_id, product_id, name, variant, price, qty)
    values (
      v_sale_id,
      nullif(it->>'product_id','')::bigint,
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
