const TMDB_BASE = 'https://api.themoviedb.org/3'

// Appel brut à l'API TMDB (le token ne quitte jamais le serveur)
const rawTmdbFetch = async (path: string, params: Record<string, any> = {}) => {
  const config = useRuntimeConfig()
  const token = config.tmdbReadAccessToken || process.env.TMDB_READ_ACCESS_TOKEN

  return await $fetch<any>(`${TMDB_BASE}${path}`, {
    params,
    headers: {
      Authorization: `Bearer ${token}`,
      accept: 'application/json'
    }
  })
}

// Version mise en cache par Nitro : les mêmes requêtes ne repartent pas vers TMDB
// pendant 6h (évite la latence et le dépassement des quotas)
export const tmdbFetch = defineCachedFunction(rawTmdbFetch, {
  name: 'tmdb',
  maxAge: 60 * 60 * 6,
  // Attention : le stockage Nitro coupe les clés au premier "?", d'où le séparateur ":" et l'encodage
  getKey: (path: string, params: Record<string, any> = {}) => {
    const query = Object.keys(params).sort().map(k => `${k}=${encodeURIComponent(params[k])}`).join('&')
    return `${path}:${query}`
  }
})

// Ajoute ou met à jour un film dans le movie_cache sans écraser les autres traductions
export const upsertMovieCache = async (tmdbMovie: any, lang: string) => {
  // On utilise le ServiceRole car le serveur doit pouvoir écrire dans la table cache librement
  const supabase = useServiceClient()
  const shortLang = lang.substring(0, 2) // Transforme "en-US" en "en"

  const { data: existingMovie } = await supabase
    .from('movie_cache')
    .select('localized_titles')
    .eq('id', tmdbMovie.id)
    .maybeSingle()

  const localizedTitles = existingMovie?.localized_titles || {}
  localizedTitles[shortLang] = tmdbMovie.title

  const { error } = await supabase.from('movie_cache').upsert({
    id: tmdbMovie.id,
    original_title: tmdbMovie.original_title,
    localized_titles: localizedTitles,
    poster_path: tmdbMovie.poster_path,
    release_year: tmdbMovie.release_date ? parseInt(tmdbMovie.release_date.substring(0, 4)) : null
  })

  if (error) throw error
}
