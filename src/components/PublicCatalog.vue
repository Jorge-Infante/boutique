<template>
  <div class="pub">
    <header class="pub-top">
      <div class="pub-brand">
        <div class="mark">
          <img v-if="biz.logo_url" :src="biz.logo_url" alt="" />
          <template v-else>{{ initial }}</template>
        </div>
        <div class="pub-name"><b>{{ biz.name || 'Catálogo' }}</b><small>Haz tu pedido por WhatsApp</small></div>
      </div>
      <button class="btn primary pub-cartbtn" :disabled="!ready" @click="openCart">
        <svg viewBox="0 0 24 24"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/></svg>
        Mi pedido<span v-if="units" class="pub-count num">{{ units }}</span>
      </button>
    </header>

    <div v-if="loading" class="loading-screen"><div class="spinner"></div>Cargando catálogo…</div>

    <main v-else class="pub-main">
      <div v-if="error" class="panel empty">
        <p>No pudimos cargar el catálogo. Revisa tu conexión e intenta de nuevo.</p>
        <button class="btn" @click="load">Reintentar</button>
      </div>

      <template v-else>
        <div class="pub-filters">
          <input class="search" v-model="q" enterkeyhint="search" placeholder="Buscar prenda…" />
          <div v-if="categories.length > 1" class="chips">
            <button class="chip" :class="{ on: !cat }" @click="cat = ''">Todo</button>
            <button v-for="c in categories" :key="c" class="chip" :class="{ on: cat === c }" @click="cat = c">{{ c }}</button>
          </div>
        </div>

        <div class="pub-grid">
          <button v-for="p in list" :key="p.id" class="prod" @click="detail = p">
            <img v-if="p.photos && p.photos[0]" class="ph" :src="p.photos[0]" alt="" loading="lazy" />
            <div v-else class="ph-ph">{{ PH }}</div>
            <span class="body">
              <span class="nm">{{ p.name }}</span>
              <span class="pr num">{{ fmt.format(p.price) }}</span>
              <span class="st">{{ optionsOf(p) }}</span>
            </span>
          </button>
        </div>
        <p v-if="!list.length" class="empty">
          {{ products.length ? 'No encontramos prendas con esa búsqueda.' : 'Por ahora no hay prendas disponibles. ¡Vuelve pronto!' }}
        </p>
      </template>
    </main>

    <div v-if="toast" class="pub-toast">
      <span>{{ toast }}</span>
      <button v-if="units" @click="openCart">Ver pedido</button>
    </div>

    <ProductDetail v-if="detail" :product="detail" :avail="availOf" add-label="Agregar al pedido"
      :exact-stock="false" @add="addLine" @close="detail = null" />

    <Modal v-if="cartOpen" klass="wide" @close="cartOpen = false">
      <div class="modal-head"><h3>Mi pedido</h3><button class="x" @click="cartOpen = false">×</button></div>
      <div class="modal-body">
        <p v-if="!lines.length" class="empty">Tu pedido está vacío. Toca una prenda para agregarla.</p>
        <template v-else>
          <div v-for="l in lines" :key="l.vid" class="pub-line">
            <img v-if="l.photo" class="thumb" :src="l.photo" alt="" />
            <div v-else class="thumb-ph">{{ PH }}</div>
            <div class="info">
              <b>{{ l.name }}</b><span v-if="l.variant !== 'Única'" class="talla">{{ l.variant }}</span>
              <div class="cat num">{{ fmt.format(l.price) }} c/u</div>
            </div>
            <div class="qty">
              <button :aria-label="l.qty > 1 ? 'Quitar una' : 'Quitar del pedido'" @click="setQty(l.vid, l.qty - 1)">–</button>
              <span class="num">{{ l.qty }}</span>
              <button aria-label="Agregar una" :disabled="l.qty >= l.stock" @click="setQty(l.vid, l.qty + 1)">+</button>
            </div>
            <b class="lt num">{{ fmt.format(l.price * l.qty) }}</b>
          </div>
          <div class="sumrow total"><span>Total</span><span class="big num">{{ fmt.format(total) }}</span></div>
          <div class="field" style="margin-top:14px"><label>Tu nombre (opcional)</label>
            <input v-model="cart.name" maxlength="60" autocomplete="name" placeholder="Ej: María López" /></div>
          <p class="cat">Se abre WhatsApp con tu pedido escrito; solo tienes que enviarlo.
            La tienda te confirma disponibilidad y forma de pago.</p>
        </template>
      </div>
      <div class="modal-foot">
        <template v-if="lines.length">
          <button class="btn" @click="clearCart">Vaciar</button>
          <a class="btn primary" :href="waHref" target="_blank" rel="noopener">Enviar por WhatsApp</a>
        </template>
        <button v-else class="btn primary" @click="cartOpen = false">Ver prendas</button>
      </div>
    </Modal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { supabase } from '../supabase'
import { fmt, vLabel, norm, PH } from '../utils'
import { orderUrl, orderMessage, waLink } from '../order'
import ProductDetail from './ProductDetail.vue'
import Modal from './Modal.vue'

