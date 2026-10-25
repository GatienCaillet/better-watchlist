// Protège les pages qui nécessitent d'être connecté
export default defineNuxtRouteMiddleware(() => {
  const user = useSupabaseUser()
  const localePath = useLocalePath()

  if (!user.value) {
    return navigateTo(localePath('/login'))
  }
})
