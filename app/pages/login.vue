<template>
  <div class="container py-5">
    <div class="card login-card shadow p-4 mx-auto">
      <h1 class="h3 text-center mb-1">{{ $t('auth.loginTitle') }}</h1>
      <p class="text-muted text-center small mb-4">{{ $t('auth.loginSubtitle') }}</p>

      <form @submit.prevent="login">
        <div class="mb-3">
          <label for="login-email" class="form-label">{{ $t('auth.email') }}</label>
          <input
            id="login-email"
            v-model="email"
            type="email"
            class="form-control"
            autocomplete="email"
            required
          />
        </div>

        <div class="mb-4">
          <label for="login-password" class="form-label">{{ $t('auth.password') }}</label>
          <input
            id="login-password"
            v-model="password"
            type="password"
            class="form-control"
            autocomplete="current-password"
            required
          />
        </div>

        <div v-if="errorMessage" class="alert alert-danger d-flex gap-2 py-2 small" role="alert">
          <i class="bi bi-exclamation-triangle-fill" aria-hidden="true"></i>
          <span>{{ errorMessage }}</span>
        </div>

        <button type="submit" class="btn btn-primary w-100" :disabled="loading">
          <span v-if="loading" class="spinner-border spinner-border-sm" aria-hidden="true"></span>
          {{ loading ? $t('auth.loggingIn') : $t('auth.login') }}
        </button>
      </form>

      <p class="text-center text-muted small mt-4 mb-0">
        {{ $t('auth.noAccount') }}
        <NuxtLinkLocale to="/signup" class="fw-semibold">{{ $t('auth.signup') }}</NuxtLinkLocale>
      </p>
    </div>
  </div>
</template>

<script lang="ts" setup>
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const localePath = useLocalePath()
const { t } = useI18n()

useHead({ title: () => t('auth.login') })

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

const login = async () => {
  loading.value = true
  errorMessage.value = ''

  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })

  loading.value = false

  if (error) {
    // Message générique : on ne révèle pas si l'e-mail existe ou non
    errorMessage.value = error.message.toLowerCase().includes('confirm')
      ? t('auth.emailNotConfirmed')
      : t('auth.invalidCredentials')
  }
}

// Dès que la session existe (connexion réussie ou déjà connecté), retour à l'accueil
watch(user, (value) => {
  if (value) navigateTo(localePath('/'))
}, { immediate: true })
</script>

<style lang="scss" scoped>
.login-card {
  max-width: 420px;
}
</style>
