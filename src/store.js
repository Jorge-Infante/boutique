import { reactive } from 'vue'
import { supabase } from './supabase'

export const store = reactive({
  ready: false,
  loading: false,
  settings: { business_name: 'Mi Boutique', logo_url: '' },
  clients: [],
  products: [],   // cada producto incluye .variants
  sales: [],      // cada venta incluye .items
})

export async function loadAll() {
  store.loading = true
  const [settings, clients, products, variants, sales, items] = await Promise.all([
    supabase.from('app_settings').select('*').eq('id', 1).maybeSingle(),
    supabase.from('clients').select('*').order('name'),
    supabase.from('products').select('*').order('name'),
    supabase.from('variants').select('*').order('id'),
    supabase.from('sales').select('*').order('created_at', { ascending: false }),
    supabase.from('sale_items').select('*'),
  ])

  if (settings.data) store.settings = settings.data
  store.clients = clients.data || []

  const vByP = {}
  for (const v of (variants.data || [])) (vByP[v.product_id] ||= []).push(v)
  store.products = (products.data || []).map(p => ({ ...p, variants: vByP[p.id] || [] }))

  const itBySale = {}
  for (const i of (items.data || [])) (itBySale[i.sale_id] ||= []).push(i)
  store.sales = (sales.data || []).map(s => ({ ...s, items: itBySale[s.id] || [] }))

  store.ready = true
  store.loading = false
}

// ---------- Storage (fotos) ----------
async function uploadDataUrl(dataUrl, folder = 'products') {
  const blob = await (await fetch(dataUrl)).blob()
  const path = `${folder}/${Date.now()}-${Math.random().toString(36).slice(2)}.jpg`
  const { error } = await supabase.storage.from('product-photos')
    .upload(path, blob, { contentType: 'image/jpeg', upsert: false })
  if (error) throw error
  return supabase.storage.from('product-photos').getPublicUrl(path).data.publicUrl
}

// Sube las fotos nuevas (data:) y conserva las que ya son URLs
async function resolvePhotos(photos, folder) {
  const out = []
  for (const ph of (photos || [])) {
    out.push(ph.startsWith('data:') ? await uploadDataUrl(ph, folder) : ph)
  }
  return out
}

// ---------- Settings ----------
export async function saveSettings({ business_name, logo_url, whatsapp }) {
  const logo = logo_url && logo_url.startsWith('data:')
    ? await uploadDataUrl(logo_url, 'logo')
    : logo_url
  const row = { business_name, logo_url: logo }
  // La columna whatsapp llega con migrations_catalogo.sql; sin ella se guarda lo demás
  if ('whatsapp' in store.settings) row.whatsapp = whatsapp || ''
  const { error } = await supabase.from('app_settings').update(row).eq('id', 1)
  if (error) throw error
  await loadAll()
}

// ---------- Clientes ----------
export async function saveClient(c) {
  const row = { name: c.name, phone: c.phone || '', note: c.note || '' }
  let saved
  if (c.id) {
    const { data, error } = await supabase.from('clients').update(row).eq('id', c.id).select().single()
    if (error) throw error; saved = data
  } else {
    const { data, error } = await supabase.from('clients').insert(row).select().single()
    if (error) throw error; saved = data
  }
  await loadAll()
  return saved
}

export async function deleteClient(id) {
  const { error } = await supabase.from('clients').delete().eq('id', id)
  if (error) throw error
  await loadAll()
}

// ---------- Productos ----------
export async function saveProduct(p) {
  const photos = await resolvePhotos(p.photos, 'products')
  const row = { name: p.name, category: p.category || 'General', price: p.price || 0, min_stock: p.min_stock || 0, photos }

  let id = p.id
  if (id) {
    const { error } = await supabase.from('products').update(row).eq('id', id)
    if (error) throw error
  } else {
    const { data, error } = await supabase.from('products').insert(row).select('id').single()
    if (error) throw error; id = data.id
  }

  // Sincroniza las variantes CONSERVANDO sus ids (las ventas y los pedidos por enlace
  // las referencian): borra solo las que se quitaron, actualiza las que siguen y
  // agrega las nuevas.
  const vrow = v => ({ talla: v.talla || '', color: v.color || '', stock: v.stock || 0 })
  const kept = (p.variants || []).filter(v => v.id)
  const added = (p.variants || []).filter(v => !v.id)

  let removed = supabase.from('variants').delete().eq('product_id', id)
  if (kept.length) removed = removed.not('id', 'in', `(${kept.map(v => v.id).join(',')})`)
  const { error: delError } = await removed
  if (delError) throw delError

  const updates = await Promise.all(kept.map(v =>
    supabase.from('variants').update(vrow(v)).eq('id', v.id).eq('product_id', id)))
  const failed = updates.find(r => r.error)
  if (failed) throw failed.error

  if (added.length) {
    const { error } = await supabase.from('variants').insert(added.map(v => ({ product_id: id, ...vrow(v) })))
    if (error) throw error
  }
  await loadAll()
}

export async function deleteProduct(id) {
  const { error } = await supabase.from('products').delete().eq('id', id)
  if (error) throw error
  await loadAll()
}

// ---------- Ventas ----------
// Resuelve el cliente por nombre (crea uno si no existe y no es "Mostrador")
async function resolveClientId(name) {
  name = (name || '').trim()
  if (!name || name.toLowerCase() === 'mostrador') return { id: null, name: 'Mostrador' }
  const found = store.clients.find(c => c.name.toLowerCase() === name.toLowerCase())
  if (found) return { id: found.id, name: found.name }
  const created = await saveClient({ name })
  return { id: created.id, name: created.name }
}

export async function createSale({ clientName, payment, totals, cart }) {
  const cli = await resolveClientId(clientName)
  const items = cart.map(c => ({
    product_id: c.pid, variant_id: c.vid, name: c.name, variant: c.variant, price: c.price, qty: c.qty,
  }))
  const { data, error } = await supabase.rpc('create_sale', {
    p_client_id: cli.id,
    p_client_name: cli.name,
    p_payment: payment,
    p_subtotal: totals.subtotal,
    p_discount: totals.disc,
    p_total: totals.total,
    p_items: items,
  })
  if (error) throw error
  await loadAll()
  return data // id de la venta
}

// Descarta una venta: devuelve el stock y la marca como devuelta/anulada.
// reason: 'devolucion' | 'anulacion'
export async function voidSale(id, reason, note = '') {
  const { error } = await supabase.rpc('void_sale', {
    p_sale_id: id,
    p_reason: reason,
    p_note: note || null,
  })
  if (error) throw error
  await loadAll()
}
