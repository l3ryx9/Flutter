// ci/sign-android.js
//
// Câble la signature "release" dans android/app/build.gradle généré par
// `expo prebuild`. Si un keystore a été décodé à l'étape précédente
// (android/app/release.keystore présent), on injecte un signingConfigs.release
// qui lit le mot de passe / alias depuis les variables d'environnement
// (fournies par les secrets GitHub Actions). Sinon on ne touche à rien et
// l'APK reste signé par le keystore debug par défaut.

const fs = require('fs');
const path = require('path');

const buildGradlePath = path.join(__dirname, '..', 'android', 'app', 'build.gradle');
const keystorePath = path.join(__dirname, '..', 'android', 'app', 'release.keystore');

if (!fs.existsSync(keystorePath)) {
  console.log('⚠️  Pas de release.keystore trouvé — signature release ignorée (build restera signé debug).');
  process.exit(0);
}

if (!fs.existsSync(buildGradlePath)) {
  console.error(`❌ Fichier introuvable : ${buildGradlePath}`);
  process.exit(1);
}

let contents = fs.readFileSync(buildGradlePath, 'utf8');

if (contents.includes('MYAPP_RELEASE_STORE_FILE')) {
  console.log('ℹ️  signingConfigs.release déjà présent dans build.gradle — rien à faire.');
  process.exit(0);
}

const signingConfigBlock = `
    signingConfigs {
        release {
            storeFile file("release.keystore")
            storePassword System.getenv("ANDROID_STORE_PASSWORD")
            keyAlias System.getenv("ANDROID_KEY_ALIAS")
            keyPassword System.getenv("ANDROID_KEY_PASSWORD")
        }
    }
`;

if (!/android\s*\{/.test(contents)) {
  console.error('❌ Bloc "android {" introuvable dans build.gradle — impossible d\'injecter la signature.');
  process.exit(1);
}

// Insère signingConfigs juste après l'ouverture du bloc android {
contents = contents.replace(/android\s*\{/, (match) => `${match}\n${signingConfigBlock}`);

// Fait pointer buildTypes.release vers signingConfigs.release
if (/buildTypes\s*\{[\s\S]*?release\s*\{/.test(contents)) {
  contents = contents.replace(
    /(buildTypes\s*\{[\s\S]*?release\s*\{)/,
    `$1\n            signingConfig signingConfigs.release`
  );
} else {
  console.warn('⚠️  Bloc buildTypes.release introuvable — signingConfig non assigné automatiquement.');
}

fs.writeFileSync(buildGradlePath, contents, 'utf8');
console.log('✅ signingConfigs.release injecté dans android/app/build.gradle');
