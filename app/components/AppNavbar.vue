<template>
  <nav class="app-navbar" :aria-label="$t('nav.label')">
    <div class="container navbar-inner">
      <NuxtLinkLocale to="/" class="brand" aria-label="BetterWatchlist">
        <span class="brand-full" aria-hidden="true">BetterWatchlist</span>
        <span class="brand-short" aria-hidden="true">BW</span>
      </NuxtLinkLocale>

      <!-- Liens principaux en pilules, centrés sur ordinateur (maquettes S5) -->
      <div class="nav-pills-group">
        <NuxtLinkLocale
          v-for="link in links"
          :key="link.to"
          :to="link.to"
          class="nav-pill"
          :class="{ active: isActive(link.to) }"
          :aria-current="isActive(link.to) ? 'page' : undefined"
        >
          {{ $t(link.label) }}
        </NuxtLinkLocale>
        <NuxtLinkLocale
          to="/search"
          class="nav-pill nav-pill-icon"
          :class="{ active: isActive('/search') }"
          :aria-label="$t('search.title')"
          :title="$t('search.title')"
          :aria-current="isActive('/search') ? 'page' : undefined"
        >
          <i class="bi bi-search" aria-hidden="true"></i>
        </NuxtLinkLocale>
      </div>

      <div class="nav-actions">
        <!-- Choix de la langue -->
        <div ref="langMenu" class="dropdown">
          <button
            type="button"
            class="lang-btn"
            :aria-expanded="langOpen"
            aria-haspopup="true"
            :aria-label="$t('nav.language')"
            @click="langOpen = !langOpen"
          >
            <i class="bi bi-translate" aria-hidden="true"></i>
            <span class="d-none d-sm-inline">{{ locale.toUpperCase() }}</span>
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
                <i v-if="loc.code === locale" class="bi bi-check2" aria-hidden="true"></i>
              </NuxtLink>
            </li>
          </ul>
        </div>

        <!-- Menu utilisateur une fois connecté -->
        <div v-if="user" ref="userMenu" class="dropdown">
          <button
            type="button"
            class="user-btn"
            :aria-expanded="userOpen"
            aria-haspopup="true"
            :aria-label="$t('nav.account')"
            @click="userOpen = !userOpen"
          >
            <span class="user-initial" aria-hidden="true">{{ initial }}</span>
            <span v-if="profile" class="d-none d-xl-inline user-name">{{ profile.username }}</span>
            <i class="bi bi-chevron-down small d-none d-sm-inline" aria-hidden="true"></i>
          </button>
          <ul class="dropdown-menu dropdown-menu-end" data-bs-popper="static" :class="{ show: userOpen }">
            <li class="px-3 py-2 small text-muted border-bottom mb-1">
              {{ $t('nav.signedInAs') }}<br />
              <strong class="text-body-emphasis">{{ profile?.username || user.email }}</strong>
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
            <li><hr class="dropdown-divider" /></li>
            <li>
              <button type="button" class="dropdown-item text-danger" @click="logout">
                <i class="bi bi-box-arrow-right me-2" aria-hidden="true"></i>{{ $t('nav.logout') }}
              </button>
            </li>
          </ul>
        </div>

        <!-- Connexion / inscription, masqués une fois connecté -->
        <template v-else>
          <NuxtLinkLocale to="/login" class="btn btn-sm btn-outline-secondary rounded-pill px-3 text-nowrap d-none d-sm-inline-flex">
            {{ $t('auth.login') }}
          </NuxtLinkLocale>
          <NuxtLinkLocale to="/signup" class="btn btn-sm btn-primary rounded-pill px-3 text-nowrap">
            {{ $t('auth.signup') }}
          </NuxtLinkLocale>
        </template>
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
const supabase = useSupabaseClient()
const route = useRoute()
// user = infos du JWT (sub, email...), profile = ligne de la table profiles (pseudo...)
const { user, userId, profile, loadProfile } = useCurrentUser()
const localePath = useLocalePath()
const switchLocalePath = useSwitchLocalePath()
const { locale, locales } = useI18n()

