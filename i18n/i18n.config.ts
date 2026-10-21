export default defineI18nConfig(() => ({
  legacy: false,
  messages: {
    en: {
      watchlist: 'Watchlist',
      rate: 'Rate / Log',
      streaming: 'Streaming on',
      originalTitle: 'Original title',
      synopsis: 'Synopsis',
      noOverview: 'No synopsis available in this language.'
    },
    fr: {
      watchlist: 'Watchlist',
      rate: 'Noter / Logger',
      streaming: 'En streaming',
      originalTitle: 'Titre original',
      synopsis: 'Synopsis',
      noOverview: 'Aucun synopsis disponible dans cette langue.'
    },
    es: {
      watchlist: 'Lista de seguimiento',
      rate: 'Calificar / Registrar',
      streaming: 'En streaming',
      originalTitle: 'Título original',
      synopsis: 'Sinopsis',
      noOverview: 'No hay sinopsis disponible en este idioma.'
    }
  }
}))