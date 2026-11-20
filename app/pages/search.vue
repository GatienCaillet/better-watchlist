<template>
  <div class="container page-container">
    <!-- La saisie se fait dans la barre de recherche du menu -->
    <h1 class="page-title mb-4">
      {{ query ? $t('search.resultsFor', { query }) : $t('search.title') }}
    </h1>

    <div v-if="!query" class="empty-state text-center p-5">
      <i class="bi bi-search fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2 mb-0">{{ $t('search.prompt') }}</p>
    </div>

    <div v-else-if="loading" class="text-center py-5">
      <div class="spinner-border text-secondary" role="status">
        <span class="visually-hidden">{{ $t('search.loading') }}</span>
      </div>
    </div>

    <div v-else-if="searched && !movies.length" class="empty-state text-center py-5">
      <i class="bi bi-film fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2 mb-0">{{ $t('search.noResults') }}</p>
    </div>

    <ul v-else class="poster-grid">
      <li v-for="movie in movies" :key="movie.id">
        <MovieCard :movie="movie" />
      </li>
    </ul>
  </div>
</template>

<script lang="ts" setup>
const route = useRoute()
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

onMounted(runSearch)

watch(() => route.query.q, (value) => {
  query.value = (value as string) || ''
  runSearch()
})
</script>
