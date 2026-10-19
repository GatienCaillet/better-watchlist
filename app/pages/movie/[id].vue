<template>
<div v-if="movie">
    <h1>{{ movie.title }}</h1>
    <p><strong>Titre original :</strong> {{ movie.original_title }}</p>
    <p><strong>Date de sortie :</strong> {{ movie.release_date }}</p>
    <p><strong>Durée :</strong> {{ movie.runtime }} minutes</p>

    <!-- Affiche du film -->
    <img 
      v-if="movie.poster_path" 
      :src="`https://image.tmdb.org/t/p/w500${movie.poster_path}`" 
      :alt="movie.title"
      width="200"
    />

    <!-- Synopsis -->
    <h2>Synopsis</h2>
    <p>{{ movie.overview }}</p>
  </div>

  <div v-else-if="pending">
    <p>Chargement du film...</p>
  </div>
</template>

<script lang="ts" setup>
const route = useRoute()
const { getMovieDetails } = useMovies()

const movie = ref<any>(null)
const pending = ref(true)

onMounted(async () => {
  // Récupère l'ID passé dans l'URL (ex: /movie/157336)
  const data = await getMovieDetails(route.params.id as string)
  movie.value = data
  pending.value = false
})
</script>

<style>

</style>