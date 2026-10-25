<template>
  <div class="container py-5">
    <!-- Présentation + recherche directe -->
    <section class="hero text-center mx-auto mb-5">
      <h1 class="display-5 fw-bold mb-3">{{ $t('home.title') }}</h1>
      <p class="lead text-muted mb-4">{{ $t('home.tagline') }}</p>

      <form role="search" @submit.prevent="goSearch">
        <label for="home-search" class="visually-hidden">{{ $t('search.placeholder') }}</label>
        <div class="input-group input-group-lg">
          <input
            id="home-search"
            v-model="search"
            type="search"
            class="form-control"
            :placeholder="$t('search.placeholder')"
          />
          <button class="btn btn-primary px-4" type="submit">
            <i class="bi bi-search" aria-hidden="true"></i>
            {{ $t('search.button') }}
          </button>
        </div>
      </form>
    </section>

    <!-- Tendances de la semaine -->
    <section aria-labelledby="trending-title">
      <h2 id="trending-title" class="h5 mb-3">{{ $t('home.trending') }}</h2>

      <div v-if="pending" class="text-center py-4">
        <div class="spinner-border text-secondary" role="status">
          <span class="visually-hidden">{{ $t('search.loading') }}</span>
        </div>
      </div>

      <p v-else-if="error" class="text-muted">{{ $t('home.trendingError') }}</p>

      <div v-else class="row g-3">
        <div v-for="movie in trending" :key="movie.id" class="col-6 col-sm-4 col-md-3 col-lg-2">
          <MovieCard :movie="movie" />
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
const localePath = useLocalePath()
const { localeProperties } = useI18n()

const search = ref('')

// TMDB attend la langue au format 'fr-FR' / 'en-US'
const lang = computed(() => localeProperties.value?.iso || 'en-US')

const { data: trending, pending, error } = await useFetch<any[]>('/api/movies/trending', {
  query: { lang }
})

const goSearch = () => {
  const q = search.value.trim()
  if (!q) return
  navigateTo({ path: localePath('/search'), query: { q } })
}
</script>

<style lang="scss" scoped>
.hero {
  max-width: 720px;
}
</style>
