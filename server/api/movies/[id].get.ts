import { serverSupabaseServiceRole } from "#supabase/server";

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
    const tmdbData: any = await $fetch(
      `https://api.themoviedb.org/3/movie/${id}?append_to_response=watch/providers&language=${lang}`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          accept: "application/json",
        },
      },
    );

    // On utilise le ServiceRole car le serveur doit pouvoir écrire dans la table cache librement
    const supabase = await serverSupabaseServiceRole(event);
    
    const releaseYear = tmdbData.release_date 
      ? parseInt(tmdbData.release_date.substring(0, 4)) 
      : null;

    const shortLang = lang.substring(0, 2); // Transforme "en-US" en "en"

    // On récupère le film s'il existe déjà pour ne pas écraser les autres traductions
    const { data: existingMovie } = await supabase
      .from('movie_cache')
      .select('localized_titles')
      .eq('id', tmdbData.id)
      .single();

    const localizedTitles = existingMovie?.localized_titles || {};
    localizedTitles[shortLang] = tmdbData.title; // Ajoute le titre dans la langue en cours

    // On insère ou on met à jour la ligne
    await supabase.from('movie_cache').upsert({
      id: tmdbData.id,
      original_title: tmdbData.original_title,
      localized_titles: localizedTitles,
      poster_path: tmdbData.poster_path,
      release_year: releaseYear
    });

    // On retourne l'objet complet TMDB au front-end pour l'affichage de la page
    return tmdbData;

  } catch (error) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération du film ${id} depuis TMDB`,
    });
  } 
});
