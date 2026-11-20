<template>
  <!-- Affiche + titre + note + année d'un film TMDB, avec lien vers sa page (maquettes S5) -->
  <NuxtLinkLocale :to="`/movie/${movie.id}`" class="movie-card d-block">
    <img
      v-if="movie.poster_path"
      :src="posterUrl(movie.poster_path) || ''"
      :alt="movie.title"
      class="poster-ratio card-poster hover-zoom"
      loading="lazy"
    />
    <div v-else class="poster-placeholder card-poster" role="img" :aria-label="movie.title">
      <i class="bi bi-film" aria-hidden="true"></i>
    </div>
    <div class="card-title text-truncate" :title="movie.title">{{ movie.title }}</div>
    <div class="card-meta d-flex align-items-center">
      <!-- Note TMDB ramenée sur 5, puis l'année, séparées par un trait -->
      <span v-if="movie.vote_average" class="card-rating">
        <i class="bi bi-star" aria-hidden="true"></i> {{ (movie.vote_average / 2).toFixed(1) }}
      </span>
      <span>{{ movie.release_date?.slice(0, 4) }}</span>
      <!-- Plateformes de l'utilisateur où le film est disponible (watchlist) -->
      <img
        v-for="provider in providers"
        :key="provider.provider_id"
        :src="`https://image.tmdb.org/t/p/w92${provider.logo_path}`"
        :alt="provider.provider_name"
        :title="provider.provider_name"
        class="provider-logo"
        width="20"
        height="20"
      />
    </div>
  </NuxtLinkLocale>
</template>

<script lang="ts" setup>
withDefaults(defineProps<{
  movie: any
  providers?: any[]
}>(), { providers: () => [] })
</script>

<style lang="scss" scoped>
.movie-card {
  color: var(--bw-ink);
}

// Proportions des affiches des maquettes (190 x 240)
.card-poster {
  aspect-ratio: 19 / 24;
}

.card-title {
  margin-top: 0.75rem;
  font-size: 0.875rem;
  font-weight: 600;
}

.card-meta {
  margin-top: 0.15rem;
  font-size: 0.8rem;
  color: var(--bs-secondary-color);
}

.card-rating {
  padding-right: 0.45rem;
  margin-right: 0.45rem;
  border-right: 1px solid var(--bw-border-strong);

  i {
    color: var(--bw-ink);
  }
}

.provider-logo {
  margin-left: 0.6rem;
  border-radius: 50%;

  & + & {
    margin-left: 0.3rem;
  }
}
</style>
