<template>
  <!-- Affiche + titre + note + année d'un film TMDB, avec lien vers sa page (maquettes S5) -->
  <NuxtLinkLocale :to="`/movie/${movie.id}`" class="movie-card d-block">
    <img
      v-if="movie.poster_path"
      :src="posterUrl(movie.poster_path) || ''"
      :alt="movie.title"
      class="poster-ratio hover-zoom"
      loading="lazy"
    />
    <div v-else class="poster-placeholder" role="img" :aria-label="movie.title">
      <i class="bi bi-film" aria-hidden="true"></i>
    </div>
    <div class="card-title mt-2 text-truncate" :title="movie.title">{{ movie.title }}</div>
    <div class="card-meta d-flex align-items-center">
      <!-- Note TMDB ramenée sur 5, puis l'année, séparées par un trait -->
      <span v-if="movie.vote_average" class="card-rating">
        <i class="bi bi-star" aria-hidden="true"></i> {{ (movie.vote_average / 2).toFixed(1) }}
      </span>
      <span>{{ movie.release_date?.slice(0, 4) }}</span>
    </div>
  </NuxtLinkLocale>
</template>

<script lang="ts" setup>
defineProps<{ movie: any }>()
</script>

<style lang="scss" scoped>
.movie-card {
  color: var(--bw-ink);
}

.card-title {
  font-size: 0.875rem;
  font-weight: 600;
}

.card-meta {
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
</style>
