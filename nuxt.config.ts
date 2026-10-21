// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: ['@nuxtjs/supabase', '@nuxtjs/i18n'],

  i18n: {
    locales: [
      { code: 'en', iso: 'en-US', region: 'EN', name: 'English' },
      { code: 'fr', iso: 'fr-FR', region: 'FR', name: 'Français' },
      { code: 'es', iso: 'es-ES', region: 'ES', name: 'Español' }
    ],
    defaultLocale: 'en',
    strategy: 'prefix',
    vueI18n: './i18n.config.ts'
  },

  css: ['~/assets/scss/main.scss'],

  runtimeConfig: {
    tmdbReadAccessToken: process.env.TMDB_READ_ACCESS_TOKEN
  },

  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          quietDeps: true,
          silenceDeprecations: [
            'import',
            'if-function',
            'color-functions',
            'global-builtin',
            'mixed-decls'
          ]
        }
      }
    }
  },

  supabase: {
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      exclude: ['/*'],
    }
  }
})
