import { createClient, type SupabaseClient } from '@supabase/supabase-js'

let serviceClient: SupabaseClient | null = null

// Client service_role utilisable hors d'une requête HTTP (Background Job d'import).
// Il contourne la RLS : à n'utiliser que côté serveur, pour des opérations contrôlées.
export const useServiceClient = () => {
  if (!serviceClient) {
    const config = useRuntimeConfig()
    const key = config.supabase.secretKey || config.supabase.serviceKey

    if (!key) {
      throw new Error('Clé service Supabase manquante (SUPABASE_SERVICE_KEY)')
    }

    serviceClient = createClient(config.public.supabase.url, key, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false }
    })
  }
  return serviceClient
}
