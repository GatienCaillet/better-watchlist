*Read this in other languages: [Français](README.fr.md) | [Español](README.es.md)*

# BetterWatchlist

BetterWatchlist is a web application designed to bridge the gap between a movie database and a social network. 

The goal of the project is to allow users to search for movies, manage their Watchlist, rate them, and interact with other users.

## Tech Stack

To run all of this, we rely on:
- Framework: Nuxt 4 (with Vue.js 3)
- Styling: Bootstrap 5 (integrated via SCSS for full customization)
- Backend & DB: Supabase (PostgreSQL)
- Movie API: TMDB API (The Movie Database)
- Multilingual: i18n (FR, EN, ES)

---

## Local Installation and Setup

Before cloning the project, make sure you have Node.js installed on your machine.

1. Clone the project and install dependencies:
```bash
git clone git@github.com:GatienCaillet/better-watchlist.git
cd better-watchlist
npm install
```

2. Initialize the Supabase database:
- To test the application locally, you need to set up your own Supabase project.
- Create a new project on your Supabase account.
- Go to the "SQL Editor" section of your Supabase dashboard.
- Open the `schema.sql` file included in the project. It contains our entire database architecture (profiles, posts, collaborative watchlists, messaging, etc.).
- Copy and paste the entire content of this file into the Supabase SQL editor and click "Run" to generate the tables.

3. Manage environment variables:
- Create a `.env` file at the root of the project.
- Copy the structure below and ask for any missing keys on our communication channel. 
Warning: never commit API keys directly into the code.

```env
# Supabase (https://supabase.com/dashboard/project/<<PROJECT_ID>>/settings/api-keys?showConnect=true&connectTab=framework)
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_supabase_secret_key

# TMDB (https://www.themoviedb.org/settings/api)
TMDB_READ_ACCESS_TOKEN=your_tmdb_token_here
```

4. Start the development server:
```bash
npm run dev
```
The site will then be accessible at http://localhost:3000/.

If you modify the Nuxt configuration file or the translations, you might need to clean and prepare the project:
```bash
npx nuxi cleanup
npx nuxi prepare
```