-- ══════════════════════════════════════════════════════════════════════════════
-- Suppression du mode furtif (localisation cachée d'un partenaire à son insu)
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Contexte : `stealth_tracking` permettait à un utilisateur d'activer un
-- suivi de position continu sur son partenaire, sans notification ni
-- consentement affiché côté personne suivie, avec déclenchement spécifique
-- quand l'app de la cible était en arrière-plan. `location_requests`
-- servait à forcer à distance une mise à jour de position via push FCM,
-- pour ce même mécanisme. Les deux sont supprimés : le seul partage de
-- position qui subsiste dans l'app est celui explicitement activé par la
-- personne qui partage sa propre position (`location_shares`, sans lien
-- avec le mode furtif).
--
-- Cette migration est irréversible pour les lignes existantes de ces deux
-- tables (elles sont supprimées, pas seulement désactivées) : si un mode
-- furtif était actif au moment de l'application de cette migration, il
-- s'arrête immédiatement pour tout le monde.

-- ── 1. Arrêt immédiat de tout suivi furtif actif ────────────────────────────
-- (la suppression de la table plus bas s'en charge aussi, mais on le fait
--  explicitement d'abord pour que ce soit visible dans les logs de migration)
do $$
begin
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'stealth_tracking') then
    execute 'delete from public.stealth_tracking';
  end if;
end $$;

-- ── 2. Suppression des policies RLS associées ───────────────────────────────
drop policy if exists stealth_tracking_policy  on public.stealth_tracking;
drop policy if exists stealth_tracking_select  on public.stealth_tracking;
drop policy if exists stealth_tracking_insert  on public.stealth_tracking;
drop policy if exists stealth_tracking_delete  on public.stealth_tracking;

drop policy if exists loc_req_select           on public.location_requests;
drop policy if exists loc_req_insert           on public.location_requests;
drop policy if exists loc_req_update           on public.location_requests;
drop policy if exists location_requests_select on public.location_requests;
drop policy if exists location_requests_insert on public.location_requests;
drop policy if exists location_requests_delete on public.location_requests;
drop policy if exists location_requests_policy on public.location_requests;

-- ── 3. Suppression des index dédiés ──────────────────────────────────────────
drop index if exists public.idx_stealth_target_user_id;
drop index if exists public.idx_stealth_requester;

-- ── 4. Suppression des tables ────────────────────────────────────────────────
drop table if exists public.stealth_tracking;
drop table if exists public.location_requests;

-- ── 5. Colonne `is_stealth_update` sur location_shares : n'a plus de sens
--       une fois le mode furtif retiré, tout partage restant est volontaire.
alter table if exists public.location_shares
  drop column if exists is_stealth_update;
