// Utilisateur connecté + son profil et ses plateformes (partagés dans toute l'app via useState)
export const useCurrentUser = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const profile = useState<any>('current_profile', () => null)
  const platforms = useState<number[]>('current_platforms', () => [])

  // useSupabaseUser renvoie les claims du JWT : l'id est dans "sub"
  const userId = computed(() => (user.value?.sub as string) || null)

  const loadProfile = async () => {
    if (!userId.value) {
      profile.value = null
      platforms.value = []
      return
    }

    const [{ data, error }, { data: platformRows }] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', userId.value).maybeSingle(),
      supabase.from('user_platforms').select('provider_id').eq('user_id', userId.value)
    ])

    if (error) console.error('Erreur lors du chargement du profil :', error)
    profile.value = data
    platforms.value = (platformRows || []).map((p: any) => p.provider_id)
  }

  return { user, userId, profile, platforms, loadProfile }
}
