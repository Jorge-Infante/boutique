import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

export const isConfigured = Boolean(url && key)

if (!isConfigured) {
  console.warn('[Boutique] Falta configurar VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY en .env.local')
}

export const supabase = createClient(url || 'http://localhost', key || 'anon')
