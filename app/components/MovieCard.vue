<template>
  <!-- Affiche + titre + année d'un film TMDB, avec lien vers sa page -->
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
</template>

<script lang="ts" setup>
defineProps<{ movie: any }>()
</script>
