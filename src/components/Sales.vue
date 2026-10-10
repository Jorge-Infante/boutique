<template>
  <div class="page-head">
    <div><h1>Ventas</h1><p>Historial completo · {{ fmt.format(totalAll) }} en ventas activas.</p></div>
  </div>

  <!-- Escritorio: tabla -->
  <div class="panel list-desktop"><div class="table-wrap"><table>
    <thead><tr>
      <th>#</th><th>Cliente</th><th>Fecha</th><th>Pago</th><th>Ítems</th>
      <th class="r">Descuento</th><th class="r">Total</th><th class="r"></th>
    </tr></thead>
    <tbody>
      <tr v-for="s in sales" :key="s.id" :class="{ voided: !isActiveSale(s) }">
        <td><b>#{{ s.id }}</b></td>
        <td>{{ s.client_name || 'Mostrador' }}
          <span v-if="!isActiveSale(s)" class="pill crit">{{ saleStatusLabel(s) }}</span>
        </td>
        <td class="cat">{{ fdate(s.created_at) }}</td>
        <td><span class="tag">{{ s.payment === 'Efectivo' ? '💵' : '🏦' }} {{ s.payment || '—' }}</span></td>
        <td class="num">{{ itemCount(s) }} ítems</td>
        <td class="r num">{{ s.discount > 0 ? '–' + fmt.format(s.discount) : '—' }}</td>
        <td class="r num"><b>{{ fmt.format(s.total) }}</b></td>
        <td class="r actions">
          <button class="btn ghost" @click="openModal('receipt', s.id)">Ver recibo</button>
          <button v-if="isActiveSale(s)" class="btn danger" @click="openModal('void', s.id)">Descartar</button>
        </td>
      </tr>
      <tr v-if="!sales.length"><td class="empty" colspan="8">Todavía no has registrado ventas.</td></tr>
    </tbody>
  </table></div></div>

  <!-- Móvil: tarjetas -->
  <div class="cards">
    <div class="card" v-for="s in sales" :key="s.id" :class="{ voided: !isActiveSale(s) }">
      <div class="card-top">
        <div class="meta"><b>#{{ s.id }} · {{ s.client_name || 'Mostrador' }}</b>
          <div class="cat">{{ fdate(s.created_at) }}</div></div>
        <span v-if="!isActiveSale(s)" class="pill crit">{{ saleStatusLabel(s) }}</span>
        <span v-else class="tag">{{ s.payment === 'Efectivo' ? '💵' : '🏦' }} {{ s.payment || '—' }}</span>
      </div>
      <div class="card-row"><span class="k">Ítems</span><span>{{ itemCount(s) }}</span></div>
      <div class="card-row" v-if="s.discount > 0"><span class="k">Descuento</span><span class="num">–{{ fmt.format(s.discount) }}</span></div>
      <div class="card-row"><span class="k">Total</span><span class="num"><b>{{ fmt.format(s.total) }}</b></span></div>
      <div class="card-actions">
        <button class="btn sm" @click="openModal('receipt', s.id)">Ver recibo</button>
        <button v-if="isActiveSale(s)" class="btn sm danger" @click="openModal('void', s.id)">Descartar</button>
      </div>
    </div>
    <p v-if="!sales.length" class="empty">Todavía no has registrado ventas.</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { openModal } from '../ui'
import { fmt, fdate, isActiveSale, saleStatusLabel } from '../utils'

const sales = computed(() => store.sales)
const totalAll = computed(() =>
  store.sales.filter(isActiveSale).reduce((a, s) => a + Number(s.total), 0))

function itemCount(s) {
  return (s.items || []).reduce((a, i) => a + i.qty, 0)
}
</script>

<style scoped>
.actions { display:flex; gap:4px; justify-content:flex-end; white-space:nowrap }
tr.voided td { opacity:.55 }
tr.voided .num b, tr.voided td:first-child b { text-decoration:line-through }
.card.voided { opacity:.7 }
.card.voided .card-row .num b { text-decoration:line-through }
</style>
