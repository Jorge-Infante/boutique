<template>
  <div class="overlay" @mousedown.self="emit('close')">
    <div :class="['modal', klass]"><slot /></div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'

defineProps({ klass: { type: String, default: '' } })
const emit = defineEmits(['close'])

function onKey(e) { if (e.key === 'Escape') emit('close') }
onMounted(() => document.addEventListener('keydown', onKey))
onUnmounted(() => document.removeEventListener('keydown', onKey))
</script>
