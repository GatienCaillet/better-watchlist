<template>
  <div v-if="movie" class="movie-page min-vh-100">
    <!-- Bannière / Backdrop avec effet de fondu vers le fond clair -->
    <div class="backdrop-container w-100" :style="backdropStyle" aria-hidden="true">
      <div class="backdrop-overlay w-100 h-100"></div>
    </div>

    <!-- Contenu principal -->
    <div class="container content-wrapper page-container pt-0">
      <div class="row g-4 g-lg-5">

        <!-- Colonne Gauche : Affiche et Actions -->
        <div class="col-12 col-md-4 col-lg-3">
          <div class="poster-wrapper mb-4 mx-auto">
            <img
              v-if="movie.poster_path"
              :src="posterUrl(movie.poster_path, 'w500') || ''"
              :alt="movie.title"
              class="poster-ratio shadow"
            />
            <div v-else class="poster-placeholder" role="img" :aria-label="movie.title">
              <i class="bi bi-film" aria-hidden="true"></i>
            </div>
          </div>

          <!-- Panneau d'actions -->
          <div class="card p-3 mb-4 actions-card">
            <button
              v-if="userId"
              type="button"
              class="btn w-100 mb-2"
              :class="inWatchlist ? 'btn-outline-secondary' : 'btn-primary'"
              :aria-pressed="inWatchlist"
              :disabled="watchlistLoading"
              @click="toggleWatchlist"
            >
              <span v-if="watchlistLoading" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
              <i v-else class="bi" :class="inWatchlist ? 'bi-bookmark-check-fill' : 'bi-bookmark-plus'" aria-hidden="true"></i>
              {{ inWatchlist ? $t('inWatchlist') : $t('addToWatchlist') }}
            </button>
            <!-- Visiteur : on l'invite à se connecter pour utiliser la watchlist -->
            <NuxtLinkLocale v-else to="/login" class="btn btn-primary w-100 mb-2">
              <i class="bi bi-bookmark-plus" aria-hidden="true"></i> {{ $t('addToWatchlist') }}
            </NuxtLinkLocale>
            <p v-if="watchlistError" class="small text-danger mb-2" role="alert">{{ watchlistError }}</p>
            <button type="button" class="btn btn-outline-secondary w-100">
              <i class="bi bi-star" aria-hidden="true"></i> {{ $t('rate') }}
            </button>
          </div>

          <!-- Plateformes VOD adaptées au pays -->
          <section class="vod-section" :aria-label="$t('streaming')">
            <h2 class="section-title">
              {{ $t('streaming') }} <span class="fw-normal">· {{ regionCode }}</span>
            </h2>
            <ul v-if="streamingProviders.length" class="d-flex flex-wrap gap-2 list-unstyled mb-0">
              <!-- Les plateformes de l'utilisateur passent en premier, avec une coche -->
              <li v-for="provider in streamingProviders" :key="provider.provider_id" class="position-relative">
                <img
                  :src="`https://image.tmdb.org/t/p/w92${provider.logo_path}`"
                  :alt="provider.provider_name"
                  :title="isOwned(provider) ? `${provider.provider_name} · ${$t('youHaveIt')}` : provider.provider_name"
                  class="rounded provider-logo"
                  :class="{ owned: isOwned(provider) }"
                  width="44"
                  height="44"
                />
                <i v-if="isOwned(provider)" class="bi bi-check-circle-fill owned-check" aria-hidden="true"></i>
              </li>
            </ul>
            <p v-else class="small text-muted mb-0">{{ $t('notStreaming') }}</p>
          </section>
        </div>

        <!-- Colonne Droite : Informations -->
        <div class="col-12 col-md-8 col-lg-9">
          <header class="movie-header mb-4">
            <h1 class="display-5 fw-bold mb-1">
              {{ movie.title }}
              <span v-if="releaseYear" class="text-muted fw-normal fs-3">({{ releaseYear }})</span>
            </h1>

            <p v-if="movie.original_title !== movie.title" class="text-muted fst-italic mb-3">
              {{ $t('originalTitle') }} : {{ movie.original_title }}
            </p>

            <!-- Méta-données (Note, Durée, Genres) -->
            <div class="d-flex flex-wrap align-items-center gap-3 mb-4">
              <div v-if="movie.vote_average" class="score d-flex align-items-center gap-2">
                <i class="bi bi-star-fill" aria-hidden="true"></i>
                <strong>{{ (movie.vote_average / 2).toFixed(1) }}</strong><span class="text-muted">/ 5</span>
              </div>
              <span v-if="formattedRuntime" class="text-muted">
                <i class="bi bi-clock" aria-hidden="true"></i> {{ formattedRuntime }}
              </span>
              <ul class="d-flex flex-wrap gap-2 list-unstyled mb-0">
                <li v-for="genre in movie.genres" :key="genre.id" class="badge rounded-pill genre-badge">{{ genre.name }}</li>
              </ul>
            </div>

            <!-- Slogan (Tagline) du film s'il existe -->
            <p v-if="movie.tagline" class="tagline fst-italic mb-4">« {{ movie.tagline }} »</p>
          </header>

          <!-- Synopsis -->
          <section class="overview-section" aria-labelledby="synopsis-title">
            <h2 id="synopsis-title" class="section-title">{{ $t('synopsis') }}</h2>
            <p class="fs-6 lh-lg overview">
              {{ movie.overview || $t('noOverview') }}
            </p>
          </section>
        </div>
      </div>
    </div>
  </div>

  <!-- Chargement pendant la requête API -->
  <div v-else-if="pending" class="min-vh-100 d-flex align-items-center justify-content-center">
    <div class="spinner-border text-secondary" role="status"></div>
  </div>

  <!-- L'API n'a rien renvoyé : mauvais ID ou TMDB indisponible -->
  <div v-else class="container page-container text-center">
    <i class="bi bi-film fs-1 text-muted" aria-hidden="true"></i>
    <h1 class="h4 mt-3">{{ $t('movieNotFound') }}</h1>
    <NuxtLinkLocale to="/search" class="btn btn-primary mt-2">
      <i class="bi bi-search" aria-hidden="true"></i> {{ $t('search.title') }}
    </NuxtLinkLocale>
  </div>
