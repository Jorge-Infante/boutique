<template>
  <div class="page-head">
    <div><h1>Clientes</h1><p>Sus datos y su historial de compras.</p></div>
    <button class="btn primary" @click="openModal('client', null)">
      <svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:1.9;fill:none"><path d="M12 5v14M5 12h14"/></svg>
      Agregar cliente
    </button>
  </div>

  <!-- Escritorio: tabla -->
  <div class="panel list-desktop"><div class="table-wrap"><table>
    <thead><tr><th>Cliente</th><th>Teléfono</th><th>Compras</th><th class="r">Total gastado</th><th class="r">Acciones</th></tr></thead>
    <tbody>
      <tr v-for="c in clients" :key="c.id">
        <td><div class="prodcell">
          <div class="avatar">{{ initials(c.name) }}</div>
          <div><b>{{ c.name }}</b><div v-if="c.note" class="cat">{{ c.note }}</div></div>
        </div></td>
        <td>{{ c.phone || '—' }}</td>
        <td class="num">{{ stats(c.id).count }}</td>
        <td class="r num">{{ fmt.format(stats(c.id).total) }}</td>
        <td class="r">
          <button class="btn ghost" @click="openModal('clienthist', c.id)">Historial</button>
          <button class="btn ghost" @click="openModal('client', c)">Editar</button>
          <button class="btn danger" @click="remove(c)">Eliminar</button>
        </td>
      </tr>
      <tr v-if="!clients.length"><td class="empty" colspan="5">Aún no hay clientes. Agrega el primero o se crean solos al vender.</td></tr>
    </tbody>
  </table></div></div>

  <!-- Móvil: tarjetas -->
  <div class="cards">
    <div class="card" v-for="c in clients" :key="c.id">
      <div class="card-top">
        <div class="avatar">{{ initials(c.name) }}</div>
        <div class="meta"><b>{{ c.name }}</b>
          <div class="cat">📞 {{ c.phone || '—' }}</div>
          <div v-if="c.note" class="cat">{{ c.note }}</div>
        </div>
      </div>
      <div class="card-row"><span class="k">Compras</span><span>{{ stats(c.id).count }}</span></div>
      <div class="card-row"><span class="k">Total gastado</span><span class="num"><b>{{ fmt.format(stats(c.id).total) }}</b></span></div>
      <div class="card-actions">
        <button class="btn sm" @click="openModal('clienthist', c.id)">Historial</button>
        <button class="btn sm" @click="openModal('client', c)">Editar</button>
        <button class="btn sm danger" @click="remove(c)">Eliminar</button>
      </div>
    </div>
    <p v-if="!clients.length" class="empty">Aún no hay clientes. Agrega el primero o se crean solos al vender.</p>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { store, deleteClient } from '../store'
import { openModal } from '../ui'
import { fmt, initials } from '../utils'

const clients = computed(() => store.clients)

function stats(id) {
  const ss = store.sales.filter(s => s.client_id === id)
  return { count: ss.length, total: ss.reduce((a, s) => a + Number(s.total), 0) }
}
async function remove(c) {
  if (confirm(`¿Eliminar al cliente "${c.name}"? Sus ventas se conservan.`)) await deleteClient(c.id)
}
</script>
