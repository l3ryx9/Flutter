#!/usr/bin/env node
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * retryBuild.js — Build Flutter avec auto-correction IA (Gemini)
 *
 * À placer dans : youme/ci/retryBuild.js
 *
 * Fonctionnement :
 *   1. Lance `flutter build apk|appbundle --release --obfuscate ...`
 *   2. En cas d'échec, envoie les logs (redigés des secrets) à Gemini
 *   3. Applique les corrections proposées (fichiers + commandes autorisées)
 *   4. Relance le build (jusqu'à MAX_ATTEMPTS tentatives)
 *   5. Écrit ci/logs/build-summary.json + attempt-N.log
 *
 * Variables d'environnement :
 *   GEMINI_API_KEY   — requis pour l'auto-correction (sinon simple build)
 *   GEMINI_MODEL     — défaut : gemini-2.0-flash
 *   BUILD_TARGET     — apk (défaut) | appbundle
 *   MAX_ATTEMPTS     — défaut : 3
 *   SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_KEY — injectés en --dart-define
 * ═══════════════════════════════════════════════════════════════════════════
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();
const LOG_DIR = path.join(ROOT, 'ci', 'logs');
fs.mkdirSync(LOG_DIR, { recursive: true });

const MAX_ATTEMPTS = Math.max(1, parseInt(process.env.MAX_ATTEMPTS || '3', 10));
const TARGET = process.env.BUILD_TARGET === 'appbundle' ? 'appbundle' : 'apk';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';

const DEBUG_INFO_DIR = TARGET === 'apk' ? 'build/debug-info' : 'build/debug-info-aab';
const ARTIFACT_PATH =
  TARGET === 'apk'
    ? 'build/app/outputs/flutter-apk/app-release.apk'
    : 'build/app/outputs/bundle/release/app-release.aab';

const SECRET_KEYS = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'GOOGLE_MAPS_KEY', 'GEMINI_API_KEY'];

// Commandes de réparation que l'IA a le droit de proposer
const ALLOWED_COMMANDS = [/^flutter\s+clean\b/, /^flutter\s+pub\b/, /^dart\s+pub\b/, /^dart\s+fix\b/];

// Fichiers que l'IA n'a PAS le droit de modifier
const PROTECTED_PATHS = [
  '.github/',
  'ci/',
  'android/key.properties',
  'android/app/release.keystore',
];

// ── Utilitaires ─────────────────────────────────────────────────────────────

function redact(text) {
  let out = text;
  for (const key of SECRET_KEYS) {
    const val = process.env[key];
    if (val && val.length > 3) out = out.split(val).join('***');
  }
  return out;
}

function buildArgs() {
  const args = [
    'build', TARGET, '--release',
    '--obfuscate',
    `--split-debug-info=${DEBUG_INFO_DIR}`,
  ];
  for (const key of ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'GOOGLE_MAPS_KEY']) {
    if (process.env[key]) args.push(`--dart-define=${key}=${process.env[key]}`);
  }
  return args;
}

function runBuild(attempt) {
  console.log(`\n═══ Tentative ${attempt}/${MAX_ATTEMPTS} : flutter build ${TARGET} --release --obfuscate ═══`);
  const res = spawnSync('flutter', buildArgs(), {
    cwd: ROOT,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    env: process.env,
  });
  const output = redact(`${res.stdout || ''}\n${res.stderr || ''}`);
  fs.writeFileSync(path.join(LOG_DIR, `attempt-${attempt}.log`), output);
  return { ok: res.status === 0, output };
}

function isPathAllowed(p) {
  if (!p || path.isAbsolute(p) || p.includes('..')) return false;
  const normalized = path.normalize(p).replace(/\\/g, '/');
  return !PROTECTED_PATHS.some((blocked) => normalized === blocked || normalized.startsWith(blocked));
}

function isCommandAllowed(cmd) {
  return typeof cmd === 'string' && ALLOWED_COMMANDS.some((re) => re.test(cmd.trim()));
}

// ── Appel Gemini ────────────────────────────────────────────────────────────

