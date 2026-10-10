<template>
  <Modal @close="closeModal">
    <div class="modal-head"><h3>{{ editing ? 'Editar cliente' : 'Nuevo cliente' }}</h3>
      <button class="x" @click="closeModal">×</button></div>
    <div class="modal-body">
      <div class="field"><label>Nombre</label><input v-model="form.name" placeholder="Ej: María López" /></div>
      <div class="field"><label>Teléfono / WhatsApp</label><input v-model="form.phone" placeholder="300 123 4567" /></div>
      <div class="field"><label>Nota (opcional)</label><input v-model="form.note" placeholder="Prefiere talla M, etc." /></div>
    </div>
    <div class="modal-foot">
      <button class="btn" @click="closeModal">Cancelar</button>
      <button class="btn primary" :disabled="busy" @click="save">{{ busy ? 'Guardando…' : 'Guardar' }}</button>
    </div>
  </Modal>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { ui, closeModal } from '../ui'
import { saveClient } from '../store'
import { saleState } from '../sale'
import Modal from './Modal.vue'

const d = ui.modalData
const editing = !!(d && d.id)
const fromSale = !!(d && d.fromSale)

const form = reactive({
  id: editing ? d.id : null,
  name: editing ? d.name : '',
  phone: editing ? d.phone : '',
  note: editing ? d.note : '',
})
const busy = ref(false)

async function save() {
  if (!form.name.trim()) return alert('Escribe un nombre.')
  busy.value = true
  try {
    const saved = await saveClient({ id: form.id, name: form.name.trim(), phone: form.phone, note: form.note })
    if (fromSale) saleState.clientName = saved.name
    closeModal()
  } catch (e) {
    alert('No se pudo guardar: ' + (e.message || e))
  } finally {
    busy.value = false
  }
}
</script>
