<template>
  <div class="container py-4">
    <h1 class="h3 mb-3">{{ $t('search.title') }}</h1>

    <form class="mb-4" role="search" @submit.prevent="submit">
      <label for="search-input" class="visually-hidden">{{ $t('search.placeholder') }}</label>
      <div class="input-group input-group-lg">
        <input
          id="search-input"
          v-model="query"
          type="search"
          class="form-control"
          :placeholder="$t('search.placeholder')"
          autofocus
        />
        <button class="btn btn-primary px-4" type="submit">
          <i class="bi bi-search" aria-hidden="true"></i>
          {{ $t('search.button') }}
        </button>
      </div>
    </form>

    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-secondary" role="status">
        <span class="visually-hidden">{{ $t('search.loading') }}</span>
      </div>
    </div>

    <p v-else-if="searched && !movies.length" class="text-muted">{{ $t('search.noResults') }}</p>

    <div v-else class="row g-3">
      <div v-for="movie in movies" :key="movie.id" class="col-6 col-sm-4 col-md-3 col-lg-2">
        <NuxtLinkLocale :to="`/movie/${movie.id}`" class="text-light d-block">
          <img
            v-if="movie.poster_path"
            :src="posterUrl(movie.poster_path) || ''"
            :alt="movie.title"
            class="rounded poster-ratio hover-zoom"
            loading="lazy"
          />
          <div v-else class="rounded poster-ratio bg-dark d-flex align-items-center justify-content-center text-muted">
            <i class="bi bi-film fs-2" aria-hidden="true"></i>
          </div>
          <div class="small fw-semibold mt-2 text-truncate" :title="movie.title">{{ movie.title }}</div>
          <div class="small text-muted">{{ movie.release_date?.slice(0, 4) }}</div>
        </NuxtLinkLocale>
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
