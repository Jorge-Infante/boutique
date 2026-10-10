<template>
  <div class="page-head">
    <div><h1>Productos</h1><p>Cada prenda con sus fotos, tallas/colores y stock.</p></div>
    <button class="btn primary" @click="openModal('product', null)">
      <svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:1.9;fill:none"><path d="M12 5v14M5 12h14"/></svg>
      Agregar prenda
    </button>
  </div>

  <div class="panel"><div class="table-wrap"><table>
    <thead><tr><th>Prenda</th><th>Categoría</th><th class="r">Precio</th><th class="r">Stock total</th><th class="r">Acciones</th></tr></thead>
    <tbody>
      <tr v-for="p in products" :key="p.id">
        <td><div class="prodcell">
          <img v-if="p.photos && p.photos[0]" class="thumb" :src="p.photos[0]" alt="" />
          <div v-else class="thumb-ph">{{ PH }}</div>
          <div><b>{{ p.name }}</b><div class="vsum">{{ summary(p) }}</div></div>
        </div></td>
        <td class="cat">{{ p.category }}</td>
        <td class="r num">{{ fmt.format(p.price) }}</td>
        <td class="r" v-html="pill(p)"></td>
        <td class="r">
          <button class="btn ghost" @click="openModal('detail', p)">Ver</button>
          <button class="btn ghost" @click="openModal('product', p)">Editar</button>
          <button class="btn danger" @click="remove(p)">Eliminar</button>
        </td>
      </tr>
      <tr v-if="!products.length"><td class="empty" colspan="5">Sin prendas. Agrega la primera.</td></tr>
    </tbody>
  </table></div></div>
</template>

<script setup>
import { computed } from 'vue'
import { store, deleteProduct } from '../store'
import { openModal } from '../ui'
import { fmt, vLabel, totalStock, PH } from '../utils'

const products = computed(() => store.products)

function summary(p) {
  return (p.variants || []).map(v => `${vLabel(v)}: ${v.stock}`).join('  ·  ')
}
function pill(p) {
  const tot = totalStock(p)
  if (tot <= 0) return '<span class="pill crit">Agotado</span>'
  if ((p.variants || []).some(v => v.stock <= p.min_stock)) return `<span class="pill warn">${tot} · reponer</span>`
  return `<span class="pill good">${tot} disp.</span>`
}
async function remove(p) {
  if (confirm(`¿Eliminar "${p.name}"?`)) await deleteProduct(p.id)
}
</script>
