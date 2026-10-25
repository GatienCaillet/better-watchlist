<template>
  <div class="container py-4 settings-page">
    <h1 class="h3 mb-1">{{ $t('settings.title') }}</h1>
    <p class="text-muted mb-4">{{ $t('settings.subtitle') }}</p>

    <div v-if="!form" class="text-center py-5">
      <div class="spinner-border text-secondary" role="status"></div>
    </div>

    <form v-else class="card p-4" novalidate @submit.prevent="saveProfile">
      <div class="mb-3">
        <label for="settings-username" class="form-label">{{ $t('auth.username') }}</label>
        <input
          id="settings-username"
          v-model="form.username"
          class="form-control"
          :class="{ 'is-invalid': !usernameValid }"
          aria-describedby="settings-username-help"
          maxlength="30"
          required
        />
        <div id="settings-username-help" class="form-text" :class="{ 'text-danger': !usernameValid }">
          {{ $t('auth.usernameHelp') }}
        </div>
      </div>

      <div class="mb-3">
        <div class="d-flex justify-content-between">
          <label for="settings-bio" class="form-label">{{ $t('settings.bio') }}</label>
          <small class="text-muted" aria-live="polite">{{ form.bio.length }} / 500</small>
        </div>
        <textarea
          id="settings-bio"
          v-model="form.bio"
          rows="4"
          maxlength="500"
          class="form-control"
          :placeholder="$t('settings.bioPlaceholder')"
        ></textarea>
      </div>

      <div class="mb-3">
        <label for="settings-region" class="form-label">{{ $t('settings.region') }}</label>
        <select id="settings-region" v-model="form.watch_region" class="form-select" aria-describedby="settings-region-help">
          <option v-for="region in regions" :key="region" :value="region">{{ regionName(region) }}</option>
        </select>
        <div id="settings-region-help" class="form-text">{{ $t('settings.regionHelp') }}</div>
      </div>

      <div v-if="errorMessage" class="alert alert-danger d-flex gap-2 py-2 small" role="alert">
        <i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>
        <span>{{ errorMessage }}</span>
      </div>
      <div v-if="saved" class="alert alert-success d-flex gap-2 py-2 small" role="status">
        <i class="bi bi-check-circle-fill" aria-hidden="true"></i>
        <span>{{ $t('settings.saved') }}</span>
      </div>

      <div class="d-flex align-items-center gap-3">
        <!-- Actif seulement s'il y a des modifications valides -->
        <button type="submit" class="btn btn-primary" :disabled="saving || !dirty || !usernameValid">
          <span v-if="saving" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
          {{ $t('settings.save') }}
        </button>
        <button v-if="dirty" type="button" class="btn btn-link text-muted" @click="resetForm">
          {{ $t('settings.discard') }}
        </button>
      </div>
    </form>

    <!-- Plateformes possédées : enregistrées dès le clic, pour le pays enregistré dans le profil -->
    <section v-if="profile" class="card p-4 mt-4" aria-labelledby="platforms-title">
      <h2 id="platforms-title" class="h5 mb-1">{{ $t('settings.platforms') }}</h2>
      <p class="text-muted small mb-3">
        {{ $t('settings.platformsHelp', { region: regionName(profile.watch_region) }) }}
      </p>

      <div v-if="loadingProviders" class="text-center py-3">
        <div class="spinner-border spinner-border-sm text-secondary" role="status"></div>
      </div>

      <div v-else class="d-flex flex-wrap gap-2" role="group" :aria-label="$t('settings.platforms')">
        <button
          v-for="provider in providers"
          :key="provider.provider_id"
          type="button"
          class="provider-btn"
          :aria-pressed="platforms.includes(provider.provider_id)"
          :title="provider.provider_name"
          :aria-label="provider.provider_name"
          @click="togglePlatform(provider.provider_id)"
        >
          <img :src="`https://image.tmdb.org/t/p/w92${provider.logo_path}`" alt="" width="52" height="52" />
        </button>
      </div>

      <div v-if="platformError" class="alert alert-danger d-flex gap-2 py-2 small mt-3 mb-0" role="alert">
        <i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>
        <span>{{ platformError }}</span>
      </div>
    </section>
  </div>
</template>

<script lang="ts" setup>
definePageMeta({ middleware: 'auth' })

