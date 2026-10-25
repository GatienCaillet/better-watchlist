export const useMovies = () => {
  const { localeProperties } = useI18n()

  // TMDB a besoin du format 'fr-FR' ou 'en-US'
  const getTmdbLang = () => {
    return localeProperties.value?.iso || 'en-US'
  }

  // Rechercher des films via notre API Nitro
  const searchMovies = async (query: string) => {
    if (!query.trim()) return null
    
    try {
      return await $fetch('/api/movies/search', {
        params: { 
          query, 
          lang: getTmdbLang() 
        }
      })
    } catch (error) {
      console.error('Erreur lors de la recherche de films :', error)
      return null
    }
  }

  // Récupérer les détails d'un film (avec données VOD/JustWatch)
  const getMovieDetails = async (id: number | string) => {
    try {
      return await $fetch(`/api/movies/${id}`, {
        params: {
          lang: getTmdbLang()
        }
      })
    } catch (error) {
      console.error(`Erreur lors de la récupération du film ${id} :`, error)
      return null
    }
  }

  // Plateformes VOD disponibles dans un pays
  const getProviders = async (region: string) => {
    try {
      return await $fetch<any[]>('/api/providers', {
        params: { region, lang: getTmdbLang() }
      })
    } catch (error) {
      console.error('Erreur lors de la récupération des plateformes :', error)
      return []
    }
  }

  return {
    searchMovies,
    getMovieDetails,
    getProviders
  }
}