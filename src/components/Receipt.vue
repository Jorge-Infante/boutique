<template>
  <Modal klass="wide" @close="closeModal">
    <div class="modal-head no-print"><h3>Recibo #{{ sale ? sale.id : '' }}</h3>
      <button class="x" @click="closeModal">×</button></div>

    <div class="modal-body">
      <div id="print-area">
        <div class="receipt" v-if="sale">
          <div class="r-top">
            <img v-if="store.settings.logo_url" class="r-logo" :src="store.settings.logo_url" alt="" />
            <b>{{ store.settings.business_name || 'Mi Boutique' }}</b>
            <div style="font-size:12px;color:#666;font-family:ui-sans-serif,sans-serif">Comprobante de venta (control interno)</div>
          </div>
          <div class="r-meta"><span>Recibo <b>#{{ sale.id }}</b></span><span>{{ fdate(sale.created_at) }}</span></div>
          <div class="r-cli"><b>Cliente:</b> {{ sale.client_name || 'Mostrador' }} &nbsp;·&nbsp; <b>Pago:</b> {{ sale.payment || '—' }}</div>
          <table>
            <thead><tr><th>Prenda</th><th class="r">Cant.</th><th class="r">Precio</th><th class="r">Subtotal</th></tr></thead>
            <tbody>
              <tr v-for="(i, idx) in sale.items" :key="idx">
                <td>{{ i.name }}<template v-if="i.variant && i.variant !== 'Única'"> · {{ i.variant }}</template></td>
                <td class="r num">{{ i.qty }}</td>
                <td class="r num">{{ fmt.format(i.price) }}</td>
                <td class="r num">{{ fmt.format(i.price * i.qty) }}</td>
              </tr>
            </tbody>
          </table>
          <div class="r-sum">
            <div class="l"><span>Subtotal</span><span>{{ fmt.format(sale.subtotal) }}</span></div>
            <div v-if="sale.discount > 0" class="l"><span>Descuento</span><span>–{{ fmt.format(sale.discount) }}</span></div>
          </div>
          <div class="r-total num">Total: {{ fmt.format(sale.total) }}</div>
          <div class="r-foot">¡Gracias por tu compra!</div>
        </div>
      </div>
    </div>

    <div class="modal-foot no-print">
      <button class="btn" @click="closeModal">Cerrar</button>
      <button class="btn primary" @click="printIt">
        <svg viewBox="0 0 24 24" style="width:16px;height:16px;stroke:currentColor;stroke-width:1.9;fill:none"><path d="M6 9V2h12v7M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2M6 14h12v8H6z"/></svg>
        Imprimir / PDF
      </button>
    </div>
  </Modal>
</template>

<script setup>
import { computed } from 'vue'
import { store } from '../store'
import { ui, closeModal } from '../ui'
import { fmt, fdate } from '../utils'
import Modal from './Modal.vue'

const sale = computed(() => store.sales.find(s => s.id === ui.modalData))

function printIt() { window.print() }
</script>
