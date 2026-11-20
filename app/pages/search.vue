<template>
  <div class="container page-container">
    <h1 class="page-title mb-3">{{ $t('search.title') }}</h1>

    <form class="mb-4" role="search" @submit.prevent="submit">
      <label for="search-input" class="visually-hidden">{{ $t('search.placeholder') }}</label>
      <div class="input-group input-group-lg">
        <span class="input-group-text" aria-hidden="true"><i class="bi bi-search"></i></span>
        <input
          id="search-input"
          v-model="query"
          type="search"
          class="form-control"
          :placeholder="$t('search.placeholder')"
          autofocus
        />
        <button class="btn btn-primary px-4" type="submit">
          {{ $t('search.button') }}
        </button>
      </div>
    </form>

    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-secondary" role="status">
        <span class="visually-hidden">{{ $t('search.loading') }}</span>
      </div>
    </div>

    <div v-else-if="searched && !movies.length" class="empty-state text-center py-5">
      <i class="bi bi-film fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2 mb-0">{{ $t('search.noResults') }}</p>
    </div>

    <div v-else class="row g-3">
      <div v-for="movie in movies" :key="movie.id" class="col-6 col-sm-4 col-md-3 col-lg-2">
        <MovieCard :movie="movie" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const { searchMovies } = useMovies()

useHead({ title: () => t('search.title') })

// La recherche est dans l'URL (?q=...) pour pouvoir partager le lien ou revenir en arrière
const query = ref((route.query.q as string) || '')
const movies = ref<any[]>([])
const loading = ref(false)
const searched = ref(false)

const runSearch = async () => {
  const q = query.value.trim()
  if (!q) return

  loading.value = true
  const data: any = await searchMovies(q)
  movies.value = data?.results || []
  loading.value = false
  searched.value = true
}

const submit = () => {
  router.replace({ query: { q: query.value.trim() } })
}

onMounted(runSearch)

watch(() => route.query.q, (value) => {
  query.value = (value as string) || ''
  runSearch()
})
</script>
