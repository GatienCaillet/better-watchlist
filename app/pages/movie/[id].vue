<template>
  <div v-if="movie" class="movie-page text-light min-vh-100">
    <!-- Bannière / Backdrop avec effet de fondu -->
    <div class="backdrop-container w-100" :style="backdropStyle">
      <div class="backdrop-overlay w-100 h-100"></div>
    </div>

    <!-- Contenu principal -->
    <div class="container content-wrapper pb-5">
      <div class="row g-4">
        
        <!-- Colonne Gauche : Affiche et Actions -->
        <div class="col-12 col-md-4 col-lg-3">
          <!-- Affiche -->
          <div class="poster-wrapper mb-4 shadow-lg rounded">
            <img 
              v-if="movie.poster_path"
              :src="`https://image.tmdb.org/t/p/w500${movie.poster_path}`" 
              :alt="movie.title"
              class="img-fluid rounded border border-secondary border-opacity-25 w-100"
            />
          </div>

          <!-- Panneau d'actions -->
          <div class="card bg-dark text-light border-secondary border-opacity-50 p-3 shadow-sm mb-4">
            <button class="btn btn-success w-100 mb-2 fw-semibold">
              + {{ $t('watchlist') }}
            </button>
            <button class="btn btn-outline-light w-100 fw-semibold">
              ★ {{ $t('rate') }}
            </button>
          </div>

          <!-- Plateformes VOD adaptées au pays -->
          <div v-if="providers?.flatrate?.length" class="vod-section">
            <h6 class="text-uppercase text-muted fw-bold small mb-2">{{ $t('streaming') }}</h6>
            <div class="d-flex flex-wrap gap-2">
              <img 
                v-for="provider in providers.flatrate" 
                :key="provider.provider_id"
                :src="`https://image.tmdb.org/t/p/original${provider.logo_path}`" 
                :alt="provider.provider_name"
                :title="provider.provider_name"
                class="rounded provider-logo border border-secondary border-opacity-25"
                width="40"
                height="40"
              />
            </div>
          </div>
        </div>

        <!-- Colonne Droite : Informations -->
        <div class="col-12 col-md-8 col-lg-9">
          <div class="movie-header mb-4">
            <h1 class="display-4 fw-bold mb-1">
              {{ movie.title }}
              <span v-if="releaseYear" class="text-muted fw-normal fs-3">({{ releaseYear }})</span>
            </h1>

            <p v-if="movie.original_title !== movie.title" class="text-muted fst-italic mb-3">
              {{ $t('originalTitle') }} : {{ movie.original_title }}
            </p>

            <!-- Méta-données (Durée, Genres, Note) -->
            <div class="d-flex flex-wrap align-items-center gap-3 mb-4">
              <span v-if="formattedRuntime" class="text-muted fw-semibold">
                {{ formattedRuntime }}
              </span>
              
              <div class="d-flex flex-wrap gap-2">
                <span 
                  v-for="genre in movie.genres" 
                  :key="genre.id"
                  class="badge bg-secondary bg-opacity-25 text-light border border-secondary border-opacity-50"
                >
                  {{ genre.name }}
                </span>
              </div>

              <!-- Note sur 5 étoiles -->
              <div v-if="movie.vote_average" class="ms-auto text-warning fw-bold fs-5">
                ★ {{ (movie.vote_average / 2).toFixed(1) }} <small class="text-muted fw-normal fs-6">/ 5</small>
              </div>
            </div>

            <!-- Slogan (Tagline) du film s'il existe -->
            <h5 v-if="movie.tagline" class="text-light fst-italic fw-normal mb-4 opacity-75">
              "{{ movie.tagline }}"
            </h5>
          </div>

          <!-- Synopsis -->
          <div class="overview-section">
            <h6 class="text-uppercase text-muted fw-bold small mb-2 border-bottom border-secondary border-opacity-25 pb-2">
              {{ $t('synopsis') }}
            </h6>
            <p class="lead text-light opacity-75 fs-6 lh-lg mt-3">
              {{ movie.overview || $t('noOverview') }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Loader plein écran pendant la requête API -->
  <div v-else-if="pending" class="min-vh-100 bg-dark text-light d-flex align-items-center justify-content-center">
    <div class="spinner-border text-secondary" role="status"></div>
  </div>
</template>

<script lang="ts" setup>
const route = useRoute()
const { locale, localeProperties } = useI18n()
const { getMovieDetails } = useMovies()

const movie = ref<any>(null)
const pending = ref(true)

// Charger les données du film
const fetchMovieData = async () => {
  pending.value = true
  movie.value = await getMovieDetails(route.params.id as string)
  pending.value = false
}

onMounted(fetchMovieData)

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

// Récupérer les plateformes VOD dynamiquement selon la langue active
const providers = computed(() => {
  const countryCode = (localeProperties.value as any).region || 'US'
  return movie.value?.['watch/providers']?.results?.[countryCode]
})

// Style dynamique de l'image de fond
const backdropStyle = computed(() => {
  if (!movie.value?.backdrop_path) return { backgroundColor: '#14181c' }
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
  height: 450px;
  position: relative;
  mask-image: linear-gradient(to bottom, rgba(0,0,0,1) 50%, rgba(0,0,0,0) 100%);
  -webkit-mask-image: linear-gradient(to bottom, rgba(0,0,0,1) 50%, rgba(0,0,0,0) 100%);
}

.backdrop-overlay {
  background: linear-gradient(to bottom, rgba(20,24,28,0.3) 0%, rgba(20,24,28,1) 100%);
}

.content-wrapper {
  margin-top: -200px;
  position: relative;
  z-index: 2;
}
</style>