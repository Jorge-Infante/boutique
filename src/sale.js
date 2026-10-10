import { reactive } from 'vue'

// Estado de la venta en curso (compartido entre el catálogo, la ficha y el carrito)
export const saleState = reactive({
  cart: [],                       // { key, pid, vid, name, variant, price, qty }
  disc: { val: 0, type: '$' },    // descuento: $ (pesos) o %
  pay: 'Efectivo',                // Efectivo | Transferencia
  clientName: 'Mostrador',
  q: '',                          // búsqueda
})

export function resetSale() {
  saleState.cart = []
  saleState.disc = { val: 0, type: '$' }
  saleState.pay = 'Efectivo'
  saleState.clientName = 'Mostrador'
  saleState.q = ''
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
