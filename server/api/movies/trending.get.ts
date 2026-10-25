// Films tendance de la semaine pour la page d'accueil (mis en cache comme les autres appels TMDB)
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const lang = query.lang ? String(query.lang) : 'en-US'

  try {
    const data = await tmdbFetch('/trending/movie/week', { language: lang })

    // On ne renvoie que ce dont la page a besoin
    return (data.results || [])
      .filter((m: any) => m.poster_path)
      .slice(0, 12)
      .map((m: any) => ({
        id: m.id,
        title: m.title,
        poster_path: m.poster_path,
        release_date: m.release_date
      }))
  } catch (error: any) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération des tendances TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})
