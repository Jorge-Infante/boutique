<template>
  <Modal @close="closeModal">
    <div class="modal-head"><h3>{{ form.id ? 'Editar prenda' : 'Nueva prenda' }}</h3>
      <button class="x" @click="closeModal">×</button></div>
    <div class="modal-body">
      <div class="field"><label>Fotos de la prenda</label>
        <div class="gallery-up">
          <div v-for="(src, i) in form.photos" :key="i" class="gthumb">
            <img :src="src" alt="" />
            <button class="gdel" @click="form.photos.splice(i, 1)">×</button>
          </div>
          <button class="gadd" type="button" @click="pickPhoto"><span>+</span>Foto</button>
        </div>
        <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="onFile" />
      </div>

      <div class="field"><label>Nombre</label>
        <input v-model="form.name" placeholder="Ej: Vestido largo elegante" /></div>
      <div class="row">
        <div class="field"><label>Categoría</label><input v-model="form.category" placeholder="Ej: Vestidos" /></div>
        <div class="field"><label>Precio (COP)</label><input v-model.number="form.price" type="number" min="0" placeholder="0" /></div>
      </div>

      <div class="field" style="margin-bottom:16px">
        <div class="vlabel"><label>Tallas / colores y su stock</label>
          <button class="btn sm" type="button" @click="addVar">+ Añadir</button></div>
        <div class="vhead"><span>Talla</span><span>Color (opcional)</span><span>Stock</span><span></span></div>
        <div v-for="(v, i) in form.variants" :key="i" class="vrow">
          <input v-model="v.talla" placeholder="S, M, 30…" />
          <input v-model="v.color" placeholder="Rojo…" />
          <input v-model.number="v.stock" class="num" type="number" min="0" />
          <button class="v-del" type="button" @click="delVar(i)">✕</button>
        </div>
      </div>

      <div class="field"><label>Avisar cuando una talla baje a</label>
        <input v-model.number="form.min_stock" type="number" min="0" placeholder="4" /></div>
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
import { saveProduct } from '../store'
import { resizeImage } from '../utils'
import Modal from './Modal.vue'

const src = ui.modalData
const form = reactive({
  id: src?.id || null,
  name: src?.name || '',
  category: src?.category || '',
  price: src?.price ?? '',
  min_stock: src?.min_stock ?? '',
  photos: src ? [...(src.photos || [])] : [],
  // el id se conserva para no romper ventas ni pedidos que apuntan a la variante
  variants: src ? src.variants.map(v => ({ id: v.id, talla: v.talla, color: v.color, stock: v.stock }))
                : [{ talla: '', color: '', stock: 0 }],
})
const busy = ref(false)
const fileInput = ref(null)

function pickPhoto() { fileInput.value.value = ''; fileInput.value.click() }
async function onFile(e) {
  const f = e.target.files[0]
  if (!f) return
  const d = await resizeImage(f, 800)
  if (d) form.photos.push(d)
}
function addVar() { form.variants.push({ talla: '', color: '', stock: 0 }) }
function delVar(i) {
  form.variants.splice(i, 1)
  if (!form.variants.length) form.variants.push({ talla: '', color: '', stock: 0 })
}

async function save() {
  if (!form.name.trim()) return alert('Escribe un nombre.')
  busy.value = true
  try {
    let vars = form.variants.filter(v => v.talla || v.color || v.stock > 0)
    if (!vars.length) vars = [{ talla: 'Única', color: '', stock: 0 }]
    await saveProduct({
      id: form.id, name: form.name.trim(), category: form.category.trim() || 'General',
      price: +form.price || 0, min_stock: +form.min_stock || 0, photos: form.photos, variants: vars,
    })
    closeModal()
  } catch (e) {
    alert('No se pudo guardar: ' + (e.message || e))
  } finally {
    busy.value = false
  }
}
</script>
