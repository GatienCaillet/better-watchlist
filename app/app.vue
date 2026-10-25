<template>
  <div>
    <AppNavbar />
    <NuxtPage />
  </div>
</template>

<script lang="ts" setup>
const { locale } = useI18n()

// data-bs-theme="dark" active les variables sombres de Bootstrap ($body-bg-dark...) sur toute l'app
useHead({
  titleTemplate: (title) => title ? `${title} · BetterWatchlist` : 'BetterWatchlist',
  htmlAttrs: { lang: locale, 'data-bs-theme': 'dark' }
})
</script>
