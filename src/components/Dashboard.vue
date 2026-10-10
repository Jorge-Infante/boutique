<template>
  <div class="page-head">
    <div><h1>Tablero</h1><p>Un vistazo a cómo va el negocio hoy.</p></div>
    <button class="btn primary" @click="go('sale')">
      <svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:1.9;fill:none"><path d="M12 5v14M5 12h14"/></svg>
      Nueva venta
    </button>
  </div>

  <div class="kpis">
    <div class="kpi"><div class="lbl">Ventas de hoy</div><div class="val num">{{ fmt.format(totToday) }}</div>
      <div class="sub">💵 {{ fmt.format(cashToday) }} · 🏦 {{ fmt.format(transfToday) }}</div></div>
    <div class="kpi"><div class="lbl">Ventas del mes</div><div class="val num">{{ fmt.format(totMonth) }}</div>
      <div class="sub">{{ salesMonth.length }} venta(s)</div></div>
    <div class="kpi"><div class="lbl">Clientes</div><div class="val num">{{ store.clients.length }}</div>
      <div class="sub">registrados</div></div>
    <div class="kpi" :class="{ alert: lowRows.length }"><div class="lbl">Tallas por reponer</div>
      <div class="val num">{{ lowRows.length }}</div><div class="sub">stock bajo o agotado</div></div>
  </div>

  <div class="grid2">
    <div class="panel">
      <div class="panel-head"><h2>Ventas recientes</h2><button class="btn ghost" @click="go('sales')">Ver todas</button></div>
      <div class="table-wrap"><table>
        <thead><tr><th># / Cliente</th><th>Pago</th><th class="r">Total</th></tr></thead>
        <tbody>
          <tr v-for="s in recent" :key="s.id" style="cursor:pointer" @click="openModal('receipt', s.id)">
            <td><b>#{{ s.id }}</b><div class="cat">{{ s.client_name || 'Mostrador' }} · {{ fdate(s.created_at) }}</div></td>
            <td><span class="tag">{{ s.payment === 'Efectivo' ? '💵' : '🏦' }} {{ s.payment }}</span></td>
            <td class="r num"><b>{{ fmt.format(s.total) }}</b></td>
          </tr>
          <tr v-if="!recent.length"><td class="empty" colspan="3">Aún no hay ventas.</td></tr>
        </tbody>
      </table></div>
    </div>

    <div class="panel">
      <div class="panel-head"><h2>Hay que reponer</h2></div>
      <div class="table-wrap"><table><tbody>
        <tr v-for="(row, i) in lowRows" :key="i">
          <td><div class="prodcell">
            <img v-if="row.p.photos && row.p.photos[0]" class="thumb" :src="row.p.photos[0]" alt="" />
            <div v-else class="thumb-ph">{{ PH }}</div>
            <div><b>{{ row.p.name }}</b> <span class="talla">{{ vLabel(row.v) }}</span>
              <div class="cat">{{ row.p.category }}</div></div>
          </div></td>
          <td class="r">
            <span v-if="row.v.stock <= 0" class="pill crit">Agotado</span>
            <span v-else class="pill warn">Bajo · {{ row.v.stock }}</span>
          </td>
        </tr>
        <tr v-if="!lowRows.length"><td class="empty">Todo con buen stock 👍</td></tr>
      </tbody></table></div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { go, openModal } from '../ui'
import { fmt, fdate, vLabel, PH, isActiveSale } from '../utils'

const today = new Date().toISOString().slice(0, 10)
const month = today.slice(0, 7)

// Solo ventas activas cuentan para las métricas (las devueltas/anuladas no suman)
const activeSales = computed(() => store.sales.filter(isActiveSale))
const salesToday = computed(() => activeSales.value.filter(s => (s.created_at || '').slice(0, 10) === today))
const salesMonth = computed(() => activeSales.value.filter(s => (s.created_at || '').slice(0, 7) === month))
const totToday = computed(() => salesToday.value.reduce((a, s) => a + Number(s.total), 0))
const totMonth = computed(() => salesMonth.value.reduce((a, s) => a + Number(s.total), 0))
const cashToday = computed(() => salesToday.value.filter(s => s.payment === 'Efectivo').reduce((a, s) => a + Number(s.total), 0))
const transfToday = computed(() => salesToday.value.filter(s => s.payment === 'Transferencia').reduce((a, s) => a + Number(s.total), 0))
const recent = computed(() => activeSales.value.slice(0, 5))

const lowRows = computed(() => {
  const out = []
  for (const p of store.products)
    for (const v of (p.variants || []))
      if (v.stock <= p.min_stock) out.push({ p, v })
  return out
})
</script>
