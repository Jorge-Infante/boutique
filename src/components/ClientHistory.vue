<template>
  <Modal klass="wide" @close="closeModal">
    <div class="modal-head"><h3>{{ client ? client.name : 'Cliente' }}</h3>
      <button class="x" @click="closeModal">×</button></div>
    <div class="modal-body">
      <div style="display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px">
        <span class="tag">📞 {{ (client && client.phone) || 'Sin teléfono' }}</span>
        <span class="tag">🛍️ {{ activeCount }} compra(s)</span>
        <span class="tag">💰 {{ fmt.format(totalSpent) }} en total</span>
      </div>
      <div class="table-wrap"><table>
        <thead><tr><th>Venta</th><th>Pago</th><th class="r">Total</th></tr></thead>
        <tbody>
          <tr v-for="s in sales" :key="s.id" style="cursor:pointer" :class="{ voided: !isActiveSale(s) }" @click="openModal('receipt', s.id)">
            <td><b>#{{ s.id }}</b>
              <span v-if="!isActiveSale(s)" class="pill crit">{{ saleStatusLabel(s) }}</span>
              <div class="cat">{{ fdate(s.created_at) }}</div></td>
            <td><span class="tag">{{ s.payment === 'Efectivo' ? '💵' : '🏦' }} {{ s.payment }}</span></td>
            <td class="r num"><b>{{ fmt.format(s.total) }}</b></td>
          </tr>
          <tr v-if="!sales.length"><td class="empty" colspan="3">Este cliente aún no tiene compras.</td></tr>
        </tbody>
      </table></div>
    </div>
    <div class="modal-foot"><button class="btn" @click="closeModal">Cerrar</button></div>
  </Modal>
</template>

<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { ui, closeModal, openModal } from '../ui'
import { fmt, fdate, isActiveSale, saleStatusLabel } from '../utils'
import Modal from './Modal.vue'

const id = ui.modalData
const client = computed(() => store.clients.find(c => c.id === id))
const sales = computed(() => store.sales.filter(s => s.client_id === id))
const activeSales = computed(() => sales.value.filter(isActiveSale))
const activeCount = computed(() => activeSales.value.length)
const totalSpent = computed(() => activeSales.value.reduce((a, s) => a + Number(s.total), 0))
</script>

<style scoped>
tr.voided td { opacity:.55 }
tr.voided .num b, tr.voided td:first-child b { text-decoration:line-through }
</style>