</template>

<script lang="ts" setup>
const route = useRoute()
const supabase = useSupabaseClient()
const { t, locale } = useI18n()
const { getMovieDetails } = useMovies()
const { userId, profile, platforms } = useCurrentUser()

const movie = ref<any>(null)
const pending = ref(true)

useHead({ title: () => movie.value?.title || '' })

// Charger les données du film
const fetchMovieData = async () => {
  pending.value = true
  movie.value = await getMovieDetails(route.params.id as string)
  pending.value = false
}

// Watchlist personnelle
const inWatchlist = ref(false)
const watchlistLoading = ref(false)
const watchlistError = ref('')

const checkWatchlist = async () => {
  if (!userId.value) return
  const { data } = await supabase
    .from('personal_watchlist')
    .select('movie_id')
    .eq('user_id', userId.value)
    .eq('movie_id', Number(route.params.id))
    .maybeSingle()
  inWatchlist.value = !!data
}

// Le film est déjà dans movie_cache (la route /api/movies/[id] l'y ajoute),
// donc la clé étrangère de personal_watchlist est respectée
const toggleWatchlist = async () => {
  watchlistLoading.value = true
  watchlistError.value = ''

  const { error } = inWatchlist.value
    ? await supabase.from('personal_watchlist').delete().eq('user_id', userId.value).eq('movie_id', movie.value.id)
    : await supabase.from('personal_watchlist').insert({ user_id: userId.value, movie_id: movie.value.id })

  watchlistLoading.value = false

  if (error) {
    console.error('Erreur watchlist :', error)
    watchlistError.value = t('watchlistError')
    return
  }
  inWatchlist.value = !inWatchlist.value
}

