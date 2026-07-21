# Supabase — Base de données YouMe

## Configuration initiale

### 1. Variables d'environnement à renseigner dans l'app

Dans `youme/lib/core/constants/app_constants.dart` :

```dart
static const String supabaseUrl    = 'https://kqgididioyztbtcddmhz.supabase.co'; // ✅ déjà renseigné
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // ← Supabase > Settings > API > anon key
```

### 2. Créer les tables manquantes

Ouvrez **Supabase > SQL Editor** et exécutez le script :

```
supabase/migrations/001_create_missing_tables.sql
```

Ce script crée les 13 tables manquantes avec RLS activé et les index de performance.

### 3. Edge Functions à déployer

Les fonctionnalités IA nécessitent ces Edge Functions (avec la clé Gemini en secret Supabase) :

| Fonction | Rôle |
|---|---|
| `analyze-message` | Analyse sentiment/émotion par message |
| `analyze-flags` | Détection red/green flags |
| `daily-analysis` | Résumé quotidien de conversation |
| `monthly-summary` | Bilan mensuel |
| `gemini-chat` | Chat IA libre (AiSearchScreen) |
| `validate-bot` | Anti-bot serveur |
| `send-push-location` | Notification push de localisation |
| `transcribe-voice` | Transcription vocale |
| `delete-account` | Suppression sécurisée du compte |

Ajoutez le secret Gemini dans **Supabase > Edge Functions > Secrets** :
```
GEMINI_API_KEY=<votre clé>
```

### 4. Storage Buckets à créer

Dans **Supabase > Storage** :
- `avatars` — public
- `media` — public
- `voice` — private

### 5. Vérification post-migration

Après avoir exécuté la migration, vérifiez dans **Supabase > Authentication > Policies** que toutes les tables affichent un cadenas vert (RLS activé).

## Structure des tables

Voir `migrations/001_create_missing_tables.sql` pour le schéma complet.

## Statistiques actuelles

| Table | Lignes |
|---|---|
| `profiles` | 0 |
| `messages` | 20 |
| `conversations` | 6 |
