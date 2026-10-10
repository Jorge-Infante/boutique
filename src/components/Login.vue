<template>
  <div class="login-wrap">
    <form class="login-card" @submit.prevent="submit">
      <div class="login-logo">B</div>
      <h1>Iniciar sesión</h1>
      <p>Ingresa para administrar tu inventario y ventas.</p>

      <div v-if="!isConfigured" class="login-err">
        Falta conectar Supabase. Crea el archivo <b>.env.local</b> con tus llaves y reinicia <code>npm run dev</code>.
      </div>
      <div v-if="err" class="login-err">{{ err }}</div>

      <div class="field">
        <label>Correo</label>
        <input v-model="email" type="email" autocomplete="username" placeholder="tucorreo@ejemplo.com" required />
      </div>
      <div class="field">
        <label>Contraseña</label>
        <input v-model="password" type="password" autocomplete="current-password" placeholder="••••••••" required />
      </div>
      <button class="btn primary block" type="submit" :disabled="busy">
        {{ busy ? 'Entrando…' : 'Entrar' }}
      </button>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase, isConfigured } from '../supabase'

const email = ref('')
const password = ref('')
const err = ref('')
const busy = ref(false)

async function submit() {
  busy.value = true
  err.value = ''
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value.trim(),
    password: password.value,
  })
  if (error) {
    err.value = /invalid login credentials/i.test(error.message)
      ? 'Correo o contraseña incorrectos.'
      : error.message
  }
  busy.value = false
}
</script>
