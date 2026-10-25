export default defineI18nConfig(() => ({
  legacy: false,
  messages: {
    en: {
      settings: { title: 'Settings', subtitle: 'Your public profile.', bio: 'Bio', bioPlaceholder: 'Your favorite genres, directors, guilty pleasures...', save: 'Save changes', discard: 'Discard changes', saved: 'Profile saved.', error: 'The profile could not be saved. Please try again.', region: 'Country', regionHelp: 'Used to show streaming availability.', platforms: 'My streaming platforms', platformsHelp: 'Select the services you subscribe to in {region}. Change the country above and save to see other platforms.' },
      auth: { login: 'Log in', loggingIn: 'Logging in...', loginTitle: 'Welcome back', loginSubtitle: 'Log in to find your watchlist and your friends.', email: 'Email', password: 'Password', invalidCredentials: 'Wrong email or password. Check them and try again.', emailNotConfirmed: 'Your email is not confirmed yet: click the link we sent you.', signup: 'Sign up', signingUp: 'Creating your account...', signupTitle: 'Create your account', signupSubtitle: 'Free, and ready in less than a minute.', username: 'Username', usernameHelp: '3 to 30 characters: letters, numbers, dots and underscores.', usernameInvalid: 'Use 3 to 30 characters: letters, numbers, dots and underscores.', usernameTaken: 'This username is already taken, try another one.', emailInvalid: 'Enter a valid email address.', passwordHelp: 'At least 8 characters.', rateLimited: 'Too many sign-ups in a short time. Please wait a few minutes and try again.', checkEmail: 'Almost done! Check {email} and click the link to confirm your account.', hasAccount: 'Already have an account?', noAccount: 'No account yet?' },
      home: { title: 'Find what to watch tonight.', tagline: 'Search a movie, see where it is streaming, and soon share your reviews with your friends.', trending: 'Trending this week', trendingError: 'Trending movies are unavailable right now.' },
      nav: { label: 'Main navigation', searchPlaceholder: 'Search for a movie...', language: 'Change language', account: 'My account', signedInAs: 'Signed in as', logout: 'Log out', settings: 'Settings' },
      watchlist: 'Watchlist',
      rate: 'Rate / Log',
      streaming: 'Streaming on',
      youHaveIt: 'you have it',
      notStreaming: 'Not available on subscription in this country.',
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
      settings: { title: 'Paramètres', subtitle: 'Ton profil public.', bio: 'Bio', bioPlaceholder: 'Tes genres préférés, tes réalisateurs, tes plaisirs coupables...', save: 'Enregistrer', discard: 'Annuler les modifications', saved: 'Profil enregistré.', error: "Le profil n'a pas pu être enregistré. Réessaie.", region: 'Pays', regionHelp: 'Sert à afficher la disponibilité en streaming.', platforms: 'Mes plateformes de streaming', platformsHelp: 'Sélectionne les services auxquels tu es abonné en {region}. Change le pays ci-dessus et enregistre pour voir les autres plateformes.' },
      auth: { login: 'Connexion', loggingIn: 'Connexion...', loginTitle: 'Content de te revoir', loginSubtitle: 'Connecte-toi pour retrouver ta watchlist et tes amis.', email: 'E-mail', password: 'Mot de passe', invalidCredentials: 'E-mail ou mot de passe incorrect. Vérifie-les et réessaie.', emailNotConfirmed: "Ton e-mail n'est pas encore confirmé : clique sur le lien qu'on t'a envoyé.", signup: 'Inscription', signingUp: 'Création du compte...', signupTitle: 'Créer ton compte', signupSubtitle: "Gratuit, et prêt en moins d'une minute.", username: 'Pseudo', usernameHelp: '3 à 30 caractères : lettres, chiffres, points et underscores.', usernameInvalid: 'Utilise 3 à 30 caractères : lettres, chiffres, points et underscores.', usernameTaken: 'Ce pseudo est déjà pris, essaie-en un autre.', emailInvalid: 'Saisis une adresse e-mail valide.', passwordHelp: '8 caractères minimum.', rateLimited: "Trop d'inscriptions en peu de temps. Patiente quelques minutes puis réessaie.", checkEmail: 'Presque fini ! Va voir ta boîte {email} et clique sur le lien pour confirmer ton compte.', hasAccount: 'Déjà un compte ?', noAccount: 'Pas encore de compte ?' },
      home: { title: 'Trouve quoi regarder ce soir.', tagline: 'Cherche un film, regarde où il est disponible en streaming, et bientôt partage tes critiques avec tes amis.', trending: 'Tendances de la semaine', trendingError: 'Les tendances sont indisponibles pour le moment.' },
      nav: { label: 'Navigation principale', searchPlaceholder: 'Rechercher un film...', language: 'Changer de langue', account: 'Mon compte', signedInAs: 'Connecté en tant que', logout: 'Se déconnecter', settings: 'Paramètres' },
      watchlist: 'Watchlist',
      rate: 'Noter / Logger',
      streaming: 'En streaming',
      youHaveIt: "tu l'as",
      notStreaming: 'Pas disponible en abonnement dans ce pays.',
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
      settings: { title: 'Ajustes', subtitle: 'Tu perfil público.', bio: 'Biografía', bioPlaceholder: 'Tus géneros favoritos, directores, placeres culpables...', save: 'Guardar cambios', discard: 'Descartar cambios', saved: 'Perfil guardado.', error: 'No se pudo guardar el perfil. Inténtalo de nuevo.', region: 'País', regionHelp: 'Se usa para mostrar la disponibilidad en streaming.', platforms: 'Mis plataformas de streaming', platformsHelp: 'Selecciona los servicios a los que estás suscrito en {region}. Cambia el país arriba y guarda para ver otras plataformas.' },
      auth: { login: 'Iniciar sesión', loggingIn: 'Iniciando sesión...', loginTitle: 'Bienvenido de nuevo', loginSubtitle: 'Inicia sesión para recuperar tu lista y a tus amigos.', email: 'Correo electrónico', password: 'Contraseña', invalidCredentials: 'Correo o contraseña incorrectos. Revísalos e inténtalo de nuevo.', emailNotConfirmed: 'Tu correo aún no está confirmado: haz clic en el enlace que te enviamos.', signup: 'Registrarse', signingUp: 'Creando tu cuenta...', signupTitle: 'Crea tu cuenta', signupSubtitle: 'Gratis, y lista en menos de un minuto.', username: 'Nombre de usuario', usernameHelp: 'De 3 a 30 caracteres: letras, números, puntos y guiones bajos.', usernameInvalid: 'Usa de 3 a 30 caracteres: letras, números, puntos y guiones bajos.', usernameTaken: 'Este nombre de usuario ya está en uso, prueba otro.', emailInvalid: 'Introduce un correo válido.', passwordHelp: 'Mínimo 8 caracteres.', rateLimited: 'Demasiados registros en poco tiempo. Espera unos minutos e inténtalo de nuevo.', checkEmail: '¡Casi listo! Revisa {email} y haz clic en el enlace para confirmar tu cuenta.', hasAccount: '¿Ya tienes cuenta?', noAccount: '¿Aún no tienes cuenta?' },
      home: { title: 'Encuentra qué ver esta noche.', tagline: 'Busca una película, mira dónde está en streaming y pronto comparte tus reseñas con tus amigos.', trending: 'Tendencias de la semana', trendingError: 'Las tendencias no están disponibles por ahora.' },
      nav: { label: 'Navegación principal', searchPlaceholder: 'Busca una película...', language: 'Cambiar idioma', account: 'Mi cuenta', signedInAs: 'Sesión iniciada como', logout: 'Cerrar sesión', settings: 'Ajustes' },
      watchlist: 'Lista de seguimiento',
      rate: 'Calificar / Registrar',
      streaming: 'En streaming',
      youHaveIt: 'la tienes',
      notStreaming: 'No disponible por suscripción en este país.',
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