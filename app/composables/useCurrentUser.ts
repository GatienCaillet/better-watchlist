// Utilisateur connecté + son profil (partagé dans toute l'app via useState)
export const useCurrentUser = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const profile = useState<any>('current_profile', () => null)

  // useSupabaseUser renvoie les claims du JWT : l'id est dans "sub"
  const userId = computed(() => (user.value?.sub as string) || null)

  const loadProfile = async () => {
    if (!userId.value) {
      profile.value = null
      return
    }

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId.value)
      .maybeSingle()

    if (error) console.error('Erreur lors du chargement du profil :', error)
    profile.value = data
  }

  return { user, userId, profile, loadProfile }
}
