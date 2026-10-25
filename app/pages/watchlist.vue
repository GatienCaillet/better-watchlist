<template>
  <div class="container py-4">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-4">
      <div>
        <h1 class="h3 mb-1">{{ $t('myWatchlist.title') }}</h1>
        <p class="text-muted mb-0">{{ $t('myWatchlist.subtitle') }}</p>
      </div>
      <span v-if="!loading && movies.length" class="small text-muted">
        {{ $t('myWatchlist.count', { count: movies.length }) }}
      </span>
    </div>

    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-secondary" role="status"></div>
    </div>

    <!-- Watchlist vide : on propose d'aller chercher des films -->
    <div v-else-if="!movies.length" class="text-center py-5">
      <i class="bi bi-bookmark fs-1 text-muted" aria-hidden="true"></i>
      <h2 class="h5 mt-3">{{ $t('myWatchlist.empty') }}</h2>
      <p class="text-muted">{{ $t('myWatchlist.emptyText') }}</p>
      <NuxtLinkLocale to="/search" class="btn btn-primary">
        <i class="bi bi-search" aria-hidden="true"></i> {{ $t('search.title') }}
      </NuxtLinkLocale>
    </div>

    <div v-else class="row g-3">
      <div v-for="movie in movies" :key="movie.id" class="col-6 col-sm-4 col-md-3 col-lg-2">
        <MovieCard :movie="movie" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
definePageMeta({ middleware: 'auth' })

const supabase = useSupabaseClient()
const { t, locale } = useI18n()
const { userId } = useCurrentUser()

useHead({ title: () => t('myWatchlist.title') })

const items = ref<any[]>([])
const loading = ref(true)

// Les films viennent de movie_cache : on les met au format attendu par MovieCard
const movies = computed(() => items.value
  .filter(item => item.movie)
  .map(item => ({
    id: item.movie.id,
    title: movieTitle(item.movie, locale.value),
    poster_path: item.movie.poster_path,
    release_date: item.movie.release_year ? String(item.movie.release_year) : ''
  })))

const loadWatchlist = async () => {
  const { data, error } = await supabase
    .from('personal_watchlist')
    .select('added_at, movie:movie_cache(id, original_title, localized_titles, poster_path, release_year)')
    .eq('user_id', userId.value)
    .order('added_at', { ascending: false })

  if (error) console.error('Erreur lors du chargement de la watchlist :', error)
  items.value = data || []
  loading.value = false
}

onMounted(loadWatchlist)
</script>
