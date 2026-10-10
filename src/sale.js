import { reactive } from 'vue'
import { norm } from './utils'

// Estado de la venta en curso (compartido entre el catálogo, la ficha y el carrito)
export const saleState = reactive({
  cart: [],                       // { key, pid, vid, name, variant, price, qty }
  disc: { val: 0, type: '$' },    // descuento: $ (pesos) o %
  pay: 'Efectivo',                // Efectivo | Transferencia
  clientName: 'Mostrador',
  q: '',                          // búsqueda
  notice: null,                   // pedido que llegó del catálogo: { name, units, warnings }
  fromOrder: false,               // la venta viene de un pedido del catálogo
})

export function resetSale() {
  saleState.cart = []
  saleState.disc = { val: 0, type: '$' }
  saleState.pay = 'Efectivo'
  saleState.clientName = 'Mostrador'
  saleState.q = ''
  saleState.notice = null
  saleState.fromOrder = false
}

// Carga en la venta un pedido que llegó por enlace del catálogo público.
// Usa precios y stock actuales, y avisa lo que ya no está o no alcanza.
export function loadOrder(order, products, clients) {
  resetSale()
  const warnings = []
  let units = 0, gone = 0
  for (const { vid, qty } of order.items) {
    const p = products.find(x => (x.variants || []).some(v => v.id === vid))
    const v = p && p.variants.find(x => x.id === vid)
    if (!v) { gone++; continue }
    const avail = availForVariant(p, v)
    const label = `${p.name} (${labelOf(v)})`
    if (avail <= 0) { warnings.push(`${label}: agotada.`); continue }
    if (avail < qty) warnings.push(`${label}: pidió ${qty}, solo hay ${avail}.`)
    addToCart(p, v, qty)
    units += Math.min(qty, avail)
  }
  if (gone) warnings.push(gone === 1
    ? 'Una prenda del pedido ya no está en el inventario.'
    : `${gone} prendas del pedido ya no están en el inventario.`)

  // Si la clienta ya existe (aunque la escriba sin tildes o en minúsculas), se usa esa
  const name = order.name || ''
  if (name) {
    const known = clients.find(c => norm(c.name) === norm(name))
    saleState.clientName = known ? known.name : name
  }
  saleState.notice = { name: name ? saleState.clientName : '', units, warnings }
  saleState.fromOrder = true
}

export function cartQtyFor(pid, vid) {
  const l = saleState.cart.find(c => c.pid === pid && c.vid === vid)
  return l ? l.qty : 0
}

export function availForVariant(p, v) {
  return v.stock - cartQtyFor(p.id, v.id)
}

export function addToCart(p, v, qty = 1) {
  const avail = availForVariant(p, v)
  if (avail <= 0) return
  qty = Math.min(Math.max(1, qty), avail)
  const key = p.id + ':' + v.id
  const line = saleState.cart.find(c => c.key === key)
  if (line) line.qty += qty
  else saleState.cart.push({ key, pid: p.id, vid: v.id, name: p.name, variant: labelOf(v), price: p.price, qty })
}

export function changeQty(key, delta, products) {
  const line = saleState.cart.find(c => c.key === key)
  if (!line) return
  const p = products.find(x => x.id === line.pid)
  const v = p && (p.variants || []).find(x => x.id === line.vid)
  const nq = line.qty + delta
  if (nq <= 0) saleState.cart = saleState.cart.filter(c => c.key !== key)
  else if (v && nq > v.stock) { /* no pasar del stock */ }
  else line.qty = nq
}

export function saleTotals() {
  const subtotal = saleState.cart.reduce((a, c) => a + c.price * c.qty, 0)
  const d = saleState.disc
  let disc = 0
  if (d.type === '%') disc = Math.round(subtotal * Math.min(100, Math.max(0, +d.val || 0)) / 100)
  else disc = Math.min(subtotal, Math.max(0, +d.val || 0))
  return { subtotal, disc, total: Math.max(0, subtotal - disc) }
}

function labelOf(v) {
  return [v.talla, v.color].filter(Boolean).join(' · ') || 'Única'
}
