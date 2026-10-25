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

      <!-- Menu utilisateur une fois connecté -->
      <div v-if="user" ref="userMenu" class="dropdown">
        <button
          type="button"
          class="btn btn-sm p-0 d-flex align-items-center gap-2 user-button"
          :aria-expanded="userOpen"
          aria-haspopup="true"
          :aria-label="$t('nav.account')"
          @click="userOpen = !userOpen"
        >
          <span class="user-initial" aria-hidden="true">{{ initial }}</span>
          <span v-if="profile" class="d-none d-lg-inline text-light">{{ profile.username }}</span>
        </button>
        <ul class="dropdown-menu dropdown-menu-end" data-bs-popper="static" :class="{ show: userOpen }">
          <li class="px-3 py-2 small text-muted border-bottom mb-1">
            {{ $t('nav.signedInAs') }}<br />
            <strong class="text-light">{{ profile?.username || user.email }}</strong>
            <span v-if="profile" class="d-block">{{ user.email }}</span>
          </li>
          <li>
            <NuxtLinkLocale to="/watchlist" class="dropdown-item" @click="userOpen = false">
              <i class="bi bi-bookmark me-2" aria-hidden="true"></i>{{ $t('nav.watchlist') }}
            </NuxtLinkLocale>
          </li>
          <li>
            <NuxtLinkLocale to="/settings" class="dropdown-item" @click="userOpen = false">
              <i class="bi bi-gear me-2" aria-hidden="true"></i>{{ $t('nav.settings') }}
            </NuxtLinkLocale>
          </li>
          <li>
            <button type="button" class="dropdown-item text-danger" @click="logout">
              <i class="bi bi-box-arrow-right me-2" aria-hidden="true"></i>{{ $t('nav.logout') }}
            </button>
          </li>
        </ul>
      </div>

      <!-- Connexion / inscription, masqués une fois connecté -->
      <template v-else>
        <NuxtLinkLocale to="/login" class="btn btn-sm btn-outline-secondary text-nowrap d-none d-sm-inline-flex">
          {{ $t('auth.login') }}
        </NuxtLinkLocale>
        <NuxtLinkLocale to="/signup" class="btn btn-sm btn-primary text-nowrap">
          {{ $t('auth.signup') }}
        </NuxtLinkLocale>
      </template>
    </div>
  </nav>
</template>

<script lang="ts" setup>
const supabase = useSupabaseClient()
// user = infos du JWT (sub, email...), profile = ligne de la table profiles (pseudo...)
const { user, userId, profile, loadProfile } = useCurrentUser()
const localePath = useLocalePath()
const switchLocalePath = useSwitchLocalePath()
const { locale, locales } = useI18n()

const search = ref('')
const langOpen = ref(false)
const langMenu = ref<HTMLElement | null>(null)
const userOpen = ref(false)
const userMenu = ref<HTMLElement | null>(null)

// Initiale du pseudo (ou de l'e-mail si le profil n'est pas encore chargé)
const initial = computed(() => (profile.value?.username || user.value?.email || '?').charAt(0).toUpperCase())

// Le profil est chargé au démarrage par le plugin current-user,
// on le recharge seulement en cas de connexion / déconnexion
watch(userId, loadProfile)

const logout = async () => {
  userOpen.value = false
  await supabase.auth.signOut()
  navigateTo(localePath('/'))
}

const goSearch = () => {
  const q = search.value.trim()
  if (!q) return
  navigateTo({ path: localePath('/search'), query: { q } })
  search.value = ''
}

// Les menus se ferment au clic en dehors ou avec Échap (on n'utilise pas le JS de Bootstrap)
const onDocumentClick = (e: MouseEvent) => {
  const target = e.target as Node
  if (langMenu.value && !langMenu.value.contains(target)) langOpen.value = false
  if (userMenu.value && !userMenu.value.contains(target)) userOpen.value = false
}
const onKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape') {
    langOpen.value = false
    userOpen.value = false
  }
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

.user-initial {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--bw-surface-2);
  border: 2px solid var(--bw-border-strong);
  font-family: "Outfit", sans-serif;
  font-weight: 700;
}

.user-button:hover .user-initial {
  border-color: var(--bw-accent);
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
