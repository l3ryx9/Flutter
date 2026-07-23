-- ══════════════════════════════════════════════════════════════════════════════
-- Consentement explicite à l'analyse IA des conversations
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Contexte : les messages ne sont pas chiffrés de bout en bout (le serveur
-- peut les lire) et sont analysés par une IA (Gemini) pour produire la
-- jauge red/green flags, les profils psychologiques et les résumés
-- quotidiens. `ai_enabled` (colonne existante) permet de couper l'analyse
-- au fil de l'eau depuis les paramètres, mais ne constitue pas en soi une
-- preuve de consentement éclairé au moment de l'inscription.
--
-- Ces colonnes tracent CE consentement précis : quand il a été donné, et
-- sur quelle version du texte présenté (pour pouvoir prouver ce qui a été
-- réellement affiché à la personne si le texte évolue plus tard).

alter table if exists public.users
  add column if not exists analysis_consent_at      timestamptz,
  add column if not exists analysis_consent_version  text;

comment on column public.users.analysis_consent_at is
  'Horodatage du consentement explicite (case cochée à l''inscription) à l''analyse IA et au stockage des conversations. NULL = jamais consenti explicitement (compte créé avant l''introduction de ce consentement, ou consentement non enregistré).';

comment on column public.users.analysis_consent_version is
  'Identifiant de la version du texte de consentement présenté (ex: "2026-07-24"), pour pouvoir retrouver le texte exact accepté si celui-ci change ultérieurement.';
