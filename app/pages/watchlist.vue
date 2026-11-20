<template>
  <div class="container page-container">
    <!-- En-tête de la maquette Watchlist : titre à gauche, filtres à droite -->
    <header class="page-toolbar">
      <div class="d-flex align-items-center gap-2">
        <h1 class="page-title mb-0">{{ $t('myWatchlist.title') }}</h1>
        <span v-if="!loading && movies.length" class="count-pill">
          {{ $t('myWatchlist.count', { count: filteredMovies.length }) }}
        </span>
      </div>

      <div v-if="!loading && movies.length" class="filter-bar" role="group" :aria-label="$t('filters.sortLabel')">
        <label for="watchlist-decade" class="visually-hidden">{{ $t('filters.decadeLabel') }}</label>
        <select id="watchlist-decade" v-model="decade" class="form-select filter-select">
          <option value="">{{ $t('filters.decade') }}</option>
          <option v-for="value in decades" :key="value" :value="String(value)">{{ $t('filters.decadeValue', { decade: value }) }}</option>
        </select>

        <label for="watchlist-genre" class="visually-hidden">{{ $t('filters.genreLabel') }}</label>
        <select id="watchlist-genre" v-model="genre" class="form-select filter-select">
          <option value="">{{ $t('filters.genre') }}</option>
          <option v-for="item in genreOptions" :key="item.id" :value="String(item.id)">{{ item.name }}</option>
        </select>

        <label for="watchlist-service" class="visually-hidden">{{ $t('filters.serviceLabel') }}</label>
        <select id="watchlist-service" v-model="provider" class="form-select filter-select">
          <option value="">{{ $t('filters.service') }}</option>
          <option v-for="item in serviceOptions" :key="item.provider_id" :value="String(item.provider_id)">{{ item.provider_name }}</option>
        </select>

        <label for="watchlist-sort" class="visually-hidden">{{ $t('filters.sortLabel') }}</label>
        <select id="watchlist-sort" v-model="sort" class="form-select filter-select">
          <option value="added">{{ $t('filters.sortAdded') }}</option>
          <option value="title">{{ $t('filters.sortTitle') }}</option>
          <option value="year">{{ $t('filters.sortYear') }}</option>
        </select>
      </div>
    </header>

    <!-- Chargement : emplacements gris aux dimensions des affiches -->
    <ul v-if="loading" class="poster-grid" aria-busy="true">
      <li v-for="n in 12" :key="n">
        <div class="skeleton skeleton-poster"></div>
        <div class="skeleton skeleton-line mt-2"></div>
      </li>
    </ul>

    <!-- Watchlist vide : on propose d'aller chercher des films -->
    <div v-else-if="!movies.length" class="empty-state text-center p-5">
      <i class="bi bi-bookmark fs-1 text-muted" aria-hidden="true"></i>
      <h2 class="h5 mt-3">{{ $t('myWatchlist.empty') }}</h2>
      <p class="text-muted">{{ $t('myWatchlist.emptyText') }}</p>
      <NuxtLinkLocale to="/" class="btn btn-primary">
        <i class="bi bi-film" aria-hidden="true"></i> {{ $t('nav.films') }}
      </NuxtLinkLocale>
    </div>

    <!-- Aucun film ne correspond aux filtres -->
    <div v-else-if="!filteredMovies.length" class="empty-state text-center p-5">
      <i class="bi bi-funnel fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2">{{ $t('filters.noMatch') }}</p>
      <button type="button" class="btn btn-outline-secondary" @click="resetFilters">{{ $t('filters.reset') }}</button>
    </div>

    <ul v-else class="poster-grid">
      <li v-for="movie in filteredMovies" :key="movie.id">
        <MovieCard :movie="movie" :providers="userProviders(movie)" />
      </li>
    </ul>
  </div>
</template>

<script lang="ts" setup>
definePageMeta({ middleware: 'auth' })

const supabase = useSupabaseClient()
const { t, locale, localeProperties } = useI18n()
const { userId, profile, platforms } = useCurrentUser()

useHead({ title: () => t('myWatchlist.title') })

const lang = computed(() => localeProperties.value?.iso || 'en-US')
const region = computed(() => profile.value?.watch_region || defaultRegion(locale.value))

const items = ref<any[]>([])
const details = ref<Record<number, any>>({})
const loading = ref(true)

// Filtres (chaîne vide = pas de filtre)
const decade = ref('')
const genre = ref('')
const provider = ref('')
const sort = ref('added')

