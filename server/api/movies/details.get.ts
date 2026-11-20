// Genres, note et plateformes de plusieurs films d'un coup (filtres et logos de la page Watchlist)
// Usage : /api/movies/details?ids=603,27205&region=FR&lang=fr-FR
const MAX_IDS = 100
const PARALLEL = 10

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const lang = query.lang ? String(query.lang) : 'en-US'
  const region = query.region ? String(query.region).toUpperCase() : 'US'
  const ids = String(query.ids || '').split(',').filter(Boolean).map(Number)

  if (!/^[A-Z]{2}$/.test(region)) {
    throw createError({ statusCode: 400, statusMessage: 'Code pays invalide' })
  }
  if (ids.some(id => !Number.isInteger(id) || id <= 0) || ids.length > MAX_IDS) {
    throw createError({ statusCode: 400, statusMessage: `Liste d'identifiants invalide (${MAX_IDS} maximum)` })
  }

  const fetchOne = async (id: number) => {
    try {
      // Une seule requête TMDB par film (mise en cache 6h) grâce à append_to_response
      const movie = await tmdbFetch(`/movie/${id}`, { language: lang, append_to_response: 'watch/providers' })
      const flatrate = movie['watch/providers']?.results?.[region]?.flatrate || []
      return {
        id,
        genre_ids: (movie.genres || []).map((g: any) => g.id),
        vote_average: movie.vote_average,
        release_date: movie.release_date,
        providers: flatrate.map((p: any) => ({
          provider_id: p.provider_id,
          provider_name: p.provider_name,
          logo_path: p.logo_path
        }))
      }
    } catch {
      // Un film introuvable ne doit pas faire échouer toute la watchlist
      return { id, genre_ids: [], vote_average: null, release_date: null, providers: [] }
    }
  }

  // Par paquets pour ne pas envoyer 100 requêtes simultanées à TMDB
  const results = []
  for (let i = 0; i < ids.length; i += PARALLEL) {
    results.push(...await Promise.all(ids.slice(i, i + PARALLEL).map(fetchOne)))
  }
  return results
})
