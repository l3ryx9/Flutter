-- ══════════════════════════════════════════════════════════════════════════════
-- Purge complète d'une conversation quand elle n'a plus de messages
-- ══════════════════════════════════════════════════════════════════════════════
--
-- Contexte : à la suppression d'un compte, `deleteUser()` supprime la ligne
-- `users`. Cela cascade déjà (ON DELETE CASCADE) vers :
--   - messages (sender_id / receiver_id)
--   - comportements, scores_relationnels, profils_personnalite,
--     resumes_mensuels, faits_cles, incoherences (personne_id)
--
-- Mais deux tables restent orphelines après cette cascade, car elles ne sont
-- rattachées qu'à `conversation_id` (une conversation est partagée par 2
-- personnes, donc il n'y a pas de `personne_id` unique à qui accrocher une
-- contrainte FK directe) :
--   - resumes_quotidiens
--   - compteurs_conversation
-- Et la ligne `conversations` elle-même n'est jamais supprimée (pas de
-- policy DELETE, pas de cascade), donc elle reste indéfiniment avec un
-- participant_ids pointant vers un utilisateur qui n'existe plus.
--
-- Solution : puisqu'une conversation à 2 personnes voit TOUS ses messages
-- disparaître dès qu'UN SEUL des deux participants supprime son compte
-- (chaque message a soit ce sender_id, soit ce receiver_id — dans une
-- conversation à 2, c'est nécessairement l'un des deux rôles), on peut se
-- fier de façon fiable à "plus aucun message dans cette conversation" comme
-- signal que la conversation est terminée et doit être entièrement purgée.
-- Un trigger AFTER DELETE ON messages vérifie ce cas et, si c'est vrai,
-- supprime la conversation et tout ce qui lui reste attaché.

CREATE OR REPLACE FUNCTION purger_conversation_si_vide()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conversation_id uuid;
  v_messages_restants int;
BEGIN
  v_conversation_id := OLD.conversation_id;

  SELECT count(*) INTO v_messages_restants
  FROM messages
  WHERE conversation_id = v_conversation_id;

  IF v_messages_restants = 0 THEN
    DELETE FROM resumes_quotidiens   WHERE conversation_id = v_conversation_id;
    DELETE FROM compteurs_conversation WHERE conversation_id = v_conversation_id;
    -- comportements / scores_relationnels / profils_personnalite / faits_cles /
    -- incoherences / resumes_mensuels sont déjà couverts par leur propre
    -- ON DELETE CASCADE via personne_id — rien à faire ici pour eux, mais on
    -- les purge quand même explicitement par conversation_id pour ne rien
    -- laisser dépendre uniquement de l'ordre des cascades multi-tables.
    DELETE FROM comportements        WHERE conversation_id = v_conversation_id;
    DELETE FROM scores_relationnels  WHERE conversation_id = v_conversation_id;
    DELETE FROM profils_personnalite WHERE conversation_id = v_conversation_id;
    DELETE FROM faits_cles           WHERE conversation_id = v_conversation_id;
    DELETE FROM incoherences         WHERE conversation_id = v_conversation_id;
    DELETE FROM resumes_mensuels     WHERE conversation_id = v_conversation_id;
    DELETE FROM location_shares      WHERE conversation_id = v_conversation_id;
    DELETE FROM conversations        WHERE id = v_conversation_id;
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_purger_conversation_si_vide ON messages;
CREATE TRIGGER trg_purger_conversation_si_vide
  AFTER DELETE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION purger_conversation_si_vide();

-- ── Rattrapage pour les comptes déjà supprimés avant cette migration ────────
-- Purge dès maintenant toute conversation déjà orpheline (0 message) créée
-- par une suppression de compte antérieure à la mise en place du trigger.
DO $$
DECLARE
  v_conv record;
BEGIN
  FOR v_conv IN
    SELECT c.id
    FROM conversations c
    WHERE NOT EXISTS (SELECT 1 FROM messages m WHERE m.conversation_id = c.id)
  LOOP
    DELETE FROM resumes_quotidiens    WHERE conversation_id = v_conv.id;
    DELETE FROM compteurs_conversation WHERE conversation_id = v_conv.id;
    DELETE FROM comportements         WHERE conversation_id = v_conv.id;
    DELETE FROM scores_relationnels   WHERE conversation_id = v_conv.id;
    DELETE FROM profils_personnalite  WHERE conversation_id = v_conv.id;
    DELETE FROM faits_cles            WHERE conversation_id = v_conv.id;
    DELETE FROM incoherences          WHERE conversation_id = v_conv.id;
    DELETE FROM resumes_mensuels      WHERE conversation_id = v_conv.id;
    DELETE FROM location_shares       WHERE conversation_id = v_conv.id;
    DELETE FROM conversations         WHERE id = v_conv.id;
  END LOOP;
END $$;
