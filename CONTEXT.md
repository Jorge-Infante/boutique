# CONTEXTO DEL PROYECTO — Boutique (para retomar luego)

> Resumen vivo del estado del proyecto. Última actualización: **2026-10-10**.

## Qué es

App web de **inventario + ventas ("control interno", NO factura electrónica DIAN)** para la
boutique de ropa de una amiga (negocio de Laura). Login privado, datos en la nube, pensada
para usarse desde el celular y el computador.

## Stack y arquitectura

- **Frontend:** Vue 3 + Vite (JavaScript, `<script setup>`). Sin router (vista por estado en `ui.js`).
- **Backend:** Supabase → Postgres (datos) + Auth (login) + Storage (fotos).
- **Hosting:** Netlify, con **deploy automático** al hacer push a `main` en GitHub.

```
Navegador (Netlify)  ──►  Supabase (Postgres + Auth + Storage)
```

## Enlaces y datos del entorno

- **Repo GitHub:** https://github.com/Jorge-Infante/boutique  (privado)
- **Sitio Netlify:** https://lauo.netlify.app
- **Supabase project ref:** `rrcrsnrcdaebcezcomzw`
- **Supabase URL:** `https://rrcrsnrcdaebcezcomzw.supabase.co`
- **Llaves locales:** en `.env.local` (NO se sube a git). La *anon key* es pública (protegida por RLS).
- **Netlify env vars:** `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` (deben estar seteadas en el sitio;
  sin ellas el build no conecta). Valores de referencia también en
  `C:\Users\Desarrollador\Downloads\boutique-variables-netlify.md`.

## Cómo trabajar en local

```bash
cd C:\Users\Desarrollador\Documents\boutique
npm install        # solo la primera vez
npm run dev        # http://localhost:5173
npm run build      # genera dist/ (lo que publica Netlify)
```

Para publicar un cambio: `git add -A && git commit -m "..." && git push` → Netlify lo publica solo.

## Modelo de datos (ver supabase/schema.sql)

- `app_settings` (1 fila): nombre del negocio + logo_url.
- `clients`: name, phone, note.
- `products`: name, category, price, min_stock, photos (text[] de URLs en Storage).
- `variants`: product_id, talla, color, stock  (stock POR variante).
- `sales`: client_id, client_name, payment (Efectivo/Transferencia), subtotal, discount, total,
  **status** ('activa' | 'devuelta' | 'anulada'), void_reason, void_note, voided_at.
- `sale_items`: sale_id, product_id, **variant_id**, name, variant, price, qty.
- RPC `create_sale(...)`: inserta venta + ítems y **descuenta stock** de cada variante, atómico.
- RPC `void_sale(id, reason, note)`: **descarta** una venta → devuelve el stock al inventario
  y marca `status` (devuelta/anulada). Idempotente (falla si ya está descartada).
- RLS: solo usuarios autenticados pueden leer/escribir.
- Storage: bucket público **`product-photos`** (políticas en schema.sql).

## Estructura del código

```
supabase/schema.sql   Tablas, RLS, create_sale, políticas de Storage
supabase/seed.sql     Datos de ejemplo (opcional)
src/supabase.js       Cliente Supabase (lee VITE_SUPABASE_*)
src/store.js          Carga/guarda datos + subida de fotos a Storage
src/sale.js           Estado del carrito / venta en curso
src/ui.js             Vista activa + modal abierto
src/utils.js          fmt moneda COP, fechas, resize de imágenes, colores
src/App.vue           Armazón: auth gate (login) + layout + modales
src/components/
  Login, Sidebar (con menú hamburguesa móvil)
  Dashboard, Sale, Products, Clients, Sales      (vistas)
  ProductForm, ProductDetail, ClientForm, ClientHistory, Receipt, Settings  (modales)
  Modal.vue  (envoltura de modal)
```

## Funcionalidad lista ✅

- Login email+contraseña (Supabase Auth). Usuarios se crean en Supabase → Authentication → Users.
- Tablero: ventas de hoy (efectivo/transferencia), del mes, # clientes, tallas por reponer.
- Productos: alta/edición/borrado, **variantes talla+color con stock propio**, **galería de fotos**.
- Ficha de producto (estilo Mercado Libre): galería + selector de color (con muestra) + tallas + cantidad.
- Nueva venta: catálogo → ficha → carrito, **descuento ($ o %)**, **método de pago**, cliente.
- Clientes: datos + teléfono + **historial de compras** y total gastado.
- Ventas: historial + **recibo imprimible/PDF** con logo.
- **Descartar venta** (Devolución / Anulación): devuelve el stock, sale de las métricas del tablero
  y del total gastado del cliente; la venta queda marcada (no se borra) y el recibo muestra el aviso.
  ⚠️ **Requiere aplicar `supabase/migrations_devoluciones.sql`** en Supabase → SQL Editor una vez.
- Ajustes: logo y nombre del negocio.
- **Responsive/móvil:** menú hamburguesa (drawer), listados como **tarjetas** en celular,
  formularios en 1 columna, y fix para que el badge de Netlify no tape los botones del modal.

## Pendiente / ideas para después 🔜

- [ ] **Probar a fondo el flujo de venta en el celular** (prenda → talla/color → carrito → registrar → recibo).
- [ ] Crear el **usuario de Laura** en Supabase (su propio correo/contraseña).
- [ ] (Opcional) Quitar el badge "Powered by Netlify".
- [ ] **Fotos por color** (que al elegir "Rojo" cambie la imagen, como Mercado Libre).
- [ ] **Entradas de inventario** (registrar mercancía que llega sin editar talla por talla).
- [ ] **Reportes**: gráfico de ventas por día, productos más vendidos, filtro por fechas.
- [ ] Posibles extras discutidos: fiado/abonos, varios precios/mayorista, dominio propio.

## Notas

- Los avisos `LF will be replaced by CRLF` al hacer commit son normales en Windows (inofensivos).
- `npm audit` reporta vulnerabilidades solo en dependencias de desarrollo (vite/esbuild); no afectan producción.
- El prototipo original (un solo archivo, localStorage) está en
  `C:\Users\Desarrollador\Documents\boutique-deploy\index.html` (referencia del diseño/flujo).
