// Catalogue de films filtrable (page Films) : décennie, genre, plateforme et tri, via /discover de TMDB
const SORTS: Record<string, Record<string, any>> = {
  popularity: { sort_by: 'popularity.desc' },
  // Sans minimum de votes, les films notés 10/10 par 2 personnes passeraient devant
  rating: { sort_by: 'vote_average.desc', 'vote_count.gte': 300 },
  recent: { sort_by: 'primary_release_date.desc' }
}

export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const lang = query.lang ? String(query.lang) : 'en-US'
  const sort = SORTS[String(query.sort)] ? String(query.sort) : 'popularity'
  const decade = query.decade ? Number(query.decade) : null
  const genre = query.genre ? Number(query.genre) : null
  const provider = query.provider ? Number(query.provider) : null
  const region = query.region ? String(query.region).toUpperCase() : 'US'

  if (!/^[A-Z]{2}$/.test(region)) {
    throw createError({ statusCode: 400, statusMessage: 'Code pays invalide' })
  }
  if ([decade, genre, provider].some(value => value !== null && !Number.isInteger(value))) {
    throw createError({ statusCode: 400, statusMessage: 'Filtre invalide' })
  }

  const today = new Date().toISOString().slice(0, 10)
  const params: Record<string, any> = {
    language: lang,
    include_adult: false,
    ...SORTS[sort],
    // Pas de films encore à venir dans "les plus récents"
    ...(sort === 'recent' ? { 'primary_release_date.lte': today } : {})
  }

  if (decade) {
    params['primary_release_date.gte'] = `${decade}-01-01`
    params['primary_release_date.lte'] = sort === 'recent' && decade + 9 >= Number(today.slice(0, 4))
      ? today
      : `${decade + 9}-12-31`
  }
  if (genre) params.with_genres = genre
  if (provider) {
    // Disponible en abonnement sur cette plateforme dans le pays de l'utilisateur
    params.with_watch_providers = provider
    params.watch_region = region
    params.with_watch_monetization_types = 'flatrate'
  }

  try {
    const data = await tmdbFetch('/discover/movie', params)

    // On ne renvoie que ce dont la grille a besoin
    return (data.results || [])
      .filter((m: any) => m.poster_path)
      .map((m: any) => ({
        id: m.id,
        title: m.title,
        poster_path: m.poster_path,
        release_date: m.release_date,
        vote_average: m.vote_average
      }))
  } catch (error: any) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération des films TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})
