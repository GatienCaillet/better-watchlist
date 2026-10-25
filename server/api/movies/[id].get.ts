export default defineEventHandler(async (event) => {
  // Récupération de l'ID du film depuis les paramètres de l'URL (ex: http://localhost:3000/api/movies/123)
  const id = getRouterParam(event, "id");
  const query = getQuery(event)

  // Récupère la langue envoyée par le front, par défaut 'en-US'
  const lang = query.lang ? String(query.lang) : 'en-US'

  if (!id || !/^\d+$/.test(id)) {
    throw createError({
      statusCode: 400,
      message: "ID du film manquant",
    });
  }

  try {
    const tmdbData = await tmdbFetch(`/movie/${id}`, {
      append_to_response: 'watch/providers',
      language: lang
    })

    // On garde une copie légère du film en base pour les listes, critiques, événements...
    try {
      await upsertMovieCache(tmdbData, lang)
    } catch (cacheError) {
      console.error("Erreur lors de l'ajout dans le movie_cache :", cacheError);
    }

    // On retourne l'objet complet TMDB au front-end pour l'affichage de la page
    return tmdbData;

  } catch (error: any) {
    // Film inexistant chez TMDB : ce n'est pas une panne, on renvoie un 404
    if (error?.response?.status === 404) {
      throw createError({
        statusCode: 404,
        message: `Le film ${id} n'existe pas sur TMDB`,
      });
    }

    console.error(`Plantage API / DB :`, error);

    throw createError({
      statusCode: 500,
      message: `Erreur lors de la récupération du film ${id} depuis TMDB`,
    });
  }
});
