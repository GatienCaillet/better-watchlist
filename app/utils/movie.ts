// Helpers d'affichage partagés (auto-importés par Nuxt)

export const posterUrl = (path?: string | null, size = 'w342') => {
  return path ? `https://image.tmdb.org/t/p/${size}${path}` : null
}

// Titre d'un film du movie_cache dans la langue courante, sinon en anglais, sinon le titre original
// (les films importés n'ont souvent que le titre anglais en cache)
export const movieTitle = (movie: any, locale: string) => {
  if (!movie) return ''
  const titles = movie.localized_titles || {}
  return titles[locale.substring(0, 2)] || titles.en || movie.original_title || movie.title || ''
}

// Pays par défaut pour les plateformes VOD quand l'utilisateur n'est pas connecté
export const defaultRegion = (locale: string) => {
  const regions: Record<string, string> = { en: 'US', fr: 'FR', es: 'ES' }
  return regions[locale] || 'US'
}

export const formatDate = (date: string | Date, locale: string, withTime = false) => {
  return new Date(date).toLocaleString(locale, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {})
  })
}
