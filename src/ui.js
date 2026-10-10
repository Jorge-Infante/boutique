import { reactive } from 'vue'

// Estado de la interfaz: vista activa y modal abierto
export const ui = reactive({
  view: 'dash',        // dash | sale | products | clients | sales
  modal: null,         // product | detail | client | receipt | settings | null
  modalData: null,     // payload del modal (producto, cliente, id de venta, etc.)
})

export function go(view) {
  ui.view = view
}

export function openModal(name, data = null) {
  ui.modal = name
  ui.modalData = data
}

export function closeModal() {
  ui.modal = null
  ui.modalData = null
}
