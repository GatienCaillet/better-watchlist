export default defineI18nConfig(() => ({
  legacy: false,
  messages: {
    en: {
      nav: { label: 'Main navigation', searchPlaceholder: 'Search for a movie...', language: 'Change language' },
      watchlist: 'Watchlist',
      rate: 'Rate / Log',
      streaming: 'Streaming on',
      originalTitle: 'Original title',
      synopsis: 'Synopsis',
      noOverview: 'No synopsis available in this language.',
      movieNotFound: 'This movie could not be found.',
      search: {
        title: 'Search',
        placeholder: 'Search for a movie...',
        button: 'Search',
        loading: 'Searching...',
        noResults: 'No movie found. Check the spelling or try the original title.'
      }
    },
    fr: {
      nav: { label: 'Navigation principale', searchPlaceholder: 'Rechercher un film...', language: 'Changer de langue' },
      watchlist: 'Watchlist',
      rate: 'Noter / Logger',
      streaming: 'En streaming',
      originalTitle: 'Titre original',
      synopsis: 'Synopsis',
      noOverview: 'Aucun synopsis disponible dans cette langue.',
      movieNotFound: 'Ce film est introuvable.',
      search: {
        title: 'Recherche',
        placeholder: 'Rechercher un film...',
        button: 'Rechercher',
        loading: 'Recherche en cours...',
        noResults: "Aucun film trouvé. Vérifie l'orthographe ou essaie le titre original."
      }
    },
    es: {
      nav: { label: 'Navegación principal', searchPlaceholder: 'Busca una película...', language: 'Cambiar idioma' },
      watchlist: 'Lista de seguimiento',
      rate: 'Calificar / Registrar',
      streaming: 'En streaming',
      originalTitle: 'Título original',
      synopsis: 'Sinopsis',
      noOverview: 'No hay sinopsis disponible en este idioma.',
      movieNotFound: 'No se encontró esta película.',
      search: {
        title: 'Búsqueda',
        placeholder: 'Busca una película...',
        button: 'Buscar',
        loading: 'Buscando...',
        noResults: 'No se encontró ninguna película. Revisa la ortografía o prueba el título original.'
      }
    }
  }
}))