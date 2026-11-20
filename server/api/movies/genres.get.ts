// Liste des genres de films TMDB dans la langue demandée (pour le filtre "Genre")
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const lang = query.lang ? String(query.lang) : 'en-US'

  try {
    const data = await tmdbFetch('/genre/movie/list', { language: lang })
    return (data.genres || []).map((g: any) => ({ id: g.id, name: g.name }))
  } catch (error: any) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération des genres TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})
