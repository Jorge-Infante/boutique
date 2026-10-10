<template>
  <div v-if="!authReady" class="loading-screen"><div class="spinner"></div>Cargando…</div>

  <Login v-else-if="!session" />

  <template v-else>
    <div v-if="!store.ready" class="loading-screen"><div class="spinner"></div>Cargando datos…</div>
    <div v-else class="app">
      <Sidebar />
      <main>
        <component :is="viewComp" />
      </main>
    </div>

    <ProductForm v-if="ui.modal === 'product'" />
    <ProductDetail v-if="ui.modal === 'detail'" />
    <ClientForm v-if="ui.modal === 'client'" />
    <ClientHistory v-if="ui.modal === 'clienthist'" />
    <Receipt v-if="ui.modal === 'receipt'" />
    <VoidSale v-if="ui.modal === 'void'" />
    <Settings v-if="ui.modal === 'settings'" />
  </template>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from './supabase'
import { store, loadAll } from './store'
import { ui } from './ui'

import Login from './components/Login.vue'
import Sidebar from './components/Sidebar.vue'
import Dashboard from './components/Dashboard.vue'
import Sale from './components/Sale.vue'
import Products from './components/Products.vue'
import Clients from './components/Clients.vue'
import Sales from './components/Sales.vue'
import ProductForm from './components/ProductForm.vue'
import ProductDetail from './components/ProductDetail.vue'
import ClientForm from './components/ClientForm.vue'
import ClientHistory from './components/ClientHistory.vue'
import Receipt from './components/Receipt.vue'
import VoidSale from './components/VoidSale.vue'
import Settings from './components/Settings.vue'

const session = ref(null)
const authReady = ref(false)

const views = { dash: Dashboard, sale: Sale, products: Products, clients: Clients, sales: Sales }
const viewComp = computed(() => views[ui.view] || Dashboard)

onMounted(async () => {
  const { data } = await supabase.auth.getSession()
  session.value = data.session
  authReady.value = true
  if (session.value) loadAll()

  supabase.auth.onAuthStateChange((_event, s) => {
    session.value = s
    if (s && !store.ready) loadAll()
  })
})
</script>
