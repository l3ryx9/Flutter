# YouMe – Tropical Paradise Flutter App 🌴

Application Flutter entièrement dessinée avec `CustomPainter`, sans aucune image externe.

## Structure du projet

```
lib/
├── main.dart                          # Point d'entrée, routes, thème
├── painters/
│   ├── sky_painter.dart               # Ciel dégradé + soleil + rayons + nuages
│   ├── sea_painter.dart               # Mer turquoise + vagues animées + reflets
│   ├── beach_painter.dart             # Plage de sable + rochers 3D
│   ├── palm_tree_painter.dart         # Palmiers 3D avec balancement
│   ├── tropical_elements_painter.dart # Fleurs, feuilles, ananas
│   ├── atmosphere_painter.dart        # Bulles flottantes + particules + lens flare
│   └── pineapple_painter.dart         # Ananas 3D pour le splash screen
├── models/
│   └── explosion_particle.dart        # Fragments, poussière, éclats pour l'explosion
├── widgets/
│   └── bubble_button.dart             # Bouton Bubble 3D avec animations élastiques
└── screens/
    ├── splash_screen.dart             # Splash animé : ananas → explosion → YouMe
    └── login_screen.dart              # Page de connexion sur fond tropical
```

## Fonctionnalités

### Splash Screen
1. Apparition de l'ananas 3D avec rebond élastique
2. Wobble avant explosion
3. **Explosion avec physique** : 24 fragments, poussière tropicale, 16 éclats lumineux
4. Flash de lumière au moment de l'explosion
5. Texte **YouMe** (Dancing Script) avec effet shimmer traversant
6. Zoom + rebond subtil sur le texte
7. Transition **Fade + Scale** vers la page de connexion

### Scène tropicale (6 couches CustomPainter)
| Painter | Contenu |
|---------|---------|
| `SkyPainter` | Ciel dégradé, soleil 3D, 16 rayons, halo, 3 nuages animés |
| `SeaPainter` | 3 couches de vagues animées, foam, reflets scintillants |
| `BeachPainter` | Plage de sable avec ombres, 4 rochers 3D arrondis, bord humide |
| `TropicalElementsPainter` | 4 feuilles banane, 3 ananas, 4 fleurs à 6 pétales |
| `PalmTreePainter` | 4 palmiers 3D (courbes de Bézier, noix de coco, 7 feuilles) |
| `AtmospherePainter` | 18 bulles transparentes, 35 particules, lens flares |

### Bouton Bubble 3D (`BubbleButton`)
- Gradient 3D + bordure glossy + reflet lumineux
- Ombre portée dynamique
- **Pulsation** permanente (TweenAnimationBuilder)
- **Compression** au tap (scale 0.92)
- **Rebond élastique** au relâchement (Curves.elasticOut)
- **Ripple personnalisé** avec mask clip

### Page de connexion
- Fond : scène tropicale animée (60 FPS)
- Carte glassmorphism avec bordure translucide
- Champs de saisie stylisés
- Indicateur de chargement

## Installation

```bash
# Prérequis : Flutter 3.x
flutter pub get
flutter run
```

## Dépendances

```yaml
dependencies:
  flutter: sdk: flutter
  google_fonts: ^6.2.1   # Dancing Script pour le logo YouMe
```

## Performance

Toutes les animations sont optimisées :
- `shouldRepaint` implémenté sur chaque painter
- Particules et bulles avec données statiques précalculées
- Ticker unique pour la physique d'explosion
- Blend modes screen pour les effets de lumière
