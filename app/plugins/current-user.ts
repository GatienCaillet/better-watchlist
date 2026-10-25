// Charge le profil de l'utilisateur connecté avant le premier rendu,
// pour que le serveur et le navigateur affichent la même navbar (pas d'erreur d'hydratation)
export default defineNuxtPlugin(async () => {
  const { userId, profile, loadProfile } = useCurrentUser()

  if (userId.value && !profile.value) {
    await loadProfile()
  }
})
