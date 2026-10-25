-- ==============================================================================
-- BETTERWATCHLIST - SCHÉMA SUPABASE
-- À exécuter en entier dans le SQL Editor de Supabase.
-- ATTENTION : le script supprime puis recrée toutes les tables (données perdues).
-- ==============================================================================

-- ==============================================================================
-- NETTOYAGE (DROP)
-- ==============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

DROP TABLE IF EXISTS import_jobs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS message_reactions CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS event_invitations CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS shared_watchlist_movies CASCADE;
DROP TABLE IF EXISTS shared_watchlist_members CASCADE;
DROP TABLE IF EXISTS shared_watchlists CASCADE;
DROP TABLE IF EXISTS personal_watchlist CASCADE;
DROP TABLE IF EXISTS interactions CASCADE;
DROP TABLE IF EXISTS movie_logs CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS user_platforms CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS movie_cache CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS generate_username(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS username_available(TEXT) CASCADE;
DROP FUNCTION IF EXISTS add_owner_as_member() CASCADE;
DROP FUNCTION IF EXISTS create_event(TEXT, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, BIGINT, UUID[]) CASCADE;
DROP FUNCTION IF EXISTS is_watchlist_member(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_watchlist_owner(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_event_creator(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_event_participant(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_message_participant(UUID) CASCADE;
DROP FUNCTION IF EXISTS notify(UUID, UUID, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS notify_on_follow() CASCADE;
DROP FUNCTION IF EXISTS notify_on_message() CASCADE;
DROP FUNCTION IF EXISTS notify_on_interaction() CASCADE;
DROP FUNCTION IF EXISTS notify_on_share() CASCADE;
DROP FUNCTION IF EXISTS notify_on_event_invitation() CASCADE;
DROP FUNCTION IF EXISTS notify_on_event_response() CASCADE;
DROP FUNCTION IF EXISTS notify_on_watchlist_member() CASCADE;

-- ==============================================================================
-- CRÉATION DES TABLES
-- ==============================================================================

-- Profils Utilisateurs (liés à l'authentification native Supabase, créés par trigger)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL CHECK (username ~ '^[A-Za-z0-9_.]{3,30}$'),
  avatar_url TEXT,
  bio TEXT CHECK (char_length(bio) <= 500),
  is_professional BOOLEAN DEFAULT FALSE NOT NULL, -- Profil pro (critique, réalisateur...), attribué par un admin
  preferred_language TEXT DEFAULT 'en' NOT NULL CHECK (preferred_language IN ('en', 'fr', 'es')),
  watch_region CHAR(2) DEFAULT 'FR' NOT NULL CHECK (watch_region ~ '^[A-Z]{2}$'), -- Pays utilisé pour le filtre VOD TMDB
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Système d'Abonnement (Follows)
CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id <> following_id) -- On ne peut pas se suivre soi-même
);

-- Cache des Films (L'ID est l'identifiant officiel de l'API TMDB)
CREATE TABLE movie_cache (
  id BIGINT PRIMARY KEY,
  original_title TEXT NOT NULL, -- Le titre original inaltérable (ex: "The Dark Knight")
  localized_titles JSONB DEFAULT '{}'::jsonb, -- Stockage dynamique (ex: {"fr": "Le Chevalier Noir", "en": "The Dark Knight"})
  poster_path TEXT,
  release_year INTEGER
);

-- Préférences VOD des utilisateurs (Pour le filtre TMDB, la région est dans profiles)
CREATE TABLE user_platforms (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  provider_id INTEGER NOT NULL CHECK (provider_id > 0), -- ID TMDB (ex: 8 pour Netflix)
  PRIMARY KEY (user_id, provider_id)
);

-- Watchlist Personnelle (Les films "À voir")
CREATE TABLE personal_watchlist (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE CASCADE,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (user_id, movie_id)
);

-- Publications (Socle central du fil d'actualité)
-- Un post est soit une critique (ligne dans movie_logs), soit un partage (shared_post_id renseigné)
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  shared_post_id UUID REFERENCES posts(id) ON DELETE CASCADE, -- Partage de la critique d'un autre utilisateur
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  CHECK (shared_post_id IS NULL OR shared_post_id <> id)
);

-- Journal de visionnage (Extension d'une publication, liée à un film)
CREATE TABLE movie_logs (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE PRIMARY KEY,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE CASCADE NOT NULL,
  rating SMALLINT CHECK (rating >= 0 AND rating <= 5),
  review_text TEXT,
  review_type TEXT NOT NULL CHECK (review_type IN ('SERIOUS', 'JOKE')), -- Tag obligatoire
  watch_date DATE
);

-- Interactions de la communauté (Likes, Commentaires et Réactions émoji sous un Post)
CREATE TABLE interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  interaction_type TEXT CHECK (interaction_type IN ('LIKE', 'COMMENT', 'REACTION')) NOT NULL,
  content TEXT, -- Uniquement pour 'COMMENT'
  emoji_code TEXT, -- Uniquement pour 'REACTION'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  CHECK (
    (interaction_type = 'LIKE' AND content IS NULL AND emoji_code IS NULL)
    OR (interaction_type = 'COMMENT' AND char_length(trim(content)) > 0 AND emoji_code IS NULL)
    OR (interaction_type = 'REACTION' AND emoji_code IS NOT NULL AND content IS NULL)
  )
);
-- Un seul like par utilisateur et par post, une seule fois le même émoji
CREATE UNIQUE INDEX interactions_one_like ON interactions (post_id, user_id) WHERE interaction_type = 'LIKE';
CREATE UNIQUE INDEX interactions_one_reaction ON interactions (post_id, user_id, emoji_code) WHERE interaction_type = 'REACTION';

-- Watchlists Collaboratives (Entité principale)
CREATE TABLE shared_watchlists (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL CHECK (char_length(trim(title)) > 0),
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Membres des Watchlists Collaboratives (le créateur y est ajouté automatiquement)
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
  is_watched BOOLEAN DEFAULT FALSE NOT NULL, -- Permet de cocher un film comme "vu" par le groupe
  added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (watchlist_id, movie_id)
);

-- Événements (Sorties ciné, soirées films IRL) - création via la fonction create_event()
CREATE TABLE events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL CHECK (char_length(trim(title)) > 0),
  event_type TEXT NOT NULL CHECK (event_type IN ('CINEMA', 'MOVIE_NIGHT')), -- "Sortie Ciné" ou "Soirée Film"
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  movie_id BIGINT REFERENCES movie_cache(id) ON DELETE SET NULL,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Invitations aux événements
CREATE TABLE event_invitations (
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  invitee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED')) DEFAULT 'PENDING' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (event_id, invitee_id)
);

-- Messagerie Privée (Direct Messages)
CREATE TABLE direct_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(trim(content)) > 0),
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  CHECK (sender_id <> receiver_id)
);

-- Réactions aux Messages Privés (Émojis)
CREATE TABLE message_reactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id UUID REFERENCES direct_messages(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  emoji_code TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (message_id, user_id, emoji_code)
);

-- Notifications (alimentées uniquement par les triggers ci-dessous)
-- entity_id pointe vers l'objet concerné selon le type (post, message, événement, watchlist)
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL, -- Destinataire
  actor_id UUID REFERENCES profiles(id) ON DELETE CASCADE, -- Auteur de l'action
  type TEXT NOT NULL CHECK (type IN (
    'NEW_FOLLOWER',
    'NEW_MESSAGE',
    'POST_LIKE',
    'POST_COMMENT',
    'POST_REACTION',
    'POST_SHARE',
    'EVENT_INVITATION',
    'EVENT_RESPONSE',
    'WATCHLIST_INVITATION'
  )),
  entity_id UUID,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Imports de Watchlist (suivi du Background Job qui traite le CSV)
-- Le fichier est déposé dans le bucket Storage "imports" sous "<user_id>/<fichier>.csv"
CREATE TABLE import_jobs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL DEFAULT auth.uid(),
  source TEXT NOT NULL CHECK (source IN ('LETTERBOXD', 'IMDB', 'TRAKT', 'CSV')),
  file_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
  total_rows INTEGER CHECK (total_rows >= 0),
  processed_rows INTEGER DEFAULT 0 NOT NULL CHECK (processed_rows >= 0),
  imported_rows INTEGER DEFAULT 0 NOT NULL CHECK (imported_rows >= 0),
  failed_rows INTEGER DEFAULT 0 NOT NULL CHECK (failed_rows >= 0),
  errors JSONB DEFAULT '[]'::jsonb NOT NULL, -- Détail des lignes en échec (ex: [{"line": 12, "reason": "Film introuvable"}])
  error_message TEXT, -- Erreur globale si le job échoue
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  started_at TIMESTAMP WITH TIME ZONE,
  finished_at TIMESTAMP WITH TIME ZONE
);

-- ==============================================================================
-- INDEX
-- ==============================================================================
CREATE INDEX follows_following_idx ON follows (following_id);
CREATE INDEX posts_feed_idx ON posts (user_id, created_at DESC);
CREATE INDEX posts_shared_post_idx ON posts (shared_post_id) WHERE shared_post_id IS NOT NULL;
CREATE INDEX movie_logs_movie_idx ON movie_logs (movie_id);
CREATE INDEX interactions_post_idx ON interactions (post_id, created_at);
CREATE INDEX shared_watchlist_members_user_idx ON shared_watchlist_members (user_id);
CREATE INDEX event_invitations_invitee_idx ON event_invitations (invitee_id);
CREATE INDEX direct_messages_conversation_idx ON direct_messages (LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id), created_at DESC);
CREATE INDEX direct_messages_receiver_idx ON direct_messages (receiver_id) WHERE read_at IS NULL;
CREATE INDEX message_reactions_message_idx ON message_reactions (message_id);
CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);
CREATE INDEX import_jobs_pending_idx ON import_jobs (created_at) WHERE status = 'PENDING';

-- ==============================================================================
-- CRÉATION AUTOMATIQUE DU PROFIL À L'INSCRIPTION
-- ==============================================================================

-- Renvoie le pseudo souhaité s'il est valide et libre, sinon un pseudo généré (user_xxxxxxxxxxxx)
CREATE FUNCTION generate_username(user_id UUID, wanted TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF wanted ~ '^[A-Za-z0-9_.]{3,30}$'
     AND NOT EXISTS (SELECT 1 FROM profiles WHERE lower(username) = lower(wanted)) THEN
    RETURN wanted;
  END IF;
  RETURN 'user_' || substr(replace(user_id::text, '-', ''), 1, 12);
END;
$$;

CREATE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    generate_username(NEW.id, NEW.raw_user_meta_data->>'username'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

REVOKE EXECUTE ON FUNCTION generate_username(UUID, TEXT) FROM PUBLIC, anon, authenticated;

-- Vérification du pseudo sur la page d'inscription (le visiteur n'a pas encore accès à profiles)
CREATE FUNCTION username_available(wanted TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (SELECT 1 FROM profiles WHERE lower(username) = lower(wanted));
$$;

GRANT EXECUTE ON FUNCTION username_available(TEXT) TO anon, authenticated;

-- Les comptes déjà existants récupèrent un profil (utile quand on relance ce script)
INSERT INTO profiles (id, username)
SELECT id, generate_username(id, raw_user_meta_data->>'username')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Le créateur d'une watchlist collaborative en devient automatiquement membre
CREATE FUNCTION add_owner_as_member()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO shared_watchlist_members (watchlist_id, user_id) VALUES (NEW.id, NEW.created_by);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_shared_watchlist_created
  AFTER INSERT ON shared_watchlists
  FOR EACH ROW EXECUTE FUNCTION add_owner_as_member();

-- ==============================================================================
-- NOTIFICATIONS (TRIGGERS)
-- ==============================================================================

-- Insère une notification, sauf si l'utilisateur agit sur son propre contenu
CREATE FUNCTION notify(recipient UUID, actor UUID, notif_type TEXT, entity UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF recipient IS NOT NULL AND recipient IS DISTINCT FROM actor THEN
    INSERT INTO notifications (user_id, actor_id, type, entity_id) VALUES (recipient, actor, notif_type, entity);
  END IF;
END;
$$;

CREATE FUNCTION notify_on_follow()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM notify(NEW.following_id, NEW.follower_id, 'NEW_FOLLOWER', NULL);
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM notify(NEW.receiver_id, NEW.sender_id, 'NEW_MESSAGE', NEW.id);
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_interaction()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM notify(
    (SELECT user_id FROM posts WHERE id = NEW.post_id),
    NEW.user_id,
    'POST_' || NEW.interaction_type, -- POST_LIKE, POST_COMMENT, POST_REACTION
    NEW.post_id
  );
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_share()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.shared_post_id IS NOT NULL THEN
    PERFORM notify((SELECT user_id FROM posts WHERE id = NEW.shared_post_id), NEW.user_id, 'POST_SHARE', NEW.id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_event_invitation()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM notify(NEW.invitee_id, (SELECT created_by FROM events WHERE id = NEW.event_id), 'EVENT_INVITATION', NEW.event_id);
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_event_response()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status <> 'PENDING' THEN
    PERFORM notify((SELECT created_by FROM events WHERE id = NEW.event_id), NEW.invitee_id, 'EVENT_RESPONSE', NEW.event_id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE FUNCTION notify_on_watchlist_member()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM notify(NEW.user_id, (SELECT created_by FROM shared_watchlists WHERE id = NEW.watchlist_id), 'WATCHLIST_INVITATION', NEW.watchlist_id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_follow_notify AFTER INSERT ON follows FOR EACH ROW EXECUTE FUNCTION notify_on_follow();
CREATE TRIGGER on_message_notify AFTER INSERT ON direct_messages FOR EACH ROW EXECUTE FUNCTION notify_on_message();
CREATE TRIGGER on_interaction_notify AFTER INSERT ON interactions FOR EACH ROW EXECUTE FUNCTION notify_on_interaction();
CREATE TRIGGER on_share_notify AFTER INSERT ON posts FOR EACH ROW EXECUTE FUNCTION notify_on_share();
CREATE TRIGGER on_event_invitation_notify AFTER INSERT ON event_invitations FOR EACH ROW EXECUTE FUNCTION notify_on_event_invitation();
CREATE TRIGGER on_event_response_notify AFTER UPDATE OF status ON event_invitations FOR EACH ROW EXECUTE FUNCTION notify_on_event_response();
CREATE TRIGGER on_watchlist_member_notify AFTER INSERT ON shared_watchlist_members FOR EACH ROW EXECUTE FUNCTION notify_on_watchlist_member();

-- La fonction notify() ne doit être appelée que par les triggers
REVOKE EXECUTE ON FUNCTION notify(UUID, UUID, TEXT, UUID) FROM PUBLIC, anon, authenticated;

-- ==============================================================================
-- FONCTIONS UTILITAIRES POUR LA RLS
-- SECURITY DEFINER : évite la récursion infinie quand une policy lit une autre table protégée
-- ==============================================================================
CREATE FUNCTION is_watchlist_member(wid UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM shared_watchlist_members WHERE watchlist_id = wid AND user_id = auth.uid());
$$;

CREATE FUNCTION is_watchlist_owner(wid UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM shared_watchlists WHERE id = wid AND created_by = auth.uid());
$$;

CREATE FUNCTION is_event_creator(eid UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM events WHERE id = eid AND created_by = auth.uid());
$$;

CREATE FUNCTION is_event_participant(eid UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT is_event_creator(eid)
    OR EXISTS (SELECT 1 FROM event_invitations WHERE event_id = eid AND invitee_id = auth.uid());
$$;

CREATE FUNCTION is_message_participant(mid UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM direct_messages
    WHERE id = mid AND auth.uid() IN (sender_id, receiver_id)
  );
$$;

-- ==============================================================================
-- CRÉATION D'ÉVÉNEMENT (RPC)
-- Seul moyen de créer un événement : garantit au moins 3 invités dans la même transaction.
-- Appel côté front : supabase.rpc('create_event', { p_title, p_event_type, p_event_date, p_location, p_movie_id, p_invitee_ids })
-- ==============================================================================
CREATE FUNCTION create_event(
  p_title TEXT,
  p_event_type TEXT,
  p_event_date TIMESTAMP WITH TIME ZONE,
  p_location TEXT,
  p_movie_id BIGINT,
  p_invitee_ids UUID[]
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_event_id UUID;
  invitees UUID[];
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentification requise';
  END IF;

  IF p_event_date <= now() THEN
    RAISE EXCEPTION 'La date de l''événement doit être dans le futur';
  END IF;

  -- Dédoublonnage et retrait du créateur de la liste des invités
  SELECT array_agg(DISTINCT i) INTO invitees
  FROM unnest(p_invitee_ids) AS i
  WHERE i IS NOT NULL AND i <> auth.uid();

  IF coalesce(array_length(invitees, 1), 0) < 3 THEN
    RAISE EXCEPTION 'Un événement doit avoir au moins 3 invités';
  END IF;

  INSERT INTO events (title, event_type, event_date, location, movie_id, created_by)
  VALUES (p_title, p_event_type, p_event_date, p_location, p_movie_id, auth.uid())
  RETURNING id INTO new_event_id;

  INSERT INTO event_invitations (event_id, invitee_id)
  SELECT new_event_id, unnest(invitees);

  RETURN new_event_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION create_event(TEXT, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, BIGINT, UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_event(TEXT, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, BIGINT, UUID[]) TO authenticated;

-- ==============================================================================
-- ROW LEVEL SECURITY
-- Le service_role (utilisé côté serveur Nitro et par le Background Job) contourne la RLS.
-- ==============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_watchlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_watchlist_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_watchlist_movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_jobs ENABLE ROW LEVEL SECURITY;

-- Colonnes modifiables par les utilisateurs (le reste est protégé : id, is_professional, statuts...)
REVOKE UPDATE ON profiles, shared_watchlist_movies, event_invitations, direct_messages, notifications FROM anon, authenticated;
GRANT UPDATE (username, avatar_url, bio, preferred_language, watch_region) ON profiles TO authenticated;
GRANT UPDATE (is_watched) ON shared_watchlist_movies TO authenticated;
GRANT UPDATE (status) ON event_invitations TO authenticated;
GRANT UPDATE (read_at) ON direct_messages TO authenticated;
GRANT UPDATE (read_at) ON notifications TO authenticated;
REVOKE INSERT, UPDATE ON import_jobs FROM anon, authenticated;
GRANT INSERT (user_id, source, file_path) ON import_jobs TO authenticated;

-- PROFILS : publics pour les utilisateurs connectés, modifiables par leur propriétaire
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- FOLLOWS : graphe social public, chacun gère ses propres abonnements
CREATE POLICY "follows_select" ON follows FOR SELECT TO authenticated USING (true);
CREATE POLICY "follows_insert_own" ON follows FOR INSERT TO authenticated WITH CHECK (follower_id = auth.uid());
CREATE POLICY "follows_delete_own" ON follows FOR DELETE TO authenticated USING (follower_id = auth.uid());

-- MOVIE_CACHE : lecture pour tous, écriture uniquement par le serveur (service_role)
CREATE POLICY "movie_cache_select" ON movie_cache FOR SELECT TO anon, authenticated USING (true);

-- USER_PLATFORMS : visibles sur le profil, gérées par leur propriétaire
CREATE POLICY "user_platforms_select" ON user_platforms FOR SELECT TO authenticated USING (true);
CREATE POLICY "user_platforms_insert_own" ON user_platforms FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "user_platforms_delete_own" ON user_platforms FOR DELETE TO authenticated USING (user_id = auth.uid());

-- WATCHLIST PERSONNELLE : consultable par les autres membres, gérée par son propriétaire
CREATE POLICY "personal_watchlist_select" ON personal_watchlist FOR SELECT TO authenticated USING (true);
CREATE POLICY "personal_watchlist_insert_own" ON personal_watchlist FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "personal_watchlist_delete_own" ON personal_watchlist FOR DELETE TO authenticated USING (user_id = auth.uid());

-- POSTS : publics, créés et supprimés par leur auteur
CREATE POLICY "posts_select" ON posts FOR SELECT TO authenticated USING (true);
CREATE POLICY "posts_insert_own" ON posts FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "posts_delete_own" ON posts FOR DELETE TO authenticated USING (user_id = auth.uid());

-- MOVIE_LOGS : publics, gérés par l'auteur du post associé
CREATE POLICY "movie_logs_select" ON movie_logs FOR SELECT TO authenticated USING (true);
CREATE POLICY "movie_logs_insert_own" ON movie_logs FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid()));
CREATE POLICY "movie_logs_update_own" ON movie_logs FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid()));
CREATE POLICY "movie_logs_delete_own" ON movie_logs FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM posts WHERE id = post_id AND user_id = auth.uid()));

-- INTERACTIONS : publiques, chacun gère ses likes / commentaires / réactions
CREATE POLICY "interactions_select" ON interactions FOR SELECT TO authenticated USING (true);
CREATE POLICY "interactions_insert_own" ON interactions FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "interactions_update_own" ON interactions FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "interactions_delete_own" ON interactions FOR DELETE TO authenticated USING (user_id = auth.uid());

-- WATCHLISTS COLLABORATIVES : visibles et modifiables uniquement par leurs membres
CREATE POLICY "shared_watchlists_select_members" ON shared_watchlists FOR SELECT TO authenticated
  USING (created_by = auth.uid() OR is_watchlist_member(id));
CREATE POLICY "shared_watchlists_insert_own" ON shared_watchlists FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "shared_watchlists_update_owner" ON shared_watchlists FOR UPDATE TO authenticated
  USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());
CREATE POLICY "shared_watchlists_delete_owner" ON shared_watchlists FOR DELETE TO authenticated USING (created_by = auth.uid());

-- Le créateur ajoute ou retire des membres, un membre peut quitter la liste
CREATE POLICY "shared_watchlist_members_select" ON shared_watchlist_members FOR SELECT TO authenticated
  USING (is_watchlist_member(watchlist_id));
CREATE POLICY "shared_watchlist_members_insert_owner" ON shared_watchlist_members FOR INSERT TO authenticated
  WITH CHECK (is_watchlist_owner(watchlist_id));
CREATE POLICY "shared_watchlist_members_delete" ON shared_watchlist_members FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR is_watchlist_owner(watchlist_id));

-- Chaque membre peut ajouter des films et les cocher comme vus
CREATE POLICY "shared_watchlist_movies_select" ON shared_watchlist_movies FOR SELECT TO authenticated
  USING (is_watchlist_member(watchlist_id));
CREATE POLICY "shared_watchlist_movies_insert" ON shared_watchlist_movies FOR INSERT TO authenticated
  WITH CHECK (is_watchlist_member(watchlist_id) AND added_by = auth.uid());
CREATE POLICY "shared_watchlist_movies_update" ON shared_watchlist_movies FOR UPDATE TO authenticated
  USING (is_watchlist_member(watchlist_id)) WITH CHECK (is_watchlist_member(watchlist_id));
CREATE POLICY "shared_watchlist_movies_delete" ON shared_watchlist_movies FOR DELETE TO authenticated
  USING (is_watchlist_member(watchlist_id) AND (added_by = auth.uid() OR is_watchlist_owner(watchlist_id)));

-- ÉVÉNEMENTS : visibles par le créateur et les invités uniquement (création via create_event())
CREATE POLICY "events_select_participants" ON events FOR SELECT TO authenticated USING (is_event_participant(id));
CREATE POLICY "events_update_creator" ON events FOR UPDATE TO authenticated
  USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());
CREATE POLICY "events_delete_creator" ON events FOR DELETE TO authenticated USING (created_by = auth.uid());

-- INVITATIONS : le créateur invite ou retire, l'invité répond (colonne status uniquement)
CREATE POLICY "event_invitations_select_participants" ON event_invitations FOR SELECT TO authenticated
  USING (is_event_participant(event_id));
CREATE POLICY "event_invitations_insert_creator" ON event_invitations FOR INSERT TO authenticated
  WITH CHECK (is_event_creator(event_id) AND invitee_id <> auth.uid());
CREATE POLICY "event_invitations_update_invitee" ON event_invitations FOR UPDATE TO authenticated
  USING (invitee_id = auth.uid()) WITH CHECK (invitee_id = auth.uid());
CREATE POLICY "event_invitations_delete_creator" ON event_invitations FOR DELETE TO authenticated
  USING (is_event_creator(event_id));

-- MESSAGES PRIVÉS : lisibles uniquement par l'expéditeur et le destinataire
CREATE POLICY "direct_messages_select_participants" ON direct_messages FOR SELECT TO authenticated
  USING (auth.uid() IN (sender_id, receiver_id));
CREATE POLICY "direct_messages_insert_sender" ON direct_messages FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());
-- Seul le destinataire marque le message comme lu (colonne read_at uniquement)
CREATE POLICY "direct_messages_update_receiver" ON direct_messages FOR UPDATE TO authenticated
  USING (receiver_id = auth.uid()) WITH CHECK (receiver_id = auth.uid());
