<template>
  <!-- Catálogo público: sin sesión -->
  <PublicCatalog v-if="isCatalog" />

  <template v-else>
    <div v-if="!authReady" class="loading-screen"><div class="spinner"></div>Cargando…</div>

    <Login v-else-if="!session" :order-pending="!!pendingOrder" />

    <template v-else>
      <div v-if="!store.ready" class="loading-screen"><div class="spinner"></div>Cargando datos…</div>
      <div v-else class="app">
        <Sidebar />
        <main>
          <component :is="viewComp" />
        </main>
      </div>

      <ProductForm v-if="ui.modal === 'product'" />
      <ProductDetail v-if="ui.modal === 'detail'" :product="ui.modalData"
        :avail="v => availForVariant(ui.modalData, v)" @add="addFromDetail" @close="closeModal" />
      <ClientForm v-if="ui.modal === 'client'" />
      <ClientHistory v-if="ui.modal === 'clienthist'" />
      <Receipt v-if="ui.modal === 'receipt'" />
      <VoidSale v-if="ui.modal === 'void'" />
      <Settings v-if="ui.modal === 'settings'" />
    </template>
  </template>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from './supabase'
import { store, loadAll } from './store'
import { ui, go, closeModal } from './ui'
import { availForVariant, addToCart, loadOrder } from './sale'
import { isCatalogPath, isOrderPath, readOrder } from './order'

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
import PublicCatalog from './components/PublicCatalog.vue'

const session = ref(null)
const authReady = ref(false)

// /catalogo es público; /pedido?c=… trae un pedido del catálogo para cargarlo en una venta
const isCatalog = isCatalogPath()
const pendingOrder = ref(isCatalog ? null : readOrder())

const views = { dash: Dashboard, sale: Sale, products: Products, clients: Clients, sales: Sales }
const viewComp = computed(() => views[ui.view] || Dashboard)

function addFromDetail(v, qty) {
  addToCart(ui.modalData, v, qty)
  closeModal()
  go('sale')
}

// Con sesión y datos listos, el pedido del enlace pasa a Nueva venta
watch(() => store.ready, ready => {
  if (!ready) return
  if (pendingOrder.value) {
    loadOrder(pendingOrder.value, store.products, store.clients)
    pendingOrder.value = null
    go('sale')
  }
  if (isOrderPath()) history.replaceState(null, '', '/')
})

watch(() => store.settings.business_name, name => {
  if (!isCatalog) document.title = `${name || 'Mi Boutique'} · Inventario y Ventas`
}, { immediate: true })

onMounted(async () => {
  if (isCatalog) return

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
