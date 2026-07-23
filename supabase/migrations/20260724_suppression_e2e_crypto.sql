-- ══════════════════════════════════════════════════════════════════════════════
-- Suppression de la colonne e2e_public_key (chiffrement de bout en bout)
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Contexte : `E2ECryptoService` générait des paires de clés X25519 à
-- l'inscription/connexion et publiait la clé publique dans cette colonne,
-- mais aucun code d'envoi ou de réception de message n'appelait jamais
-- `.encrypt()`/`.decrypt()` avec ces clés — les messages ont toujours été
-- stockés et lus en clair côté serveur. Le service et ses colonnes créaient
-- une fausse impression de chiffrement de bout en bout : ils sont retirés
-- entièrement. La confidentialité réelle du service repose maintenant sur
-- le consentement explicite décrit dans consent.tsx (voir aussi
-- 20260724_consentement_analyse_ia.sql), qui indique clairement qu'il n'y
-- a pas de chiffrement de bout en bout.

alter table if exists public.users
  drop column if exists e2e_public_key;

alter table if exists public.public_profiles
  drop column if exists e2e_public_key;
