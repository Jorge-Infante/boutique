export const fmt = new Intl.NumberFormat('es-CO', {
  style: 'currency', currency: 'COP', maximumFractionDigits: 0,
})

export const PH = '👚'

export function vLabel(v) {
  return [v.talla, v.color].filter(Boolean).join(' · ') || 'Única'
}

export function initials(name) {
  return (name || '?').trim().split(/\s+/).slice(0, 2).map(w => w.charAt(0).toUpperCase()).join('')
}

export function fdate(iso) {
  const d = new Date(iso)
  return d.toLocaleDateString('es-CO', { day: '2-digit', month: 'short' }) +
    ' · ' + d.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit' })
}

const COLOR_HEX = {
  blanco:'#ffffff', negro:'#222222', rojo:'#c0392b', azul:'#2d6cdf', rosa:'#e58fb0', rosado:'#e58fb0',
  gris:'#9aa0a6', verde:'#2e7d4f', amarillo:'#f1c40f', beige:'#d9c7a3', 'café':'#6f4e37', cafe:'#6f4e37',
  'marrón':'#6f4e37', marron:'#6f4e37', morado:'#7d3c98', lila:'#b39ddb', naranja:'#e67e22',
  vinotinto:'#7c2d3a', dorado:'#caa94e', plateado:'#c9ccd1', turquesa:'#1ab6b0', fucsia:'#d6246e',
  crema:'#f3ead6', celeste:'#8ec9e8',
}
export function colorHex(name) {
  return COLOR_HEX[(name || '').toLowerCase().trim()] || '#ded7db'
}

export function totalStock(p) {
  return (p.variants || []).reduce((a, v) => a + (v.stock || 0), 0)
}

// ---------- Estado de la venta ----------
export function isActiveSale(s) {
  return (s.status || 'activa') === 'activa'
}

// Etiqueta corta para mostrar el estado de una venta descartada
export function saleStatusLabel(s) {
  if (s.status === 'devuelta') return 'Devuelta'
  if (s.status === 'anulada') return 'Anulada'
  return 'Activa'
}

// Lee un archivo de imagen y lo reduce a un data URL JPEG más liviano
export function resizeImage(file, maxDim = 800) {
  return new Promise((resolve) => {
    if (!file) return resolve('')
    const r = new FileReader()
    r.onload = () => {
      const img = new Image()
      img.onload = () => {
        let w = img.width, h = img.height
        if (w > h && w > maxDim) { h = Math.round(h * maxDim / w); w = maxDim }
        else if (h > maxDim) { w = Math.round(w * maxDim / h); h = maxDim }
        const c = document.createElement('canvas')
        c.width = w; c.height = h
        c.getContext('2d').drawImage(img, 0, 0, w, h)
        resolve(c.toDataURL('image/jpeg', 0.82))
      }
      img.onerror = () => resolve('')
      img.src = r.result
    }
    r.readAsDataURL(file)
  })
}
