# Boutique · Inventario y Ventas

App web (Vue 3 + Vite + Supabase) para una tienda de ropa: inventario con tallas/colores,
ventas con descuento y método de pago, clientes con historial, ficha de producto con fotos,
recibos imprimibles y login privado.

---

## 1) Instalar

```bash
npm install
```

## 2) Crear el proyecto en Supabase

1. Entra a https://supabase.com → **New project** (plan gratis). Guarda la contraseña de la base.
2. En **SQL Editor → New query**, pega y ejecuta todo el archivo [`supabase/schema.sql`](supabase/schema.sql).
3. En **Storage → New bucket**, crea un bucket **público** llamado exactamente **`product-photos`**.
   - Vuelve a ejecutar la última sección de `schema.sql` (las políticas de Storage) si creaste el bucket después.
4. (Opcional) Ejecuta [`supabase/seed.sql`](supabase/seed.sql) para cargar prendas y clientes de ejemplo.
5. En **Authentication → Users → Add user**, crea el usuario de la dueña (correo + contraseña).
   - Si pide confirmación de correo, puedes desactivarla en **Authentication → Providers → Email**
     (apaga "Confirm email") para que entre de una vez.

## 3) Conectar las llaves

En **Project Settings → API** copia:
- **Project URL**
- **anon public** key

Crea el archivo `.env.local` (copia de `.env.example`) y pégalas:

```
VITE_SUPABASE_URL=https://TU-PROYECTO.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...
```

> La *anon key* es pública y segura para el frontend: los datos están protegidos por RLS
> (solo usuarios con sesión pueden leer/escribir).

## 4) Correr en local

```bash
npm run dev
```

Abre la URL que muestra (normalmente http://localhost:5173), inicia sesión y listo.

---

## 5) Desplegar gratis (Netlify)

1. Sube este proyecto a un repositorio de GitHub.
2. En https://app.netlify.com → **Add new site → Import from GitHub** y elige el repo.
3. Configuración de build:
   - **Build command:** `npm run build`
   - **Publish directory:** `dist`
4. En **Site settings → Environment variables**, agrega:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. **Deploy**. Te queda una URL tipo `https://tu-boutique.netlify.app`.

Alternativas equivalentes: **Vercel** o **Cloudflare Pages** (mismos build command y env vars).

---

## Estructura

```
supabase/
  schema.sql     Tablas, seguridad (RLS), función de venta atómica y políticas de Storage
  seed.sql       Datos de ejemplo (opcional)
src/
  supabase.js    Cliente de Supabase
  store.js       Carga y guarda datos (productos, clientes, ventas, fotos)
  sale.js        Estado del carrito / venta en curso
  ui.js          Vista activa y modales
  utils.js       Formato de moneda, fechas, redimensionar imágenes
  components/    Vistas (Dashboard, Sale, Products, Clients, Sales) y modales
```

## Notas

- Las fotos se suben a Supabase Storage (bucket `product-photos`) y se guardan sus URLs.
- La venta descuenta el stock de cada variante de forma atómica (función `create_sale`).
- Para agregar más usuarios autorizados, créalos en **Authentication → Users**.
