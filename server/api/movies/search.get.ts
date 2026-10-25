export default defineEventHandler(async (event) => {
  // Récupération des paramètres de requête dans l'URL (search?query=Test)
  const queryParams = getQuery(event)
  const query = queryParams.query as string

  // Récupère la langue envoyée par le front, par défaut 'en-US'
  const lang = queryParams.lang ? String(queryParams.lang) : 'en-US'
  const page = queryParams.page ? Number(queryParams.page) : 1

  if (!query) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Le paramètre de recherche "query" est obligatoire'
    })
  }

  try {
    return await tmdbFetch('/search/movie', { query, language: lang, page })
  } catch (error: any) {
    throw createError({
      statusCode: error?.response?.status || 500,
      statusMessage: `Erreur lors de la recherche TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})
