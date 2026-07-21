# YouMe — Rapport de Sécurité

_Audit réalisé et migration exécutée le 2026-07-21_

---

## ✅ Corrections appliquées (commits 96a7988 + migration directe)

| # | Problème | Sévérité | Statut |
|---|---|---|---|
| 1 | E2EE non activé — messages envoyés en clair | 🔴 Critique | ✅ Corrigé |
| 2 | URL Supabase en placeholder dans le code | 🔴 Critique | ✅ Corrigé |
| 3 | Tables manquantes (AppFlo attendait 16 tables, base en avait 3) | 🔴 Critique | ✅ 13 tables créées |
| 4 | 8 tables avec RLS activé mais 0 policies | 🔴 Critique | ✅ Policies ajoutées |
| 5 | Debug screen accessible à tous les utilisateurs | 🟡 Moyen | ✅ Bloqué kReleaseMode |
| 6 | Localisation Paris (48.8566) codée en dur | 🟡 Moyen | ✅ GPS réel (Geolocator) |
| 7 | Upload d'image non implémenté | 🟡 Moyen | ✅ Supabase Storage |
| 8 | Navigation push notification manquante | 🟡 Moyen | ✅ Routage par type |
| 9 | Réactions aux messages vides | 🟢 Mineur | ✅ Upsert message_reactions |

---

## 📋 Tables Supabase — État final (33 tables)

| Table | RLS | Policies | Notes |
|---|---|---|---|
| `profiles` | ✅ | 3 | select_public, update_own, insert_own |
| `messages` | ✅ | 4 | select/insert/update (participants + sender) |
| `conversations` | ✅ | 6 | select/insert/update (participants) |
| `contacts` | ✅ | 2 | select (both), all (user_id) |
| `contact_requests` | ✅ | 3 | select, insert (sender), update (receiver) |
| `message_reactions` | ✅ | 2 | select (participants), all (user_id) |
| `ai_message_insights` | ✅ | 1 | select_own |
| `conversation_analysis` | ✅ | 1 | select_own |
| `relationship_flags` | ✅ | 1 | select_own |
| `psychological_profiles` | ✅ | 1 | select_own |
| `daily_summaries` | ✅ | 1 | select (participants) |
| `highlighted_facts` | ✅ | 1 | select_own |
| `monthly_summaries` | ✅ | 1 | select (participants) |
| `device_tokens` | ✅ | 1 | all (user_id) |
| `live_locations` | ✅ | 2 | select (participants), upsert (user_id) |
| `bot_protection_logs` | ✅ | 0 | ✅ Intentionnel — service_role only |
| `comportements` | ✅ | 1 | select (participants) |
| `compteurs_conversation` | ✅ | 1 | select (participants) |
| `profils_personnalite` | ✅ | 1 | select (personne_id ou participants) |
| `resumes_quotidiens` | ✅ | 1 | select (participants) |
| `scores_relationnels` | ✅ | 1 | select (personne_id ou participants) |
| `rate_limit_events` | ✅ | 0 | ✅ Intentionnel — service_role only |
| `security_logs` | ✅ | 0 | ✅ Intentionnel — service_role only |
| `app_logs` | ✅ | 2 | ✅ Existant |
| `location_requests` | ✅ | 3 | ✅ Existant |
| `location_shares` | ✅ | 4 | ✅ Existant |
| `partner_requests` | ✅ | 4 | ✅ Existant |
| `partners` | ✅ | 3 | ✅ Existant |
| `public_profiles` | ✅ | 4 | ✅ Existant |
| `resumes_mensuels` | ✅ | 1 | ✅ Existant |
| `stealth_tracking` | ✅ | 3 | ✅ Existant |
| `usernames` | ✅ | 3 | ✅ Existant |
| `users` | ✅ | 4 | ✅ Existant |

---

## 🟡 Recommandations restantes

### Priorité haute — à faire maintenant

1. **Clé anon Supabase manquante dans le code**
   Renseigner dans `youme/lib/core/constants/app_constants.dart` :
   ```dart
   static const String supabaseAnonKey = 'eyJ...'; // Supabase > Settings > API > anon public
   ```
   Sans cette clé, l'app ne peut pas se connecter.

2. **Révoquer le PAT Supabase** utilisé pour la migration
   → https://app.supabase.com/account/tokens

3. **Stockage clés E2EE**
   Migrer de `SharedPreferences` vers `flutter_secure_storage`
   (Keychain iOS / Keystore Android)

### Priorité moyenne

4. **Anti-bot serveur** — validation arithmétique côté client uniquement, contournable
   Implémenter validation dans Edge Function `validate-bot`

5. **Clé Google Maps** — remplacer `YOUR_GOOGLE_MAPS_API_KEY`

6. **Rate limiting Gemini** — limiter les appels par utilisateur/minute

7. **Expiration tokens FCM** — nettoyer les tokens invalides périodiquement

---

## 🔐 Architecture E2EE

```
Alice                               Bob
  │                                   │
  ├── génère paire (pub_A, priv_A)    ├── génère paire (pub_B, priv_B)
  ├── publie pub_A → profiles         ├── publie pub_B → profiles
  │                                   │
  ├── lit pub_B                       ├── lit pub_A
  ├── ECDH(priv_A, pub_B) → secret   ├── ECDH(priv_B, pub_A) → secret
  ├── HKDF(secret) → AES-256 key     ├── HKDF(secret) → AES-256 key
  │   (même clé côté Alice et Bob)   │
  ├── AES-GCM encrypt(message, key)  │
  ├──────── encrypted_text ──────────►│
                                      ├── AES-GCM decrypt(encrypted_text, key)
```