onMounted(async () => {
  await fetchMovieData()
  await checkWatchlist()
})

// Recharger les données si la langue change dynamiquement
watch(locale, fetchMovieData)

// Extraire l'année
const releaseYear = computed(() => {
  return movie.value?.release_date ? movie.value.release_date.slice(0, 4) : ''
})

// Formatage heures / minutes
const formattedRuntime = computed(() => {
  if (!movie.value?.runtime) return null
  const hours = Math.floor(movie.value.runtime / 60)
  const minutes = movie.value.runtime % 60
  return `${hours}h ${minutes}m`
})

// Pays du profil si connecté, sinon pays associé à la langue active
// (la "region" de la locale anglaise vaut EN, qui n'est pas un code pays TMDB)
const regionCode = computed(() => profile.value?.watch_region || defaultRegion(locale.value))

const isOwned = (provider: any) => platforms.value.includes(provider.provider_id)

// Plateformes d'abonnement dans ce pays, celles de l'utilisateur en premier
const streamingProviders = computed(() => {
  const list = movie.value?.['watch/providers']?.results?.[regionCode.value]?.flatrate || []
  return [...list].sort((a: any, b: any) => Number(isOwned(b)) - Number(isOwned(a)))
})

// Style dynamique de l'image de fond
const backdropStyle = computed(() => {
  if (!movie.value?.backdrop_path) return { backgroundColor: 'var(--bw-placeholder)' }
  return {
    backgroundImage: `url('https://image.tmdb.org/t/p/original${movie.value.backdrop_path}')`,
    backgroundSize: 'cover',
    backgroundPosition: 'center 20%',
    backgroundRepeat: 'no-repeat'
  }
})
</script>

<style lang="scss" scoped>
.backdrop-container {
  height: 460px;
  position: relative;
  mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) 45%, rgba(0, 0, 0, 0) 100%);
  -webkit-mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 1) 45%, rgba(0, 0, 0, 0) 100%);
}

// Fondu vers le gris clair pour que le titre reste lisible par-dessus l'image
.backdrop-overlay {
  background: linear-gradient(to bottom, rgba(243, 244, 246, 0.45) 0%, rgba(243, 244, 246, 0.92) 55%, var(--bw-bg) 100%);
}

.content-wrapper {
  margin-top: -220px;
  position: relative;
  z-index: 2;
}

@media (max-width: 767.98px) {
  .backdrop-container {
    height: 240px;
  }

  .content-wrapper {
    margin-top: -120px;
  }
}

.poster-wrapper {
  max-width: 300px;

  // Sur mobile, une affiche plus petite laisse le titre et les actions visibles sans défiler
  @media (max-width: 767.98px) {
    max-width: 170px;
  }
}

// Icône à gauche puis libellé : reste lisible même si le texte passe sur deux lignes
.actions-card .btn {
  justify-content: flex-start;
  text-align: left;
}

.score {
  background: #fff;
  border: 1px solid var(--bw-border);
  padding: 0.25rem 0.75rem;
  border-radius: 999px;

  strong {
    font-size: 1.1rem;
  }
}

.genre-badge {
  background: #fff;
  border: 1px solid var(--bw-border);
  color: #374151;
  font-weight: 500;
}

.tagline {
  color: #374151;
  font-size: 1.15rem;
}

.overview {
  color: #374151;
  max-width: 760px;
}

// Plateforme possédée par l'utilisateur : contour bleu nuit + coche
.provider-logo.owned {
  outline: 2px solid var(--bw-accent);
  outline-offset: 2px;
}

.owned-check {
  position: absolute;
  top: -7px;
  right: -7px;
  color: var(--bw-accent);
  background: var(--bw-bg);
  border-radius: 50%;
  font-size: 0.9rem;
}
</style>
