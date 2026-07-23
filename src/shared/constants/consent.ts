/**
 * Texte de consentement — Analyse IA des conversations
 *
 * Source unique de vérité pour ce texte, utilisé à l'inscription et
 * réaffichable depuis les paramètres. Toute modification du contenu
 * doit s'accompagner d'un changement de `ANALYSIS_CONSENT_VERSION`
 * (voir migration 20260724_consentement_analyse_ia.sql) pour pouvoir
 * retrouver quelle version exacte un utilisateur donné a acceptée.
 *
 * Règle impérative : ce texte ne doit JAMAIS employer un vocabulaire de
 * confidentialité absolue ("chiffré", "privé", "personne ne peut lire")
 * puisque ce n'est pas le cas — les messages sont lisibles côté serveur
 * et analysés par une IA. Voir ARCHITECTURE.md / CHANGEMENTS pour le
 * contexte de cette décision.
 */

export const ANALYSIS_CONSENT_VERSION = '2026-07-24';

export const ANALYSIS_CONSENT_TEXT =
  "YouMe analyse le contenu de vos conversations à l'aide d'une intelligence " +
  "artificielle, pour générer votre profil relationnel, les indicateurs de la " +
  "jauge, et les alertes. Vos messages sont stockés de façon sécurisée sur nos " +
  "serveurs et ne sont pas chiffrés de bout en bout : ils peuvent être lus par " +
  "le service pour permettre cette analyse. En cochant cette case, vous " +
  "acceptez cette analyse et ce stockage. Vous pouvez supprimer définitivement " +
  "toutes vos données à tout moment depuis votre compte.";

/** Version courte utilisée dans l'espace réduit du formulaire d'inscription. */
export const ANALYSIS_CONSENT_TEXT_SHORT =
  "J'accepte que mes conversations soient stockées sur les serveurs de YouMe " +
  "(non chiffrées de bout en bout) et analysées par une intelligence " +
  "artificielle pour générer les profils, la jauge et les alertes.";
