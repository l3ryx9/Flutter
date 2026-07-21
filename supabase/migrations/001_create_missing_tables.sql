-- =====================================================================
-- YouMe — Migration 001 : Création des tables manquantes
-- Exécutez ce script dans Supabase > SQL Editor
-- Projet : kqgididioyztbtcddmhz
-- Date   : 2026-07-21
-- =====================================================================

-- ─── contacts ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.contacts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'active',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, contact_id)
);
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "contacts_select" ON public.contacts;
DROP POLICY IF EXISTS "contacts_all"    ON public.contacts;
CREATE POLICY "contacts_select" ON public.contacts
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = contact_id);
CREATE POLICY "contacts_all" ON public.contacts
  FOR ALL   USING (auth.uid() = user_id);

-- ─── contact_requests ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.contact_requests (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'pending',   -- pending | accepted | declined
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(sender_id, receiver_id)
);
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "req_select" ON public.contact_requests;
DROP POLICY IF EXISTS "req_insert" ON public.contact_requests;
DROP POLICY IF EXISTS "req_update" ON public.contact_requests;
CREATE POLICY "req_select" ON public.contact_requests
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "req_insert" ON public.contact_requests
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "req_update" ON public.contact_requests
  FOR UPDATE USING (auth.uid() = receiver_id);

-- ─── message_reactions ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji      TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reactions_select" ON public.message_reactions;
DROP POLICY IF EXISTS "reactions_all"    ON public.message_reactions;
CREATE POLICY "reactions_select" ON public.message_reactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.messages m
      JOIN public.conversations c ON c.id = m.conversation_id
      WHERE m.id = message_reactions.message_id
        AND auth.uid() = ANY(c.participant_ids)
    )
  );
CREATE POLICY "reactions_all" ON public.message_reactions
  FOR ALL USING (auth.uid() = user_id);

-- ─── ai_message_insights ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ai_message_insights (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  message_id       UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sentiment        TEXT,
  emotion          TEXT,
  key_phrases      TEXT[],
  behavioral_note  TEXT,
  analyzed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_message_insights ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "insights_select" ON public.ai_message_insights;
CREATE POLICY "insights_select" ON public.ai_message_insights
  FOR SELECT USING (auth.uid() = user_id);
-- Insertions uniquement via Edge Functions (service_role)

-- ─── conversation_analysis ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.conversation_analysis (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  summary          TEXT,
  relationship_score FLOAT DEFAULT 0.5,
  analyzed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.conversation_analysis ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "analysis_select" ON public.conversation_analysis;
CREATE POLICY "analysis_select" ON public.conversation_analysis
  FOR SELECT USING (auth.uid() = user_id);

-- ─── relationship_flags ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.relationship_flags (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type             TEXT NOT NULL,       -- 'green_flag' | 'red_flag'
  description      TEXT NOT NULL,
  message_quote    TEXT,
  severity         TEXT NOT NULL DEFAULT 'low',  -- 'low' | 'medium' | 'high' | 'critical'
  detected_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.relationship_flags ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "flags_select" ON public.relationship_flags;
CREATE POLICY "flags_select" ON public.relationship_flags
  FOR SELECT USING (auth.uid() = user_id);

-- ─── psychological_profiles ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.psychological_profiles (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id     UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  traits              TEXT[],
  general_tone        TEXT,
  recurring_topics    TEXT[],
  behavioral_advice   TEXT[],
  mood_score          FLOAT DEFAULT 0.5,
  possible_avoidance  BOOLEAN DEFAULT false,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);
ALTER TABLE public.psychological_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "psych_select" ON public.psychological_profiles;
CREATE POLICY "psych_select" ON public.psychological_profiles
  FOR SELECT USING (auth.uid() = user_id);

-- ─── daily_summaries ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_summaries (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id     UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  summary             TEXT,
  relationship_score  FLOAT DEFAULT 0.5,
  flags               JSONB DEFAULT '[]',
  highlighted_facts   TEXT[],
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id, date)
);
ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "summaries_select" ON public.daily_summaries;
CREATE POLICY "summaries_select" ON public.daily_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE id = daily_summaries.conversation_id
        AND auth.uid() = ANY(participant_ids)
    )
  );

