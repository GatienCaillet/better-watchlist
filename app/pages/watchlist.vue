<template>
  <div class="container page-container">
    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-4">
      <div>
        <h1 class="page-title mb-0">{{ $t('myWatchlist.title') }}</h1>
        <p class="page-subtitle text-muted mb-0 mt-1">{{ $t('myWatchlist.subtitle') }}</p>
      </div>
      <span v-if="!loading && movies.length" class="count-pill">
        {{ $t('myWatchlist.count', { count: movies.length }) }}
      </span>
    </div>

    <!-- Chargement : emplacements gris aux dimensions des affiches -->
    <div v-if="loading" class="row g-3" aria-busy="true">
      <div v-for="n in 12" :key="n" class="col-6 col-sm-4 col-md-3 col-lg-2">
        <div class="skeleton poster-ratio"></div>
        <div class="skeleton mt-2 skeleton-line"></div>
      </div>
    </div>

    <!-- Watchlist vide : on propose d'aller chercher des films -->
    <div v-else-if="!movies.length" class="empty-state text-center p-5">
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

<style lang="scss" scoped>
.count-pill {
  padding: 0.35rem 0.9rem;
  border: 1px solid var(--bw-border);
  border-radius: 999px;
  background: #fff;
  font-size: 0.85rem;
  color: var(--bs-secondary-color);
}

.skeleton-line {
  height: 0.8rem;
  width: 70%;
}
</style>