const supabase = useSupabaseClient()
const { t, locale } = useI18n()
const { userId, profile, loadProfile } = useCurrentUser()

useHead({ title: () => t('settings.title') })

// Pays proposés pour le filtre VOD (codes ISO utilisés par TMDB)
const regions = ['FR', 'BE', 'CH', 'CA', 'US', 'GB', 'ES', 'DE', 'IT']

// Nom du pays dans la langue de l'interface (ex : "FR" -> "France" / "Francia")
const regionName = (code: string) => {
  try {
    return new Intl.DisplayNames([locale.value], { type: 'region' }).of(code) || code
  } catch {
    return code
  }
}

const form = ref<{ username: string; bio: string; watch_region: string } | null>(null)
const saving = ref(false)
const saved = ref(false)
const errorMessage = ref('')

const fromProfile = (value: any) => ({
  username: value.username,
  bio: value.bio || '',
  watch_region: value.watch_region
})

// Copie du profil dans le formulaire une fois chargé
watch(profile, (value) => {
  if (value && !form.value) form.value = fromProfile(value)
}, { immediate: true })

const dirty = computed(() => {
  if (!form.value || !profile.value) return false
  return JSON.stringify(form.value) !== JSON.stringify(fromProfile(profile.value))
})

// Mêmes règles que la contrainte CHECK de la table profiles
const usernameValid = computed(() => /^[A-Za-z0-9_.]{3,30}$/.test(form.value?.username || ''))

const resetForm = () => {
  form.value = fromProfile(profile.value)
  errorMessage.value = ''
}

const saveProfile = async () => {
  if (!form.value || !usernameValid.value) return
  saving.value = true
  saved.value = false
  errorMessage.value = ''

  const { error } = await supabase
    .from('profiles')
    .update({
      username: form.value.username,
      bio: form.value.bio.trim() || null,
      watch_region: form.value.watch_region
    })
    .eq('id', userId.value)

  saving.value = false

  if (error) {
    // 23505 = violation de contrainte unique (pseudo déjà utilisé)
    errorMessage.value = error.code === '23505' ? t('auth.usernameTaken') : t('settings.error')
    return
  }

  await loadProfile()
  form.value = fromProfile(profile.value)
  saved.value = true
}

const { getProviders } = useMovies()

const providers = ref<any[]>([])
const platforms = ref<number[]>([])
const loadingProviders = ref(false)
const platformError = ref('')

const loadPlatforms = async () => {
  if (!profile.value) return
  loadingProviders.value = true

  const [allProviders, { data }] = await Promise.all([
    getProviders(profile.value.watch_region),
    supabase.from('user_platforms').select('provider_id').eq('user_id', userId.value)
  ])

  providers.value = allProviders
  platforms.value = (data || []).map((p: any) => p.provider_id)
  loadingProviders.value = false
}

// Recharge la liste quand le pays enregistré change
watch(() => profile.value?.watch_region, loadPlatforms, { immediate: true })

const togglePlatform = async (providerId: number) => {
  platformError.value = ''
  const selected = platforms.value.includes(providerId)

  // Mise à jour immédiate de l'affichage, annulée si la base refuse
  platforms.value = selected
    ? platforms.value.filter(id => id !== providerId)
    : [...platforms.value, providerId]

  const { error } = selected
    ? await supabase.from('user_platforms').delete().eq('user_id', userId.value).eq('provider_id', providerId)
    : await supabase.from('user_platforms').insert({ user_id: userId.value, provider_id: providerId })

  if (error) {
    platforms.value = selected
      ? [...platforms.value, providerId]
      : platforms.value.filter(id => id !== providerId)
    platformError.value = t('settings.error')
  }
}
</script>

<style lang="scss" scoped>
.settings-page {
  max-width: 720px;
}

// Logo grisé tant que la plateforme n'est pas sélectionnée
.provider-btn {
  padding: 3px;
  border-radius: 0.8rem;
  border: 2px solid transparent;
  background: var(--bw-surface-2);

  img {
    display: block;
    border-radius: 0.6rem;
    opacity: 0.5;
    filter: grayscale(0.6);
    transition: opacity 0.15s ease, filter 0.15s ease;
  }

  &:hover img {
    opacity: 0.9;
    filter: none;
  }

  &[aria-pressed="true"] {
    border-color: var(--bw-accent);

    img {
      opacity: 1;
      filter: none;
    }
  }
}
</style>
