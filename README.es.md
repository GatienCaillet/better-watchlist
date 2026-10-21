*Leer en otros idiomas: [English](README.md) | [Français](README.fr.md)*

# BetterWatchlist

BetterWatchlist es una aplicación web diseñada para estar a medio camino entre una base de datos de cine y una red social. 

El objetivo del proyecto es permitir a los usuarios buscar películas, gestionar su Watchlist, puntuarlas e interactuar con otros usuarios.

## Stack Técnico

Para hacer funcionar todo esto, nos apoyamos en:
- Framework: Nuxt 4 (con Vue.js 3)
- Estilos: Bootstrap 5 (integrado vía SCSS para una personalización completa)
- Backend y BD: Supabase (PostgreSQL)
- API de Cine: TMDB API (The Movie Database)
- Multilingüe: i18n (FR, EN, ES)

---

## Instalación y despliegue local

Antes de clonar el proyecto, asegúrate de tener Node.js instalado en tu equipo.

1. Obtener el proyecto e instalar las dependencias:
```bash
git clone git@github.com:GatienCaillet/better-watchlist.git
cd better-watchlist
npm install
```

2. Inicializar la base de datos Supabase:
- Para poder probar la aplicación en local, debes configurar tu propio proyecto Supabase.
- Crea un nuevo proyecto en tu cuenta de Supabase.
- Ve a la sección "SQL Editor" de tu panel de control de Supabase.
- Abre el archivo `schema.sql` incluido en el proyecto. Contiene toda la arquitectura de nuestra base de datos (perfiles, posts, watchlists colaborativas, mensajería, etc.).
- Copia y pega todo el contenido de este archivo en el editor SQL de Supabase y haz clic en "Run" para generar las tablas.

3. Gestionar las variables de entorno:
- Crea un archivo `.env` en la raíz del proyecto. 
- Copia la estructura a continuación y pide las claves que falten en nuestro canal de comunicación. 
Atención: nunca pongas las claves de API directamente en el código.

```env
# Supabase ([https://supabase.com/dashboard/project/](https://supabase.com/dashboard/project/)<<PROJECT_ID>>/settings/api-keys?showConnect=true&connectTab=framework)
SUPABASE_URL=tu_url_supabase
SUPABASE_KEY=tu_clave_anon_supabase

# TMDB ([https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api))
TMDB_READ_ACCESS_TOKEN=tu_token_tmdb_aqui
```

4. Iniciar el servidor de desarrollo:
```bash
npm run dev
```
El sitio estará accesible en http://localhost:3000/.

Si modificas el archivo de configuración de Nuxt o las traducciones, es posible que necesites limpiar y preparar el proyecto:
```bash
npx nuxi cleanup
npx nuxi prepare
```