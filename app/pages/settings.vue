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
  </div>
</template>

<script lang="ts" setup>
definePageMeta({ middleware: 'auth' })

const supabase = useSupabaseClient()
const { t } = useI18n()
const { userId, profile, loadProfile } = useCurrentUser()

useHead({ title: () => t('settings.title') })

const form = ref<{ username: string; bio: string } | null>(null)
const saving = ref(false)
const saved = ref(false)
const errorMessage = ref('')

const fromProfile = (value: any) => ({
  username: value.username,
  bio: value.bio || ''
})

// Copie du profil dans le formulaire une fois chargé
watch(profile, (value) => {
  if (value && !form.value) form.value = fromProfile(value)
}, { immediate: true })

const dirty = computed(() => {
  if (!form.value || !profile.value) return false
  const original = fromProfile(profile.value)
  return form.value.username !== original.username || form.value.bio !== original.bio
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
      bio: form.value.bio.trim() || null
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
</script>

<style lang="scss" scoped>
.settings-page {
  max-width: 720px;
}
</style>
