export const useMovies = () => {
  // Rechercher des films via notre API Nitro
  const searchMovies = async (query: string) => {
    if (!query.trim()) return null
    
    try {
      return await $fetch('/api/movies/search', {
        params: { query }
      })
    } catch (error) {
      console.error('Erreur lors de la recherche de films :', error)
      return null
    }
  }

  // Récupérer les détails d'un film (avec données VOD/JustWatch)
  const getMovieDetails = async (id: number | string) => {
    try {
      return await $fetch(`/api/movies/${id}`)
    } catch (error) {
      console.error(`Erreur lors de la récupération du film ${id} :`, error)
      return null
    }
  }

  return {
    searchMovies,
    getMovieDetails
  }
}