# YouMe — Rapport de Sécurité

_Audit réalisé le 2026-07-21_

---

## ✅ Points positifs

| Élément | Détail |
|---|---|
| Supabase Row Level Security | Activé sur toutes les tables (voir migration SQL) |
| E2EE (chiffrement de bout en bout) | ECDH prime256v1 + AES-GCM 256 implémenté |
| Anti-bot | Calcul arithmétique + délai minimum 3s côté client |
| Suppression de compte | Double confirmation ("SUPPRIMER" + mot de passe) |
| Clé Gemini | Stockée en variable d'environnement Supabase Edge Function, jamais dans le code |
| Debug screen | Bloqué en mode `kReleaseMode` (production inaccessible) |
| Sessions | Gérées par Supabase Auth (rotation de tokens) |
| Logs d'erreur | Limités à 500 entrées (anti-overflow) |

---

## 🔴 Problèmes critiques (corrigés dans ce commit)

### 1. E2EE non activé
**Avant** : Messages envoyés en clair malgré la présence du chiffrement.  
**Après** : `EncryptionService.encrypt()` appelé dans `_sendText()`. Bannière d'état E2EE dans l'interface.

### 2. Credentials Supabase placeholders
**Avant** : `'https://YOUR_PROJECT.supabase.co'` / `'YOUR_ANON_KEY'`  
**Après** : URL réelle mise à jour. **La clé anon doit être complétée par le développeur** (voir `app_constants.dart`).

### 3. Tables manquantes (13/16)
**Avant** : Seules `profiles`, `messages`, `conversations` existaient. Les fonctionnalités IA/contacts/notifications ne pouvaient pas persister de données.  
**Après** : Script SQL `supabase/migrations/001_create_missing_tables.sql` avec RLS complet sur toutes les tables.

---

## 🟡 Problèmes modérés (corrigés)

### 4. Debug screen accessible à tous
**Avant** : Route `/home/debug` accessible à tout utilisateur authentifié.  
**Après** : Bloqué en `kReleaseMode` — affiche "Accès restreint" en production.

### 5. Localisation Paris codée en dur
**Avant** : `location_lat: 48.8566, location_lng: 2.3522` hardcodé.  
**Après** : `Geolocator.getCurrentPosition()` avec demande de permission explicite.

### 6. Upload d'image non implémenté
**Avant** : TODO vide dans `_pickImage()`.  
**Après** : Upload vers Supabase Storage (`media` bucket) + insertion message.

### 7. Navigation sur tap de notification absente
**Avant** : `_handleMessageOpened` se contentait de logger.  
**Après** : Navigation intelligente selon le type (`message` → chat, `flag` → flags, etc.).

### 8. Réactions aux messages vides
**Avant** : `_reactToMessage()` vide.  
**Après** : Upsert dans `message_reactions` via Supabase.

---

## 🟡 Recommandations restantes (à implémenter)

### Priorité haute

1. **Clé anon Supabase dans le code source**  
   La `supabaseAnonKey` est une clé publique par design, mais ne doit PAS être dans le dépôt Git en clair.  
   **Solution recommandée** : Utiliser `--dart-define` au build ou `flutter_dotenv`.

2. **Stockage des clés E2EE**  
   Actuellement dans `SharedPreferences` (non sécurisé).  
   **Solution** : Migrer vers `flutter_secure_storage` (Keychain iOS / Keystore Android).

3. **Anti-bot serveur**  
   La validation du calcul arithmétique est côté client (contournable).  
   **Solution** : Valider via Edge Function `validate-bot` avant toute inscription.

4. **Clé Google Maps**  
   `YOUR_GOOGLE_MAPS_API_KEY` doit être remplacée et restreinte à l'application (SHA-1).

### Priorité moyenne

5. **Rate limiting sur l'Edge Function `gemini-chat`**  
   Sans limite, un utilisateur peut générer des coûts Gemini illimités.

6. **Sanitisation des logs**  
   `ErrorLogger` peut capturer des données personnelles dans les stack traces.  
   Implémenter une fonction de filtrage avant sauvegarde.

7. **Expiration des tokens FCM**  
   Nettoyer les tokens invalides dans `device_tokens` périodiquement.

---

## 📋 Tables Supabase — Statut RLS

| Table | Existe | RLS | Notes |
|---|---|---|---|
| `profiles` | ✅ | ✅ | Lecture publique pour affichage |
| `messages` | ✅ | ✅ | Select limité aux participants |
| `conversations` | ✅ | ✅ | Select limité aux participants |
| `contacts` | ✅* | ✅ | *Créé par migration 001 |
| `contact_requests` | ✅* | ✅ | *Créé par migration 001 |
| `message_reactions` | ✅* | ✅ | *Créé par migration 001 |
| `ai_message_insights` | ✅* | ✅ | Insert via service_role uniquement |
| `conversation_analysis` | ✅* | ✅ | Insert via service_role uniquement |
| `relationship_flags` | ✅* | ✅ | Insert via service_role uniquement |
| `psychological_profiles` | ✅* | ✅ | Insert via service_role uniquement |
| `daily_summaries` | ✅* | ✅ | Select limité aux participants |
| `highlighted_facts` | ✅* | ✅ | *Créé par migration 001 |
| `monthly_summaries` | ✅* | ✅ | Select limité aux participants |
| `device_tokens` | ✅* | ✅ | Accès uniquement à ses propres tokens |
| `live_locations` | ✅* | ✅ | Select limité aux participants |
| `bot_protection_logs` | ✅* | ✅ | Aucune policy anon (service_role only) |

*À créer via `supabase/migrations/001_create_missing_tables.sql`

---

## 🚀 Prochaines étapes recommandées

1. Exécuter `supabase/migrations/001_create_missing_tables.sql` dans Supabase > SQL Editor
2. Récupérer la clé `anon` dans Supabase > Settings > API et la mettre dans `app_constants.dart`
3. Migrer le stockage des clés E2EE vers `flutter_secure_storage`
4. Configurer `--dart-define` pour les variables d'environnement
5. Configurer les Edge Functions Supabase avec la clé Gemini