-- ─── highlighted_facts ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.highlighted_facts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fact             TEXT NOT NULL,
  date             DATE NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.highlighted_facts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facts_select" ON public.highlighted_facts;
CREATE POLICY "facts_select" ON public.highlighted_facts
  FOR SELECT USING (auth.uid() = user_id);

-- ─── monthly_summaries ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.monthly_summaries (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id      UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  year                 INT NOT NULL,
  month                INT NOT NULL,
  summary              TEXT,
  highlights           TEXT[],
  relationship_trend   TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id, year, month)
);
ALTER TABLE public.monthly_summaries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "monthly_select" ON public.monthly_summaries;
CREATE POLICY "monthly_select" ON public.monthly_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE id = monthly_summaries.conversation_id
        AND auth.uid() = ANY(participant_ids)
    )
  );

-- ─── device_tokens ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  platform    TEXT DEFAULT 'android',   -- 'android' | 'ios'
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tokens_all" ON public.device_tokens;
CREATE POLICY "tokens_all" ON public.device_tokens
  FOR ALL USING (auth.uid() = user_id);

-- ─── live_locations ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.live_locations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude         FLOAT NOT NULL,
  longitude        FLOAT NOT NULL,
  accuracy         FLOAT,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id, user_id)
);
ALTER TABLE public.live_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "loc_select" ON public.live_locations;
DROP POLICY IF EXISTS "loc_upsert" ON public.live_locations;
CREATE POLICY "loc_select" ON public.live_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE id = live_locations.conversation_id
        AND auth.uid() = ANY(participant_ids)
    )
  );
CREATE POLICY "loc_upsert" ON public.live_locations
  FOR ALL USING (auth.uid() = user_id);

-- ─── bot_protection_logs ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bot_protection_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_hash    TEXT,
  event      TEXT NOT NULL,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.bot_protection_logs ENABLE ROW LEVEL SECURITY;
-- Aucune policy anon : seule la service_role peut y accéder
-- (Edge Function validate-bot insère via service_role)

-- ─── Vérification RLS sur tables existantes ──────────────────────────
-- S'assurer que profiles et messages ont bien RLS activé
ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Policies pour profiles (idempotent policy par policy)
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_public" ON public.profiles;

CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
-- Lecture publique des profils pour afficher les noms/avatars
CREATE POLICY "profiles_select_public" ON public.profiles
  FOR SELECT USING (true);

-- Policies pour messages
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
DROP POLICY IF EXISTS "messages_update_own" ON public.messages;

CREATE POLICY "messages_select" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE id = messages.conversation_id
        AND auth.uid() = ANY(participant_ids)
    )
  );
CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "messages_update_own" ON public.messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Policies pour conversations
DROP POLICY IF EXISTS "conv_select" ON public.conversations;
DROP POLICY IF EXISTS "conv_insert" ON public.conversations;
DROP POLICY IF EXISTS "conv_update" ON public.conversations;

CREATE POLICY "conv_select" ON public.conversations
  FOR SELECT USING (auth.uid() = ANY(participant_ids));
CREATE POLICY "conv_insert" ON public.conversations
  FOR INSERT WITH CHECK (auth.uid() = ANY(participant_ids));
CREATE POLICY "conv_update" ON public.conversations
  FOR UPDATE USING (auth.uid() = ANY(participant_ids));

-- ─── Index de performance ────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_ids
  ON public.conversations USING GIN(participant_ids);
CREATE INDEX IF NOT EXISTS idx_relationship_flags_conversation
  ON public.relationship_flags(conversation_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_conv_date
  ON public.daily_summaries(conversation_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user
  ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_live_locations_conversation
  ON public.live_locations(conversation_id, updated_at DESC);

-- =====================================================================
-- Migration terminée ✓
-- Vérifiez dans Supabase > Authentication > Policies que toutes les
-- tables affichent un verrou vert (RLS activé).
-- =====================================================================
