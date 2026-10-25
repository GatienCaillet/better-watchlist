<template>
  <nav class="navbar sticky-top app-navbar" :aria-label="$t('nav.label')">
    <div class="container flex-nowrap gap-2">
      <NuxtLinkLocale to="/" class="navbar-brand d-flex align-items-center gap-2 fw-bold me-auto">
        <span class="brand-logo" aria-hidden="true"><i class="bi bi-film"></i></span>
        <span class="brand-name">Better<span class="text-primary">Watchlist</span></span>
      </NuxtLinkLocale>

      <!-- Recherche rapide accessible depuis toutes les pages -->
      <form class="search-form" role="search" @submit.prevent="goSearch">
        <label for="nav-search" class="visually-hidden">{{ $t('nav.searchPlaceholder') }}</label>
        <div class="position-relative">
          <i class="bi bi-search search-icon" aria-hidden="true"></i>
          <input
            id="nav-search"
            v-model="search"
            type="search"
            class="form-control form-control-sm"
            :placeholder="$t('nav.searchPlaceholder')"
          />
        </div>
      </form>

      <!-- Choix de la langue -->
      <div ref="langMenu" class="dropdown">
        <button
          type="button"
          class="btn btn-sm btn-outline-secondary d-flex align-items-center gap-1"
          :aria-expanded="langOpen"
          aria-haspopup="true"
          :aria-label="$t('nav.language')"
          @click="langOpen = !langOpen"
        >
          <i class="bi bi-translate" aria-hidden="true"></i>
          {{ locale.toUpperCase() }}
        </button>
        <!-- data-bs-popper="static" : alignement à droite sans le JS (Popper) de Bootstrap -->
        <ul class="dropdown-menu dropdown-menu-end" data-bs-popper="static" :class="{ show: langOpen }">
          <li v-for="loc in locales" :key="loc.code">
            <NuxtLink
              :to="switchLocalePath(loc.code)"
              class="dropdown-item d-flex justify-content-between align-items-center"
              @click="langOpen = false"
            >
              {{ loc.name }}
              <i v-if="loc.code === locale" class="bi bi-check2 text-primary" aria-hidden="true"></i>
            </NuxtLink>
          </li>
        </ul>
      </div>

      <!-- Lien de connexion, masqué une fois connecté -->
      <NuxtLinkLocale v-if="!user" to="/login" class="btn btn-sm btn-primary text-nowrap">
        {{ $t('auth.login') }}
      </NuxtLinkLocale>
    </div>
  </nav>
</template>

<script lang="ts" setup>
const user = useSupabaseUser()
const localePath = useLocalePath()
const switchLocalePath = useSwitchLocalePath()
const { locale, locales } = useI18n()

const search = ref('')
const langOpen = ref(false)
const langMenu = ref<HTMLElement | null>(null)

const goSearch = () => {
  const q = search.value.trim()
  if (!q) return
  navigateTo({ path: localePath('/search'), query: { q } })
  search.value = ''
}

// Le menu se ferme au clic en dehors ou avec Échap (on n'utilise pas le JS de Bootstrap)
const onDocumentClick = (e: MouseEvent) => {
  if (langMenu.value && !langMenu.value.contains(e.target as Node)) langOpen.value = false
}
const onKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') langOpen.value = false
}

onMounted(() => {
  document.addEventListener('click', onDocumentClick)
  document.addEventListener('keydown', onKeydown)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', onDocumentClick)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<style lang="scss" scoped>
.app-navbar {
  background-color: rgba(11, 14, 20, 0.85);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--bw-border);
  min-height: 64px;
}

.brand-logo {
  width: 2rem;
  height: 2rem;
  border-radius: 0.55rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--bw-accent);
  color: #04130a;
}

// Sur très petit écran on garde le logo seul pour que tout tienne sur une ligne
.brand-name {
  @media (max-width: 400px) {
    display: none;
  }
}

.search-form {
  width: min(260px, 45vw);

  .form-control {
    padding-left: 2rem;
    border-radius: 999px;
  }
}

.search-icon {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--bs-secondary-color);
  font-size: 0.85rem;
}
</style>
