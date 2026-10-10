// Pedidos por enlace: el catálogo público arma el pedido y lo manda por WhatsApp con un
// enlace; la tienda lo abre con su usuario y el pedido se carga en Nueva venta.
import { fmt } from './utils'

export const CATALOG_PATH = '/catalogo'
export const ORDER_PATH = '/pedido'
const MAX_QTY = 99
const MAX_NAME = 60

const cleanPath = p => (p || '/').replace(/\/+$/, '') || '/'
export const isCatalogPath = (loc = location) => cleanPath(loc.pathname) === CATALOG_PATH
export const isOrderPath = (loc = location) => cleanPath(loc.pathname) === ORDER_PATH

// [{ vid, qty }] <-> "12.1-15.2"  (id de variante . cantidad)
export function encodeItems(items) {
  return items.map(i => `${i.vid}.${i.qty}`).join('-')
}

export function decodeItems(s) {
  const qty = new Map()
  for (const part of String(s || '').split('-')) {
    const [vid, q] = part.split('.').map(Number)
    if (Number.isInteger(vid) && vid > 0 && Number.isInteger(q) && q > 0)
      qty.set(vid, Math.min(MAX_QTY, (qty.get(vid) || 0) + q))
  }
  return [...qty].map(([vid, q]) => ({ vid, qty: q }))
}

export function orderUrl(items, name, origin = location.origin) {
  const params = new URLSearchParams({ c: encodeItems(items) })
  if (name && name.trim()) params.set('n', name.trim().slice(0, MAX_NAME))
  return `${origin}${ORDER_PATH}?${params}`
}

// Pedido que trae la URL, o null si no es un enlace de pedido válido
export function readOrder(loc = location) {
  if (!isOrderPath(loc)) return null
  const q = new URLSearchParams(loc.search)
  const items = decodeItems(q.get('c'))
  return items.length ? { items, name: (q.get('n') || '').trim().slice(0, MAX_NAME) } : null
}

// wa.me pide el número con indicativo y sin signos: "300 123 4567" → "573001234567"
export function waNumber(phone) {
  const d = String(phone || '').replace(/\D/g, '')
  return d.length === 10 && d.startsWith('3') ? '57' + d : d
}

// Sin número, WhatsApp deja elegir el chat
export function waLink(phone, text) {
  return `https://wa.me/${waNumber(phone)}?text=${encodeURIComponent(text)}`
}

// lines: [{ name, variant, price, qty }]
export function orderMessage(lines, name, url) {
  const total = lines.reduce((a, l) => a + l.price * l.qty, 0)
  const who = (name || '').trim()
  return [
    '¡Hola! Quiero hacer este pedido:',
    '',
    ...lines.map(l => `• ${l.name}${l.variant && l.variant !== 'Única' ? ` (${l.variant})` : ''} × ${l.qty}: ${fmt.format(l.price * l.qty)}`),
    '',
    `Total: ${fmt.format(total)}`,
    ...(who ? [`A nombre de: ${who}`] : []),
    '',
    'Enlace del pedido (para la tienda):',
    url,
  ].join('\n')
}
