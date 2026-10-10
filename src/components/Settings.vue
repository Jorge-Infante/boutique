<template>
  <Modal @close="closeModal">
    <div class="modal-head"><h3>Logo y nombre</h3><button class="x" @click="closeModal">×</button></div>
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
import Modal from './Modal.vue'

const name = ref(store.settings.business_name || '')
const logo = ref(store.settings.logo_url || '')
const busy = ref(false)
const fileInput = ref(null)

function pick() { fileInput.value.value = ''; fileInput.value.click() }
async function onFile(e) {
  const f = e.target.files[0]
  if (!f) return
  const d = await resizeImage(f, 400)
  if (d) logo.value = d
}
async function save() {
  busy.value = true
  try {
    await saveSettings({ business_name: name.value.trim() || 'Mi Boutique', logo_url: logo.value })
    closeModal()
  } catch (e) {
    alert('No se pudo guardar: ' + (e.message || e))
  } finally {
    busy.value = false
  }
}
</script>
