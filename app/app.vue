<template>
  <div>
    <AppNavbar />
    <NuxtPage />
  </div>
</template>

<script lang="ts" setup>
const { locale } = useI18n()

// Thème clair des maquettes S5 : les couleurs sont définies dans assets/scss/main.scss
useHead({
  titleTemplate: (title) => title ? `${title} · BetterWatchlist` : 'BetterWatchlist',
  htmlAttrs: { lang: locale, 'data-bs-theme': 'light' }
})
</script>
