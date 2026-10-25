<template>
  <div class="container py-5">
    <div class="card signup-card shadow p-4 mx-auto">
      <h1 class="h3 text-center mb-1">{{ $t('auth.signupTitle') }}</h1>
      <p class="text-muted text-center small mb-4">{{ $t('auth.signupSubtitle') }}</p>

      <!-- Confirmation par e-mail activée : on prévient l'utilisateur -->
      <div v-if="emailSent" class="alert alert-success d-flex gap-2 small mb-0" role="status">
        <i class="bi bi-envelope-check" aria-hidden="true"></i>
        <span>{{ $t('auth.checkEmail', { email }) }}</span>
      </div>

      <form v-else novalidate @submit.prevent="signup">
        <div class="mb-3">
          <label for="signup-username" class="form-label">{{ $t('auth.username') }}</label>
          <input
            id="signup-username"
            v-model="username"
            type="text"
            class="form-control"
            :class="{ 'is-invalid': errors.username }"
            aria-describedby="signup-username-help"
            autocomplete="username"
            maxlength="30"
            required
          />
          <div id="signup-username-help" class="form-text" :class="{ 'text-danger': errors.username }">
            {{ errors.username || $t('auth.usernameHelp') }}
          </div>
        </div>

        <div class="mb-3">
          <label for="signup-email" class="form-label">{{ $t('auth.email') }}</label>
          <input
            id="signup-email"
            v-model="email"
            type="email"
            class="form-control"
            :class="{ 'is-invalid': errors.email }"
            aria-describedby="signup-email-error"
            autocomplete="email"
            required
          />
          <div v-if="errors.email" id="signup-email-error" class="invalid-feedback">{{ errors.email }}</div>
        </div>

        <div class="mb-4">
          <label for="signup-password" class="form-label">{{ $t('auth.password') }}</label>
          <input
            id="signup-password"
            v-model="password"
            type="password"
            class="form-control"
            :class="{ 'is-invalid': errors.password }"
            aria-describedby="signup-password-help"
            autocomplete="new-password"
            required
          />
          <div id="signup-password-help" class="form-text" :class="{ 'text-danger': errors.password }">
            {{ $t('auth.passwordHelp') }}
          </div>
        </div>

        <div v-if="errorMessage" class="alert alert-danger d-flex gap-2 py-2 small" role="alert">
          <i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>
          <span>{{ errorMessage }}</span>
        </div>

        <button type="submit" class="btn btn-primary w-100" :disabled="loading">
          <span v-if="loading" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
          {{ loading ? $t('auth.signingUp') : $t('auth.signup') }}
        </button>
      </form>

      <p class="text-center text-muted small mt-4 mb-0">
        {{ $t('auth.hasAccount') }}
        <NuxtLinkLocale to="/login" class="fw-semibold">{{ $t('auth.login') }}</NuxtLinkLocale>
      </p>
    </div>
  </div>
</template>

<script lang="ts" setup>
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const localePath = useLocalePath()
const { t } = useI18n()

useHead({ title: () => t('auth.signup') })

const username = ref('')
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')
const emailSent = ref(false)
const errors = reactive<{ username?: string; email?: string; password?: string }>({})

// Mêmes règles que la contrainte CHECK de la table profiles
const validate = () => {
  errors.username = /^[A-Za-z0-9_.]{3,30}$/.test(username.value) ? undefined : t('auth.usernameInvalid')
  errors.email = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value) ? undefined : t('auth.emailInvalid')
  errors.password = password.value.length >= 8 ? undefined : t('auth.passwordHelp')
}

const signup = async () => {
  errorMessage.value = ''
  validate()

  // Le visiteur n'a pas accès à la table profiles : on passe par la fonction username_available
  if (!errors.username) {
    const { data: available } = await supabase.rpc('username_available', { wanted: username.value })
    if (available === false) errors.username = t('auth.usernameTaken')
  }

  if (errors.username || errors.email || errors.password) return

  loading.value = true

  // Le trigger handle_new_user crée le profil à partir du pseudo passé dans les métadonnées
  const { data, error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
    options: {
      data: { username: username.value },
      emailRedirectTo: `${window.location.origin}${localePath('/')}`
    }
  })

  loading.value = false

  if (error) {
    errorMessage.value = error.message.toLowerCase().includes('rate limit')
      ? t('auth.rateLimited')
      : error.message
    return
  }

  // Sans session, Supabase attend la confirmation de l'e-mail
  if (!data.session) emailSent.value = true
}

// Si la confirmation par e-mail est désactivée, la session arrive directement
watch(user, (value) => {
  if (value) navigateTo(localePath('/'))
}, { immediate: true })
</script>

<style lang="scss" scoped>
.signup-card {
  max-width: 420px;
}
</style>
