export default defineEventHandler(async (event) => {
  // Récupération de l'ID du film depuis les paramètres de l'URL (ex: http://localhost:3000/api/movies/123)
  const id = getRouterParam(event, "id");
  const query = getQuery(event)

  // Récupère la langue envoyée par le front, par défaut 'en-US'
  const lang = query.lang ? String(query.lang) : 'en-US'
  // Utilisation de la configuration runtime Nuxt ou secours sur process.env
  const config = useRuntimeConfig();
  const token =
    config.tmdbReadAccessToken || process.env.TMDB_READ_ACCESS_TOKEN;

  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: "ID du film manquant",
    });
  }

  try {
    const data = await $fetch(
      `https://api.themoviedb.org/3/movie/${id}?append_to_response=watch/providers&language=${lang}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          accept: "application/json",
        },
      },
    );
    return data;
  } catch (error) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération du film ${id} depuis TMDB`,
    });
  }
});
