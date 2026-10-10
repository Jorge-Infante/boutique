<template>
  <Modal @close="closeModal">
    <div class="modal-head"><h3>Datos de la tienda</h3><button class="x" @click="closeModal">×</button></div>
    <div class="modal-body">
      <div class="field"><label>Logo del negocio</label>
        <div class="uploader">
          <img v-if="logo" class="pv" :src="logo" alt="" />
          <div v-else class="pv-ph">🏷️</div>
          <div class="acts">
            <button class="btn" type="button" @click="pick">{{ logo ? 'Cambiar logo' : 'Subir logo' }}</button>
            <button v-if="logo" class="btn danger" type="button" @click="logo = ''">Quitar</button>
          </div>
        </div>
        <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="onFile" />
      </div>
      <div class="field"><label>Nombre del negocio</label>
        <input v-model="name" placeholder="Mi Boutique" /></div>

      <div class="field"><label>WhatsApp de la tienda</label>
        <input v-model="whatsapp" inputmode="tel" placeholder="300 123 4567" :disabled="!hasWhatsapp" />
        <span class="cat">{{ hasWhatsapp
          ? 'Aquí te llegan los pedidos del catálogo.'
          : 'Para guardarlo, falta aplicar supabase/migrations_catalogo.sql en Supabase.' }}</span>
      </div>

      <div class="field"><label>Enlace del catálogo</label>
        <div class="copyrow">
          <input :value="catalogUrl" readonly @focus="$event.target.select()" />
          <button class="btn sm" type="button" @click="copy">{{ copied ? 'Copiado' : 'Copiar' }}</button>
        </div>
        <span class="cat">Compártelo en Instagram o WhatsApp. Solo muestra prendas con stock.</span>
      </div>
    </div>
    <div class="modal-foot">
      <button class="btn" @click="closeModal">Cancelar</button>
      <button class="btn primary" :disabled="busy" @click="save">{{ busy ? 'Guardando…' : 'Guardar' }}</button>
    </div>
  </Modal>
</template>

<script setup>
import { ref } from 'vue'
import { store, saveSettings } from '../store'
import { closeModal } from '../ui'
import { resizeImage } from '../utils'
import { CATALOG_PATH } from '../order'
import Modal from './Modal.vue'

const name = ref(store.settings.business_name || '')
const logo = ref(store.settings.logo_url || '')
const hasWhatsapp = 'whatsapp' in store.settings   // existe tras migrations_catalogo.sql
const whatsapp = ref(store.settings.whatsapp || '')
const catalogUrl = location.origin + CATALOG_PATH
const copied = ref(false)
const busy = ref(false)
const fileInput = ref(null)

function pick() { fileInput.value.value = ''; fileInput.value.click() }
async function onFile(e) {
  const f = e.target.files[0]
  if (!f) return
  const d = await resizeImage(f, 400)
  if (d) logo.value = d
}
async function copy() {
  try {
    await navigator.clipboard.writeText(catalogUrl)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch { /* sin permiso para el portapapeles: el campo se puede seleccionar a mano */ }
}
async function save() {
  busy.value = true
  try {
    await saveSettings({
      business_name: name.value.trim() || 'Mi Boutique',
      logo_url: logo.value,
      whatsapp: whatsapp.value.trim(),
    })
    closeModal()
  } catch (e) {
    alert('No se pudo guardar: ' + (e.message || e))
  } finally {
    busy.value = false
  }
}
</script>
