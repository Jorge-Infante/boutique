<template>
  <div class="page-head">
    <div><h1>Nueva venta</h1><p>Toca una prenda para ver su ficha y elegir color/talla.</p></div>
  </div>

  <div class="sale">
    <div class="panel">
      <div style="padding:14px 16px 0">
        <input class="search" v-model="saleState.q" placeholder="Buscar prenda o categoría…" />
      </div>
      <div class="picker">
        <button v-for="p in list" :key="p.id" class="prod" :disabled="left(p) <= 0" @click="openModal('detail', p)">
          <img v-if="p.photos && p.photos[0]" class="ph" :src="p.photos[0]" alt="" />
          <div v-else class="ph-ph">{{ PH }}</div>
          <span class="body">
            <span class="nm">{{ p.name }}</span>
            <span class="pr num">{{ fmt.format(p.price) }}</span>
            <span class="st">{{ left(p) > 0 ? left(p) + ' disponibles · ' + p.variants.length + ' opción(es)' : 'Sin stock' }}</span>
          </span>
        </button>
        <p v-if="!list.length" class="cat">No hay prendas. Agrégalas en la sección Productos.</p>
      </div>
    </div>

    <div class="panel cart">
      <div class="panel-head"><h2>Carrito</h2>
        <button v-if="saleState.cart.length" class="btn ghost" @click="saleState.cart = []">Vaciar</button>
      </div>
      <div style="padding:4px 18px 16px">
        <div v-for="c in saleState.cart" :key="c.key" class="line">
          <span class="nm">{{ c.name }} <span class="talla">{{ c.variant }}</span></span>
          <div class="qty">
            <button @click="changeQty(c.key, -1, store.products)">–</button>
            <span class="num">{{ c.qty }}</span>
            <button @click="changeQty(c.key, 1, store.products)">+</button>
          </div>
          <span class="lt num">{{ fmt.format(c.price * c.qty) }}</span>
        </div>
        <p v-if="!saleState.cart.length" class="cat" style="padding:20px 0">El carrito está vacío.</p>

        <div class="sumrow"><span>Subtotal</span><span class="num">{{ fmt.format(totals.subtotal) }}</span></div>
        <div class="sumrow"><span>Descuento</span>
          <span class="disc-input">
            <input type="number" min="0" v-model.number="saleState.disc.val" placeholder="0" />
            <select v-model="saleState.disc.type"><option value="$">$</option><option value="%">%</option></select>
          </span>
        </div>
        <div class="sumrow total"><span>Total</span><span class="big num">{{ fmt.format(totals.total) }}</span></div>

        <div class="field" style="margin-top:14px"><label>Método de pago</label>
          <div class="seg">
            <button :class="{ on: saleState.pay === 'Efectivo' }" @click="saleState.pay = 'Efectivo'">💵 Efectivo</button>
            <button :class="{ on: saleState.pay === 'Transferencia' }" @click="saleState.pay = 'Transferencia'">🏦 Transferencia</button>
          </div>
        </div>

        <div class="field"><label>Cliente</label>
          <div style="display:flex;gap:6px">
            <select v-model="saleState.clientName" style="flex:1">
              <option value="Mostrador">Mostrador</option>
              <option v-for="c in store.clients" :key="c.id" :value="c.name">
                {{ c.name }}{{ c.phone ? ' · ' + c.phone : '' }}
              </option>
            </select>
            <button class="btn sm" type="button" @click="openModal('client', { fromSale: true })">+ Nuevo</button>
          </div>
        </div>

        <button class="btn primary block" :disabled="!saleState.cart.length || busy" @click="checkout">
          {{ busy ? 'Guardando…' : 'Registrar venta · ' + fmt.format(totals.total) }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { store, createSale } from '../store'
import { openModal, go } from '../ui'
import { saleState, saleTotals, changeQty, availForVariant, resetSale } from '../sale'
import { fmt, PH } from '../utils'

const busy = ref(false)

const list = computed(() => {
  const q = (saleState.q || '').toLowerCase()
  return store.products.filter(p =>
    p.name.toLowerCase().includes(q) || (p.category || '').toLowerCase().includes(q))
})
const totals = computed(() => saleTotals())

function left(p) {
  return (p.variants || []).reduce((a, v) => a + Math.max(0, availForVariant(p, v)), 0)
}

async function checkout() {
  if (!saleState.cart.length) return
  busy.value = true
  try {
    const id = await createSale({
      clientName: saleState.clientName,
      payment: saleState.pay,
      totals: saleTotals(),
      cart: saleState.cart,
    })
    resetSale()
    go('sales')
    openModal('receipt', id)
  } catch (e) {
    alert('No se pudo registrar la venta: ' + (e.message || e))
  } finally {
    busy.value = false
  }
}
</script>