CREATE POLICY "direct_messages_delete_sender" ON direct_messages FOR DELETE TO authenticated
  USING (sender_id = auth.uid());

-- RÉACTIONS AUX MESSAGES : réservées aux deux participants de la conversation
CREATE POLICY "message_reactions_select_participants" ON message_reactions FOR SELECT TO authenticated
  USING (is_message_participant(message_id));
CREATE POLICY "message_reactions_insert_own" ON message_reactions FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND is_message_participant(message_id));
CREATE POLICY "message_reactions_delete_own" ON message_reactions FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- NOTIFICATIONS : chacun ne voit que les siennes (créées par les triggers uniquement)
CREATE POLICY "notifications_select_own" ON notifications FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications_delete_own" ON notifications FOR DELETE TO authenticated USING (user_id = auth.uid());

-- IMPORTS : l'utilisateur crée et suit ses jobs, seul le Background Job (service_role) les met à jour
CREATE POLICY "import_jobs_select_own" ON import_jobs FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "import_jobs_insert_own" ON import_jobs FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND file_path LIKE auth.uid()::text || '/%');

-- ==============================================================================
-- STORAGE : BUCKET PRIVÉ POUR LES FICHIERS CSV D'IMPORT
-- Chaque utilisateur ne peut écrire et lire que dans son dossier "<user_id>/"
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('imports', 'imports', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "imports_insert_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "imports_select_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "imports_delete_own_folder" ON storage.objects;

CREATE POLICY "imports_insert_own_folder" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'imports' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "imports_select_own_folder" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'imports' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "imports_delete_own_folder" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'imports' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ==============================================================================
-- STORAGE : BUCKET PUBLIC POUR LES AVATARS
-- Lecture publique (URL directe), écriture uniquement dans son dossier "<user_id>/"
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "avatars_insert_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "avatars_update_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete_own_folder" ON storage.objects;
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;

CREATE POLICY "avatars_select" ON storage.objects FOR SELECT TO anon, authenticated
  USING (bucket_id = 'avatars');
CREATE POLICY "avatars_insert_own_folder" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "avatars_update_own_folder" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "avatars_delete_own_folder" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ==============================================================================
-- REALTIME : messagerie, réactions et notifications en direct
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE direct_messages, message_reactions, notifications, import_jobs;
