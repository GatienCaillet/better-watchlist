<template>
  <div class="container page-container">
    <!-- En-tête de la maquette Home : titre à gauche, filtres à droite -->
    <header class="page-toolbar">
      <h1 class="page-title mb-0">{{ $t('nav.films') }}</h1>

      <div class="filter-bar" role="group" :aria-label="$t('filters.sortLabel')">
        <label for="films-decade" class="visually-hidden">{{ $t('filters.decadeLabel') }}</label>
        <select id="films-decade" v-model="decade" class="form-select filter-select">
          <option value="">{{ $t('filters.decade') }}</option>
          <option v-for="value in decades" :key="value" :value="String(value)">{{ $t('filters.decadeValue', { decade: value }) }}</option>
        </select>

        <label for="films-genre" class="visually-hidden">{{ $t('filters.genreLabel') }}</label>
        <select id="films-genre" v-model="genre" class="form-select filter-select">
          <option value="">{{ $t('filters.genre') }}</option>
          <option v-for="item in genres || []" :key="item.id" :value="String(item.id)">{{ item.name }}</option>
        </select>

        <label for="films-service" class="visually-hidden">{{ $t('filters.serviceLabel') }}</label>
        <select id="films-service" v-model="provider" class="form-select filter-select">
          <option value="">{{ $t('filters.service') }}</option>
          <option v-for="item in services" :key="item.provider_id" :value="String(item.provider_id)">{{ item.provider_name }}</option>
        </select>

        <label for="films-sort" class="visually-hidden">{{ $t('filters.sortLabel') }}</label>
        <select id="films-sort" v-model="sort" class="form-select filter-select">
          <option value="popularity">{{ $t('filters.sortPopularity') }}</option>
          <option value="rating">{{ $t('filters.sortRating') }}</option>
          <option value="recent">{{ $t('filters.sortRecent') }}</option>
        </select>
      </div>
    </header>

    <!-- Chargement : emplacements gris aux dimensions des affiches -->
    <ul v-if="pending" class="poster-grid" aria-busy="true">
      <li v-for="n in 12" :key="n">
        <div class="skeleton skeleton-poster"></div>
        <div class="skeleton skeleton-line mt-2"></div>
      </li>
    </ul>

    <div v-else-if="error" class="empty-state text-center p-5">
      <i class="bi bi-cloud-slash fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2 mb-0">{{ $t('filters.loadError') }}</p>
    </div>

    <div v-else-if="!movies?.length" class="empty-state text-center p-5">
      <i class="bi bi-funnel fs-1 text-muted" aria-hidden="true"></i>
      <p class="text-muted mt-2">{{ $t('filters.noMatch') }}</p>
      <button type="button" class="btn btn-outline-secondary" @click="resetFilters">{{ $t('filters.reset') }}</button>
    </div>

    <ul v-else class="poster-grid">
      <li v-for="movie in movies" :key="movie.id">
        <MovieCard :movie="movie" />
      </li>
    </ul>
  </div>
</template>

<script lang="ts" setup>
const { t, locale, localeProperties } = useI18n()
const { profile, platforms } = useCurrentUser()

useHead({ title: () => t('nav.films') })

// TMDB attend la langue au format 'fr-FR' / 'en-US'
const lang = computed(() => localeProperties.value?.iso || 'en-US')
// Pays du profil si connecté, sinon pays associé à la langue active
const region = computed(() => profile.value?.watch_region || defaultRegion(locale.value))

// Filtres (chaîne vide = pas de filtre)
const decade = ref('')
const genre = ref('')
const provider = ref('')
const sort = ref('popularity')

const resetFilters = () => {
  decade.value = ''
  genre.value = ''
  provider.value = ''
  sort.value = 'popularity'
}

// Décennies de la plus récente aux années 1920
const currentDecade = Math.floor(new Date().getFullYear() / 10) * 10
const decades = Array.from({ length: (currentDecade - 1920) / 10 + 1 }, (_, i) => currentDecade - i * 10)

const { data: genres } = await useFetch<any[]>('/api/movies/genres', { query: { lang } })
const { data: providers } = await useFetch<any[]>('/api/providers', { query: { region, lang } })

// Les plateformes de l'utilisateur apparaissent en premier dans la liste
const services = computed(() => [...(providers.value || [])]
  .sort((a, b) => Number(platforms.value.includes(b.provider_id)) - Number(platforms.value.includes(a.provider_id))))

// La liste se recharge dès qu'un filtre change
const { data: movies, pending, error } = await useFetch<any[]>('/api/movies/discover', {
  query: computed(() => ({
    lang: lang.value,
    region: region.value,
    sort: sort.value,
    ...(decade.value ? { decade: decade.value } : {}),
    ...(genre.value ? { genre: genre.value } : {}),
    ...(provider.value ? { provider: provider.value } : {})
  }))
})

// Une plateforme d'un autre pays n'a plus de sens après un changement de pays
watch(region, () => { provider.value = '' })
</script>

<style lang="scss" scoped>
.skeleton-poster {
  aspect-ratio: 19 / 24;
}

.skeleton-line {
  height: 0.8rem;
  width: 70%;
}
</style>
