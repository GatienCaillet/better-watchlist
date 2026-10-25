export default defineI18nConfig(() => ({
  legacy: false,
  messages: {
    en: {
      auth: { login: 'Log in', loggingIn: 'Logging in...', loginTitle: 'Welcome back', loginSubtitle: 'Log in to find your watchlist and your friends.', email: 'Email', password: 'Password', invalidCredentials: 'Wrong email or password. Check them and try again.', emailNotConfirmed: 'Your email is not confirmed yet: click the link we sent you.' },
      home: { title: 'Find what to watch tonight.', tagline: 'Search a movie, see where it is streaming, and soon share your reviews with your friends.', trending: 'Trending this week', trendingError: 'Trending movies are unavailable right now.' },
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
      auth: { login: 'Connexion', loggingIn: 'Connexion...', loginTitle: 'Content de te revoir', loginSubtitle: 'Connecte-toi pour retrouver ta watchlist et tes amis.', email: 'E-mail', password: 'Mot de passe', invalidCredentials: 'E-mail ou mot de passe incorrect. Vérifie-les et réessaie.', emailNotConfirmed: "Ton e-mail n'est pas encore confirmé : clique sur le lien qu'on t'a envoyé." },
      home: { title: 'Trouve quoi regarder ce soir.', tagline: 'Cherche un film, regarde où il est disponible en streaming, et bientôt partage tes critiques avec tes amis.', trending: 'Tendances de la semaine', trendingError: 'Les tendances sont indisponibles pour le moment.' },
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
      auth: { login: 'Iniciar sesión', loggingIn: 'Iniciando sesión...', loginTitle: 'Bienvenido de nuevo', loginSubtitle: 'Inicia sesión para recuperar tu lista y a tus amigos.', email: 'Correo electrónico', password: 'Contraseña', invalidCredentials: 'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.', emailNotConfirmed: 'Tu correo aún no está confirmado: haz clic en el enlace que te enviamos.' },
      home: { title: 'Encuentra qué ver esta noche.', tagline: 'Busca una película, mira dónde está en streaming y pronto comparte tus reseñas con tus amigos.', trending: 'Tendencias de la semana', trendingError: 'Las tendencias no están disponibles por ahora.' },
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