async function askGeminiForFix(buildLog, attempt) {
  const tail = buildLog.split('\n').slice(-250).join('\n');

  const prompt = [
    'Tu es un expert CI/CD qui répare des builds Flutter Android (release, obfuscation activée).',
    'Le build `flutter build ' + TARGET + ' --release` a échoué. Voici la fin des logs :',
    '```',
    tail,
    '```',
    'Propose une correction MINIMALE. Réponds UNIQUEMENT avec un objet JSON valide, sans Markdown, au format :',
    '{',
    '  "explanation": "explication courte de la cause et du correctif",',
    '  "files": [{ "path": "chemin/relatif/fichier", "content": "contenu COMPLET du fichier corrigé" }],',
    '  "commands": ["flutter clean"]',
    '}',
    'Règles :',
    '- "files" et "commands" peuvent être des tableaux vides.',
    '- "commands" : uniquement `flutter clean`, `flutter pub ...`, `dart pub ...`, `dart fix ...`.',
    '- Ne modifie JAMAIS les fichiers sous .github/, ci/, ni les fichiers de signature.',
    '- Si aucune correction automatique n\'est possible, renvoie files et commands vides avec une explication.',
  ].join('\n');

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;
  const body = {
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
  };

  const resp = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    throw new Error(`Gemini API HTTP ${resp.status}: ${(await resp.text()).slice(0, 300)}`);
  }

  const data = await resp.json();
  let text = data?.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
  text = text.replace(/^```(json)?/m, '').replace(/```\s*$/m, '').trim();

  fs.writeFileSync(path.join(LOG_DIR, `gemini-attempt-${attempt}.json`), text);
  return JSON.parse(text);
}

function applyFix(fix, attempt) {
  const applied = { files: [], commands: [] };

  for (const f of Array.isArray(fix.files) ? fix.files : []) {
    if (!isPathAllowed(f.path)) {
      console.log(`  ⛔ Fichier refusé (protégé/invalide) : ${f.path}`);
      continue;
    }
    const target = path.join(ROOT, f.path);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, f.content ?? '', 'utf8');
    console.log(`  ✏️  Fichier réécrit : ${f.path}`);
    applied.files.push(f.path);
  }

  for (const cmd of Array.isArray(fix.commands) ? fix.commands : []) {
    if (!isCommandAllowed(cmd)) {
      console.log(`  ⛔ Commande refusée : ${cmd}`);
      continue;
    }
    console.log(`  ▶️  Commande : ${cmd}`);
    const [bin, ...args] = cmd.trim().split(/\s+/);
    const res = spawnSync(bin, args, { cwd: ROOT, encoding: 'utf8', stdio: 'inherit' });
    applied.commands.push({ cmd, status: res.status });
  }

  fs.writeFileSync(
    path.join(LOG_DIR, `fix-applied-${attempt}.json`),
    JSON.stringify({ explanation: fix.explanation, ...applied }, null, 2)
  );
  return applied;
}

// ── Boucle principale ───────────────────────────────────────────────────────

(async () => {
  const start = Date.now();
  const fixes = [];
  let success = false;
  let attempt = 0;

  while (attempt < MAX_ATTEMPTS && !success) {
    attempt += 1;
    const { ok, output } = runBuild(attempt);

    if (ok) {
      success = true;
      break;
    }

    console.log(`\n❌ Build échoué (tentative ${attempt}).`);

    if (!GEMINI_API_KEY) {
      console.log('ℹ️  GEMINI_API_KEY absent — auto-correction IA désactivée.');
      break;
    }
    if (attempt >= MAX_ATTEMPTS) break;

    try {
      console.log('🤖 Analyse des logs par Gemini…');
      const fix = await askGeminiForFix(output, attempt);
      console.log(`💡 Diagnostic IA : ${(fix.explanation || '').slice(0, 300)}`);
      const applied = applyFix(fix, attempt);
      fixes.push({ attempt, explanation: fix.explanation, ...applied });

      if (applied.files.length === 0 && applied.commands.length === 0) {
        console.log('⚠️  Aucune correction applicable proposée — arrêt des tentatives.');
        break;
      }
    } catch (err) {
      console.log(`⚠️  Auto-correction impossible : ${err.message}`);
      break;
    }
  }

  const summary = {
    success,
    attempts: attempt,
    maxAttempts: MAX_ATTEMPTS,
    totalDuration: Math.round((Date.now() - start) / 1000),
    target: TARGET,
    apkPath: success ? ARTIFACT_PATH : null,
    fixes,
  };
  fs.writeFileSync(path.join(LOG_DIR, 'build-summary.json'), JSON.stringify(summary, null, 2));

  if (success) {
    console.log(`\n✅ Build réussi en ${attempt} tentative(s) : ${ARTIFACT_PATH}`);
    if (process.env.GITHUB_OUTPUT) {
      fs.appendFileSync(process.env.GITHUB_OUTPUT, `apk-path=${ARTIFACT_PATH}\n`);
    }
    process.exit(0);
  } else {
    console.log(`\n❌ Build définitivement échoué après ${attempt} tentative(s).`);
    process.exit(1);
  }
})();
