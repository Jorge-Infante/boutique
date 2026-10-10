<template>
  <Modal @close="closeModal">
    <div class="modal-head"><h3>Descartar venta #{{ sale ? sale.id : '' }}</h3>
      <button class="x" @click="closeModal">×</button></div>

    <div class="modal-body" v-if="sale">
      <p class="hint">
        Esta venta se marcará como descartada, saldrá de las métricas y del historial del cliente,
        y <b>el stock volverá al inventario</b>. No se borra: queda registrada con su motivo.
      </p>

      <label class="fld">
        <span>Motivo</span>
        <select v-model="reason">
          <option value="devolucion">Devolución · el cliente trajo la mercancía</option>
          <option value="anulacion">Anulación · se registró mal (error / duplicada / prueba)</option>
        </select>
      </label>

      <label class="fld">
        <span>Nota (opcional)</span>
        <input v-model="note" type="text" placeholder="Ej: cambió de talla, se registró dos veces…" />
      </label>

      <div class="restock">
        <div class="restock-head">Vuelve al inventario:</div>
        <div class="restock-row" v-for="(i, idx) in sale.items" :key="idx">
          <span>{{ i.name }}<template v-if="i.variant && i.variant !== 'Única'"> · {{ i.variant }}</template></span>
          <span class="num">+{{ i.qty }}</span>
        </div>
        <p v-if="!sale.items || !sale.items.length" class="empty">Esta venta no tiene ítems.</p>
      </div>
    </div>

    <div class="modal-foot">
      <button class="btn" @click="closeModal" :disabled="busy">Cancelar</button>
      <button class="btn danger" @click="confirm" :disabled="busy">
        {{ busy ? 'Descartando…' : 'Descartar venta' }}
      </button>
    </div>
  </Modal>
</template>

<script setup>
import { ref, computed } from 'vue'
import { store, voidSale } from '../store'
import { ui, closeModal } from '../ui'
import Modal from './Modal.vue'

const sale = computed(() => store.sales.find(s => s.id === ui.modalData))
const reason = ref('devolucion')
const note = ref('')
const busy = ref(false)

async function confirm() {
  if (!sale.value || busy.value) return
  busy.value = true
  try {
    await voidSale(sale.value.id, reason.value, note.value.trim())
    closeModal()
  } catch (e) {
    alert('No se pudo descartar la venta: ' + (e.message || e))
    busy.value = false
  }
}
</script>

<style scoped>
.hint { color:#666; font-size:13px; line-height:1.5; margin:0 0 14px }
.fld { display:block; margin-bottom:12px }
.fld > span { display:block; font-size:13px; font-weight:600; margin-bottom:5px }
.fld select, .fld input { width:100%; padding:9px 11px; border:1px solid #ddd; border-radius:9px; font:inherit }
.restock { margin-top:6px; border:1px solid #eee; border-radius:11px; padding:10px 12px; background:#fafafa }
.restock-head { font-size:12px; font-weight:700; color:#777; text-transform:uppercase; letter-spacing:.03em; margin-bottom:6px }
.restock-row { display:flex; justify-content:space-between; gap:12px; padding:3px 0; font-size:14px }
.restock-row .num { font-variant-numeric:tabular-nums; color:#2e7d4f; font-weight:700 }
/* Botón de confirmar: sólido para que destaque como acción principal */
.modal-foot .btn.danger { background:var(--crit); color:#fff; padding:9px 14px }
.modal-foot .btn.danger:hover { filter:brightness(.94) }
.modal-foot .btn.danger:disabled { opacity:.6; cursor:default }
</style>
