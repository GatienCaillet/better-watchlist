<template>
  <div class="container page-container">
    <!-- Présentation + recherche directe -->
    <section class="hero text-center mx-auto mb-5 pt-lg-4">
      <h1 class="display-5 fw-bold mb-3">{{ $t('home.title') }}</h1>
      <p class="lead text-muted mb-4">{{ $t('home.tagline') }}</p>

      <form role="search" @submit.prevent="goSearch">
        <label for="home-search" class="visually-hidden">{{ $t('search.placeholder') }}</label>
        <div class="input-group input-group-lg">
          <span class="input-group-text" aria-hidden="true"><i class="bi bi-search"></i></span>
          <input
            id="home-search"
            v-model="search"
            type="search"
            class="form-control"
            :placeholder="$t('search.placeholder')"
          />
          <button class="btn btn-primary px-4" type="submit">
            {{ $t('search.button') }}
          </button>
        </div>
      </form>
    </section>

    <!-- Tendances de la semaine -->
    <section aria-labelledby="trending-title">
      <h2 id="trending-title" class="page-title mb-3">{{ $t('home.trending') }}</h2>

      <!-- Chargement : emplacements gris aux dimensions des affiches -->
      <div v-if="pending" class="row g-3" aria-busy="true">
        <span class="visually-hidden">{{ $t('search.loading') }}</span>
        <div v-for="n in 12" :key="n" class="col-6 col-sm-4 col-md-3 col-lg-2">
          <div class="skeleton poster-ratio"></div>
          <div class="skeleton mt-2 skeleton-line"></div>
        </div>
      </div>

      <div v-else-if="error" class="empty-state text-center p-5">
        <i class="bi bi-cloud-slash fs-1 text-muted" aria-hidden="true"></i>
        <p class="text-muted mt-2 mb-0">{{ $t('home.trendingError') }}</p>
      </div>

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

.skeleton-line {
  height: 0.8rem;
  width: 70%;
}
</style>