const resetFilters = () => {
  decade.value = ''
  genre.value = ''
  provider.value = ''
  sort.value = 'added'
}

// Les films viennent de movie_cache, complétés par TMDB (genres, note, plateformes)
const movies = computed(() => items.value
  .filter(item => item.movie)
  .map((item) => {
    const extra = details.value[item.movie.id] || {}
    const year = item.movie.release_year || Number(extra.release_date?.slice(0, 4)) || null
    return {
      id: item.movie.id,
      title: movieTitle(item.movie, locale.value),
      poster_path: item.movie.poster_path,
      release_date: year ? String(year) : '',
      year,
      vote_average: extra.vote_average,
      genre_ids: extra.genre_ids || [],
      providers: extra.providers || [],
      added_at: item.added_at
    }
  }))

// Les options ne proposent que ce qui existe dans la watchlist
const decades = computed(() => [...new Set(movies.value
  .filter(m => m.year)
  .map(m => Math.floor(m.year / 10) * 10))]
  .sort((a, b) => b - a))

const { data: genres } = await useFetch<any[]>('/api/movies/genres', { query: { lang } })
const genreOptions = computed(() => {
  const used = new Set(movies.value.flatMap(m => m.genre_ids))
  return (genres.value || []).filter(g => used.has(g.id))
})

// Plateformes où au moins un film est disponible, celles de l'utilisateur en premier
const serviceOptions = computed(() => {
  const byId = new Map<number, any>()
  movies.value.forEach(m => m.providers.forEach((p: any) => byId.set(p.provider_id, p)))
  return [...byId.values()].sort((a, b) =>
    Number(platforms.value.includes(b.provider_id)) - Number(platforms.value.includes(a.provider_id))
    || a.provider_name.localeCompare(b.provider_name))
})

const filteredMovies = computed(() => {
  const list = movies.value.filter(m =>
    (!decade.value || (m.year && Math.floor(m.year / 10) * 10 === Number(decade.value)))
    && (!genre.value || m.genre_ids.includes(Number(genre.value)))
    && (!provider.value || m.providers.some((p: any) => p.provider_id === Number(provider.value))))

  if (sort.value === 'title') return [...list].sort((a, b) => a.title.localeCompare(b.title, locale.value))
  if (sort.value === 'year') return [...list].sort((a, b) => (b.year || 0) - (a.year || 0))
  return list // déjà triée par date d'ajout (la plus récente d'abord)
})

// Logos affichés sous l'affiche : uniquement les plateformes de l'utilisateur
const userProviders = (movie: any) => movie.providers.filter((p: any) => platforms.value.includes(p.provider_id))

const loadDetails = async () => {
  const ids = movies.value.map(m => m.id)
  const chunks = []
  for (let i = 0; i < ids.length; i += 100) chunks.push(ids.slice(i, i + 100))

  try {
    const results = await Promise.all(chunks.map(chunk => $fetch<any[]>('/api/movies/details', {
      query: { ids: chunk.join(','), region: region.value, lang: lang.value }
    })))
    details.value = Object.fromEntries(results.flat().map(d => [d.id, d]))
  } catch (error) {
    // Sans ces infos la watchlist reste affichée, seuls les filtres sont moins utiles
    console.error('Erreur lors du chargement des détails des films :', error)
  }
}

const loadWatchlist = async () => {
  const { data, error } = await supabase
    .from('personal_watchlist')
    .select('added_at, movie:movie_cache(id, original_title, localized_titles, poster_path, release_year)')
    .eq('user_id', userId.value)
    .order('added_at', { ascending: false })

  if (error) console.error('Erreur lors du chargement de la watchlist :', error)
  items.value = data || []
  await loadDetails()
  loading.value = false
}

onMounted(loadWatchlist)

// Les plateformes changent avec le pays, les genres avec la langue
watch([region, lang], () => {
  provider.value = ''
  if (items.value.length) loadDetails()
})
</script>

<style lang="scss" scoped>
.count-pill {
  padding: 0.2rem 0.7rem;
  border: 1px solid var(--bw-border);
  border-radius: 999px;
  background: #fff;
  font-size: 0.8rem;
  color: var(--bs-secondary-color);
}

.skeleton-poster {
  aspect-ratio: 19 / 24;
}

.skeleton-line {
  height: 0.8rem;
  width: 70%;
}
</style>
