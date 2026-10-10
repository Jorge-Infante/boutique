<template>
  <Modal klass="detail" @close="closeModal">
    <div class="modal-head"><h3>Detalle de la prenda</h3><button class="x" @click="closeModal">×</button></div>
    <div class="modal-body">
      <div class="det-grid">
        <div class="det-thumbs">
          <img v-for="(src, i) in photos" :key="i" :src="src" :class="{ on: i === sel.img }" @click="sel.img = i" alt="" />
        </div>
        <div class="det-main">
          <img v-if="photos[sel.img]" :src="photos[sel.img]" alt="" />
          <span v-else class="ph">{{ PH }}</span>
        </div>
        <div class="det-info">
          <div class="elbl">{{ p.category || 'Prenda' }}</div>
          <div class="det-title">{{ p.name }}</div>
          <div class="det-price num">{{ fmt.format(p.price) }}</div>

          <div v-if="colors.length" class="det-sect">
            <div class="lab">Color: <b>{{ sel.color || 'Elige' }}</b></div>
            <div class="chips">
              <button v-for="c in colors" :key="c" class="chip" :class="{ on: sel.color === c }"
                :disabled="!colorAvail(c) && sel.color !== c" @click="pickColor(c)">
                <span class="dot" :style="{ background: colorHex(c) }"></span>{{ c }}
              </button>
            </div>
          </div>

          <div v-if="sizes.length" class="det-sect">
            <div class="lab">Talla: <b>{{ sel.size || 'Elige' }}</b></div>
            <div class="chips">
              <button v-for="t in sizes" :key="t" class="chip" :class="{ on: sel.size === t }"
                :disabled="!sizeAvail(t) && sel.size !== t" @click="pickSize(t)">{{ t }}</button>
            </div>
          </div>

          <div v-if="needColor || needSize" class="det-stock" style="color:var(--muted)">
            Elige {{ [needColor ? 'color' : null, needSize ? 'talla' : null].filter(Boolean).join(' y ') }} para ver el stock.
          </div>
          <div v-else-if="variant && avail > 0" class="det-stock">
            <b>Stock disponible</b> · {{ avail }} {{ avail === 1 ? 'unidad' : 'unidades' }}
          </div>
          <div v-else class="det-stock" style="color:var(--crit)"><b>Sin stock</b> para esta combinación.</div>

          <div class="det-qty"><span class="elbl">Cantidad</span>
            <div class="qty">
              <button :disabled="sel.qty <= 1" @click="dec">–</button>
              <span class="num">{{ sel.qty }}</span>
              <button :disabled="sel.qty >= maxQ" @click="inc">+</button>
            </div>
          </div>

          <button class="btn primary block det-add" :disabled="!canAdd" @click="add">
            <svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:1.9;fill:none"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/></svg>
            Agregar al carrito
          </button>
        </div>
      </div>
    </div>
  </Modal>
</template>

<script setup>
import { reactive, computed, watch } from 'vue'
import { ui, closeModal, go } from '../ui'
import { saleState, availForVariant, addToCart } from '../sale'
import { fmt, colorHex, PH } from '../utils'
import Modal from './Modal.vue'

const p = ui.modalData
const photos = p.photos || []
const colors = [...new Set(p.variants.map(v => v.color).filter(Boolean))]
const sizes = [...new Set(p.variants.map(v => v.talla).filter(Boolean))]

// eslint-disable-next-line no-unused-vars
void saleState.cart  // mantiene reactividad de disponibilidad al cambiar el carrito

const sel = reactive({
  color: colors.length === 1 ? colors[0] : '',
  size: sizes.length === 1 ? sizes[0] : '',
  img: 0,
  qty: 1,
})

function colorAvail(c) {
  return p.variants.some(v => v.color === c &&
    (!sizes.length || !sel.size || v.talla === sel.size) && availForVariant(p, v) > 0)
}
function sizeAvail(t) {
  return p.variants.some(v => v.talla === t &&
    (!colors.length || !sel.color || v.color === sel.color) && availForVariant(p, v) > 0)
}

const variant = computed(() => p.variants.find(v =>
  (colors.length ? v.color === sel.color : true) && (sizes.length ? v.talla === sel.size : true)))
const avail = computed(() => variant.value ? availForVariant(p, variant.value) : null)
const needColor = computed(() => colors.length && !sel.color)
const needSize = computed(() => sizes.length && !sel.size)
const maxQ = computed(() => (variant.value && avail.value > 0) ? avail.value : 1)
const canAdd = computed(() => !!variant.value && avail.value > 0 && !needColor.value && !needSize.value &&
  sel.qty >= 1 && sel.qty <= maxQ.value)

watch(maxQ, m => { if (sel.qty > m) sel.qty = m })

function pickColor(c) { if (!colorAvail(c) && sel.color !== c) return; sel.color = c; sel.qty = 1 }
function pickSize(t) { if (!sizeAvail(t) && sel.size !== t) return; sel.size = t; sel.qty = 1 }
function inc() { if (sel.qty < maxQ.value) sel.qty++ }
function dec() { if (sel.qty > 1) sel.qty-- }
function add() {
  if (!canAdd.value) return
  addToCart(p, variant.value, sel.qty)
  closeModal()
  go('sale')
}
</script>