const langOpen = ref(false)
const langMenu = ref<HTMLElement | null>(null)
const userOpen = ref(false)
const userMenu = ref<HTMLElement | null>(null)

// La watchlist n'apparaît que pour un utilisateur connecté
const links = computed(() => [
  { to: '/', label: 'nav.films' },
  ...(user.value ? [{ to: '/watchlist', label: 'watchlist' }] : [])
])

// Page courante : l'accueil doit correspondre exactement, les autres par préfixe
const isActive = (to: string) => {
  const target = localePath(to)
  if (to === '/') return route.path === target
  return route.path === target || route.path.startsWith(`${target}/`)
}

// Initiale du pseudo (ou de l'e-mail si le profil n'est pas encore chargé)
const initial = computed(() => (profile.value?.username || user.value?.email || '?').charAt(0).toUpperCase())

// Le profil est chargé au démarrage par le plugin current-user,
// on le recharge seulement en cas de connexion / déconnexion
watch(userId, loadProfile)

// Les menus se ferment quand on change de page
watch(() => route.fullPath, () => {
  langOpen.value = false
  userOpen.value = false
})

const logout = async () => {
  userOpen.value = false
  await supabase.auth.signOut()
  navigateTo(localePath('/'))
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
  position: sticky;
  top: 0;
  z-index: 1030;
  background-color: rgba(243, 244, 246, 0.9);
  backdrop-filter: blur(12px);
}

.navbar-inner {
  position: relative;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem 1rem;
  min-height: 72px;
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
}

.brand {
  font-size: 1.5rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--bw-ink);
  white-space: nowrap;
}

// Sur très petit écran on garde un monogramme pour que la barre tienne sur une ligne
.brand-short {
  display: none;
}

@media (max-width: 400px) {
  .brand-full { display: none; }
  .brand-short { display: inline; }
}

// Groupe de pilules : centré dans la barre sur ordinateur, passe à la ligne sur petit écran si besoin
.nav-pills-group {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.3rem;
  border: 1px solid var(--bw-border-strong);
  border-radius: 999px;
  background: #fff;

  @media (min-width: 992px) {
    position: absolute;
    left: 50%;
    transform: translateX(-50%);
  }

  @media (max-width: 400px) {
    .nav-pill {
      padding: 0 0.8rem;
    }
  }
}

.nav-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 2.1rem;
  padding: 0 1.2rem;
  border: 1px solid var(--bw-border);
  border-radius: 999px;
  color: #6b7280;
  font-size: 0.9rem;
  white-space: nowrap;
  transition: color 0.15s ease, border-color 0.15s ease, background-color 0.15s ease;

  &:hover {
    color: var(--bw-ink);
    border-color: var(--bw-border-strong);
  }

  &.active {
    background: var(--bw-ink);
    border-color: var(--bw-ink);
    color: #fff;
    font-weight: 500;
  }
}

.nav-pill-icon {
  width: 2.1rem;
  padding: 0;
  color: var(--bw-ink);
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-left: auto;

  @media (max-width: 575.98px) {
    gap: 0.4rem;
  }
}

.lang-btn,
.user-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 2.25rem;
  border: 1px solid var(--bw-border-strong);
  border-radius: 999px;
  background: #fff;
  color: var(--bw-ink);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;

  &:hover {
    border-color: #9ca3af;
    box-shadow: var(--bw-shadow-sm);
  }
}

.lang-btn {
  gap: 0.3rem;
  padding: 0 0.6rem;
  font-weight: 700;
  font-size: 0.85rem;
}

.user-btn {
  height: 3rem;
  gap: 0.6rem;
  padding: 0 0.9rem 0 0.35rem;
  font-weight: 600;
  font-size: 0.9rem;

  @media (max-width: 575.98px) {
    height: 2.5rem;
    padding: 0 0.2rem;
  }
}

.user-initial {
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--bw-placeholder);
  color: var(--bw-ink);
  font-weight: 700;

  @media (max-width: 575.98px) {
    width: 2rem;
    height: 2rem;
  }
}

.user-name {
  max-width: 10rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dropdown-menu {
  min-width: 13rem;
  margin-top: 0.5rem;
}
</style>
