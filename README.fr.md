*Lire dans d'autres langues : [English](README.md) | [Español](README.es.md)*
# BetterWatchlist

BetterWatchlist est une application web conçue pour être à mi-chemin entre 
une base de données de cinéma et un réseau social. 

L'objectif du projet est de permettre aux utilisateurs de chercher des films, 
de gérer leur Watchlist, de les noter, et d'intéragir avec les autres utilisateurs.

## Stack Technique

Pour faire tourner tout ça, nous nous appuyons sur :
- Framework : Nuxt 4 (avec Vue.js 3)
- Style : Bootstrap 5 (intégré via SCSS pour une personnalisation complète)
- Backend & BDD : Supabase (PostgreSQL)
- API Cinéma : TMDB API (The Movie Database)
- Multilingue : i18n (FR, EN, ES)

---

## Installation et démarrage en local

Avant de cloner le projet, assurez-vous d'avoir Node.js installé sur votre machine.

1. Récupérer le projet et installer les dépendances :
```bash
git clone git@github.com:GatienCaillet/better-watchlist.git
cd better-watchlist
npm install
```

2. Initialiser la base de données Supabase :
- Pour pouvoir tester l'application en local, vous devez configurer votre propre projet Supabase.
- Créez un nouveau projet sur votre compte Supabase.
- Rendez-vous dans la section "SQL Editor" de votre tableau de bord Supabase.
- Ouvrez le fichier schema.sql présent dans le projet. Il contient toute l'architecture de notre base de données (profils, posts, watchlists collaboratives, messagerie, etc.).
- Copiez-collez tout le contenu de ce fichier dans l'éditeur SQL de Supabase et cliquez sur "Run" pour générer les tables.

3. Gérer les variables d'environnement :
- Créez un fichier .env à la racine du projet. 
- Copiez-y la structure ci-dessous et demandez les clés manquantes sur notre 
canal de discussion. 
Attention : ne mettez jamais les clés d'API directement dans le code.

```env
# Supabase ([https://supabase.com/dashboard/project/](https://supabase.com/dashboard/project/)<<PROJECT_ID>>/settings/api-keys?showConnect=true&connectTab=framework)
SUPABASE_URL=votre_url_supabase
SUPABASE_KEY=votre_cle_anon_supabase
SUPABASE_SERVICE_KEY=votre_cle_secrete_supabase

# TMDB ([https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api))
TMDB_READ_ACCESS_TOKEN=votre_token_tmdb_ici
```

4. Lancer le serveur de développement :
```bash
npm run dev
```
Le site sera alors accessible sur http://localhost:3000/.

Si vous touchez au fichier de configuration de Nuxt ou aux traductions, vous devrez peut-être nettoyer et préparer le projet :
```bash
npx nuxi cleanup
npx nuxi prepare
```