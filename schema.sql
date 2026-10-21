-- ==============================================================================
-- NETTOYAGE (DROP)
-- ==============================================================================
DROP TABLE IF EXISTS message_reactions CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS event_invitations CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS shared_watchlist_movies CASCADE;
DROP TABLE IF EXISTS shared_watchlist_members CASCADE;
DROP TABLE IF EXISTS shared_watchlists CASCADE;
DROP TABLE IF EXISTS personal_watchlist CASCADE; -- NOUVEAU
DROP TABLE IF EXISTS interactions CASCADE;
DROP TABLE IF EXISTS movie_logs CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS user_platforms CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS movie_cache CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- ==============================================================================
-- CRÉATION DES TABLES
-- ==============================================================================

-- Profils Utilisateurs (liés à l'authentification native Supabase)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Système d'Abonnement (Follows)
CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (follower_id, following_id)
);

-- Cache des Films (L'ID est l'identifiant officiel de l'API TMDB)
CREATE TABLE movie_cache (
  id BIGINT PRIMARY KEY,
  original_title TEXT NOT NULL, -- Le titre original inaltérable (ex: "The Dark Knight")
  localized_titles JSONB DEFAULT '{}'::jsonb, -- Stockage dynamique (ex: {"fr": "Le Chevalier Noir", "en": "The Dark Knight"})
  poster_path TEXT,
  release_year INTEGER
);

-- Préférences VOD des utilisateurs (Pour le filtre TMDB)
CREATE TABLE user_platforms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  provider_id INTEGER NOT NULL -- ID TMDB (ex: 8 pour Netflix)
);

-- Watchlist Personnelle (Les films "À voir")
CREATE TABLE personal_watchlist (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (user_id, movie_id)
);

-- Publications (Socle central du fil d'actualité)
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Journal de visionnage (Extension d'une publication, liée à un film)
CREATE TABLE movie_logs (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE PRIMARY KEY,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE CASCADE,
  rating SMALLINT CHECK (rating >= 0 AND rating <= 5),
  review_text TEXT,
  review_type TEXT CHECK (review_type IN ('SERIOUS', 'JOKE')),
  watch_date DATE
);

-- Interactions de la communauté (Commentaires et Likes sous un Post)
CREATE TABLE interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  interaction_type TEXT CHECK (interaction_type IN ('LIKE', 'COMMENT')) NOT NULL,
  content TEXT, -- Reste vide si le type est 'LIKE'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Watchlists Collaboratives (Entité principale)
CREATE TABLE shared_watchlists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Membres des Watchlists Collaboratives
CREATE TABLE shared_watchlist_members (
  watchlist_id UUID REFERENCES shared_watchlists(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (watchlist_id, user_id)
);

-- Contenu des Watchlists Collaboratives (Les films dans la liste)
CREATE TABLE shared_watchlist_movies (
  watchlist_id UUID REFERENCES shared_watchlists(id) ON DELETE CASCADE,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE CASCADE,
  added_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_watched BOOLEAN DEFAULT FALSE, -- Permet de cocher un film comme "vu" par le groupe
  added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (watchlist_id, movie_id)
);

-- Événements (Sorties ciné, soirées films IRL)
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE SET NULL, 
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Invitations aux événements
CREATE TABLE event_invitations (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  invitee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED')) DEFAULT 'PENDING',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (event_id, invitee_id)
);

-- Messagerie Privée (Direct Messages)
CREATE TABLE direct_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Réactions aux Messages Privés (Émojis)
CREATE TABLE message_reactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id UUID REFERENCES direct_messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  emoji_code TEXT NOT NULL, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (message_id, user_id, emoji_code) 
);