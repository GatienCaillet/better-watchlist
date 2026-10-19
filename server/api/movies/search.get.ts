export default defineEventHandler(async (event) => {
  // Récupération des paramètres de requête dans l'URL (ex: ?query=batman)
  const queryParams = getQuery(event)
  const query = queryParams.query as string

  // Utilisation de la configuration runtime Nuxt ou secours sur process.env
  const config = useRuntimeConfig()
  const token = config.tmdbReadAccessToken || process.env.TMDB_READ_ACCESS_TOKEN

  if (!query) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Le paramètre de recherche "query" est obligatoire'
    })
  }

  try {
    const data = await $fetch(`https://api.themoviedb.org/3/search/movie?query=${encodeURIComponent(query)}&language=fr-FR&page=1`, {
      headers: {
        Authorization: `Bearer ${token}`,
        accept: 'application/json'
      }
    })
    return data
  } catch (error: any) {
    throw createError({
      statusCode: error?.response?.status || 500,
      statusMessage: `Erreur lors de la recherche TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})