// Catálogo público: se abre sin sesión. Solo trae prendas con stock (y solo sus
// variantes con stock): lo filtra la función public_catalog en la base de datos.
const loading = ref(true)
const error = ref(false)
const ready = ref(false)
const biz = ref({})
const products = ref([])
const q = ref('')
const cat = ref('')
const detail = ref(null)
const cartOpen = ref(false)
const toast = ref('')

// El pedido queda guardado en este navegador para no perderlo al recargar
const KEY = 'boutique.pedido'
const cart = reactive(readCart())
watch(cart, c => {
  try { localStorage.setItem(KEY, JSON.stringify(c)) } catch { /* navegador sin almacenamiento */ }
}, { deep: true })

function readCart() {
  try {
    const d = JSON.parse(localStorage.getItem(KEY) || 'null')
    if (d && Array.isArray(d.items)) return {
      items: d.items.filter(i => Number.isInteger(i.vid) && Number.isInteger(i.qty) && i.qty > 0),
      name: typeof d.name === 'string' ? d.name : '',
    }
  } catch { /* dato dañado o navegador sin almacenamiento */ }
  return { items: [], name: '' }
}

async function load() {
  loading.value = true
  error.value = false
  const { data, error: err } = await supabase.rpc('public_catalog')
  if (err || !data) {
    error.value = true
  } else {
    biz.value = data.business || {}
    products.value = (data.products || []).map(p => ({ ...p, variants: p.variants || [] }))
    document.title = `${biz.value.name || 'Catálogo'} · Catálogo`
    fitCart()
    ready.value = true
  }
  loading.value = false
}
onMounted(load)

const byVid = computed(() => {
  const m = new Map()
  for (const p of products.value) for (const v of p.variants) m.set(v.id, { p, v })
  return m
})

// Ajusta un pedido guardado a lo que hay hoy: quita lo agotado y limita cantidades
function fitCart() {
  const before = cart.items.length
  cart.items = cart.items
    .filter(i => byVid.value.has(i.vid))
    .map(i => ({ vid: i.vid, qty: Math.min(i.qty, byVid.value.get(i.vid).v.stock) }))
  if (cart.items.length < before) flash('Algunas prendas de tu pedido ya no están disponibles.')
}

const categories = computed(() =>
  [...new Set(products.value.map(p => p.category).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'es')))

const list = computed(() => {
  const s = norm(q.value)
  return products.value.filter(p =>
    (!cat.value || p.category === cat.value) &&
    (!s || norm(p.name).includes(s) || norm(p.category).includes(s)))
})

function optionsOf(p) {
  const tallas = [...new Set(p.variants.map(v => v.talla).filter(Boolean))]
  if (tallas.length === 1 && tallas[0] === 'Única') return 'Talla única'
  if (tallas.length) return 'Tallas: ' + tallas.join(' · ')
  const colores = new Set(p.variants.map(v => v.color).filter(Boolean)).size
  return colores > 1 ? `${colores} colores` : ''
}

const lines = computed(() => cart.items.map(i => {
  const hit = byVid.value.get(i.vid)
  if (!hit) return null
  const { p, v } = hit
  return {
    vid: v.id, name: p.name, variant: vLabel(v), price: Number(p.price),
    qty: i.qty, stock: v.stock, photo: (p.photos || [])[0],
  }
}).filter(Boolean))

const units = computed(() => lines.value.reduce((a, l) => a + l.qty, 0))
const total = computed(() => lines.value.reduce((a, l) => a + l.price * l.qty, 0))

function qtyOf(vid) {
  const it = cart.items.find(i => i.vid === vid)
  return it ? it.qty : 0
}
function availOf(v) { return v.stock - qtyOf(v.id) }

function addLine(v, qty) {
  const name = detail.value.name
  const it = cart.items.find(i => i.vid === v.id)
  if (it) it.qty = Math.min(v.stock, it.qty + qty)
  else cart.items.push({ vid: v.id, qty: Math.min(v.stock, qty) })
  detail.value = null
  flash(`Agregado: ${name}`)
}

function setQty(vid, n) {
  const hit = byVid.value.get(vid)
  if (!hit) return
  if (n <= 0) cart.items = cart.items.filter(i => i.vid !== vid)
  else cart.items.find(i => i.vid === vid).qty = Math.min(n, hit.v.stock)
}

function clearCart() {
  if (confirm('¿Vaciar tu pedido?')) cart.items = []
}

let toastTimer
function flash(msg) {
  toast.value = msg
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.value = '' }, 3500)
}
function openCart() {
  toast.value = ''
  cartOpen.value = true
}

const initial = computed(() => (biz.value.name || 'C').trim().charAt(0).toUpperCase())

// Mensaje para WhatsApp: el detalle para leer + el enlace que la tienda abre con su usuario
const waHref = computed(() => {
  const url = orderUrl(lines.value.map(l => ({ vid: l.vid, qty: l.qty })), cart.name)
  return waLink(biz.value.whatsapp, orderMessage(lines.value, cart.name, url))
})
</script>
