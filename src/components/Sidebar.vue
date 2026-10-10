<template>
  <aside class="side no-print">
    <div class="brand">
      <div class="mark">
        <img v-if="store.settings.logo_url" :src="store.settings.logo_url" alt="logo" />
        <template v-else>{{ (store.settings.business_name || 'B').trim().charAt(0).toUpperCase() }}</template>
      </div>
      <div>
        <b>{{ store.settings.business_name || 'Mi Boutique' }}</b>
        <small>Inventario · Ventas</small>
      </div>
    </div>

    <nav class="nav">
      <button v-for="n in items" :key="n.v" :class="{ active: ui.view === n.v }" @click="go(n.v)">
        <span v-html="n.icon"></span><span>{{ n.label }}</span>
      </button>
    </nav>

    <div class="side-foot">
      <button @click="openModal('settings')">
        <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7 19.4a1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H1a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 2.6 7a1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 7 2.6h.1A1.6 1.6 0 0 0 9 1.1V1a2 2 0 1 1 4 0v.1A1.6 1.6 0 0 0 15 2.6h.1a1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8v.1a1.6 1.6 0 0 0 1.5 1H23a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/></svg>
        Logo y nombre
      </button>
      <button @click="logout">
        <svg viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/></svg>
        Cerrar sesión
      </button>
    </div>
  </aside>
</template>

<script setup>
import { store } from '../store'
import { ui, go, openModal } from '../ui'
import { supabase } from '../supabase'

const items = [
  { v: 'dash', label: 'Tablero', icon: '<svg viewBox="0 0 24 24"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>' },
  { v: 'sale', label: 'Nueva venta', icon: '<svg viewBox="0 0 24 24"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/></svg>' },
  { v: 'products', label: 'Productos', icon: '<svg viewBox="0 0 24 24"><path d="M20.4 7.5 12 2 3.6 7.5 12 13l8.4-5.5z"/><path d="M3.6 7.5V16L12 21.5 20.4 16V7.5"/></svg>' },
  { v: 'clients', label: 'Clientes', icon: '<svg viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.9"/><path d="M16 3.1a4 4 0 0 1 0 7.8"/></svg>' },
  { v: 'sales', label: 'Ventas', icon: '<svg viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M8 13h8M8 17h8"/></svg>' },
]

async function logout() {
  await supabase.auth.signOut()
}
</script>
