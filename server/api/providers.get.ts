// Liste des plateformes VOD disponibles dans un pays (pour le choix dans les paramètres)
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const region = query.region ? String(query.region).toUpperCase() : 'FR'
  const lang = query.lang ? String(query.lang) : 'en-US'

  if (!/^[A-Z]{2}$/.test(region)) {
    throw createError({ statusCode: 400, statusMessage: 'Code pays invalide' })
  }

  try {
    const data = await tmdbFetch('/watch/providers/movie', { watch_region: region, language: lang })

    // Triées par popularité dans le pays, on garde les plus connues
    return (data.results || [])
      .sort((a: any, b: any) => (a.display_priorities?.[region] ?? 999) - (b.display_priorities?.[region] ?? 999))
      .slice(0, 40)
      .map((p: any) => ({
        provider_id: p.provider_id,
        provider_name: p.provider_name,
        logo_path: p.logo_path
      }))
  } catch (error: any) {
    throw createError({
      statusCode: 500,
      statusMessage: `Erreur lors de la récupération des plateformes TMDB : ${error?.message || 'Échec de la requête'}`
    })
  }
})
