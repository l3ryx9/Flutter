/**
 * Thème YouMe V2 — « Forêt Enchantée » (dark) / « Clairière » (light)
 * Vert pomme + marron clair + accents ananas (orange/jaune) sur fond noir
 * teinté de vert (dark) ou parchemin crème (light).
 */
import { MD3DarkTheme, MD3LightTheme, configureFonts } from 'react-native-paper';
import type { MD3Theme } from 'react-native-paper';
import { useMemo } from 'react';
import { useUIStore } from '../../presentation/stores/uiStore';

// ─── Couleurs brand/accent ────────────────────────────────────────────────────

export const YOUME_COLORS = {
  // Dégradé principal (vert pomme → forêt profonde)
  gradientStart: '#8CC152',
  gradientMid:   '#4C7A28',
  gradientEnd:   '#0A0F08',

  primary:      '#7FD858', // vert pomme plus vif — ressort sur les photos de jungle sombres
  primaryDark:  '#4C7A28', // vert forêt profond
  primaryLight: '#A9E67D', // vert pomme clair
  secondary:    '#5C4128', // écorce chaude, plus claire que le fond photo pour bien se détacher

  // Surfaces & fonds — thème « Forêt Enchantée » (nuit)
  background:     '#0A0F08', // noir à peine teinté de vert — nuit en forêt
  surface:        'rgba(28, 38, 28, 0.92)',  // panneau semi-opaque : laisse deviner la photo tout en restant lisible
  surfaceVariant: 'rgba(40, 54, 36, 0.92)',  // un ton au-dessus, même logique

  // Bulles de chat — orange foncé (envoyé, plus transparent) / bleu foncé (reçu, légèrement transparent)
  // Textes choisis pour un contraste maximal sur chaque couleur (WCAG AA+).
  bubbleOwn:      '#E8850FC2', // orange plus foncé, ~76% opaque (encore un peu plus transparent)
  bubbleOther:    '#14335ED9', // bleu marine profond, ~85% opaque (légère transparence ajoutée)
  bubbleOwnText:  '#2A1400',   // brun quasi noir — contraste fort sur l'orange
  bubbleOtherText:'#F2F6FF',   // blanc bleuté — contraste fort sur le bleu marine

  // Textes
  textPrimary:   '#F5F1E0', // ivoire chaud (clair de lune à travers les feuilles)
  textSecondary: '#D8CDA8', // kaki clair, plus lumineux pour la lisibilité sur photo
  textMuted:     '#A3B08E', // mousse grisée, éclaircie
  textLink:      '#FFA542', // orange ananas, plus vif

  // États & feedback
  online:    '#8CE86B',
  delivered: '#C9BFA0',
  read:      '#FFA542', // orange ananas — coche "lu" bien visible
  error:     '#F0776A',
  warning:   '#FFD65C', // jaune ananas
  success:   '#7FD858',

  // Accents « ananas » (utilisés pour badges, liens, éléments à faire ressortir)
  pineappleOrange: '#FFA542',
  pineappleYellow: '#FFD65C',

  // Émotions (inchangé — génériques, indépendantes du thème)
  emotionJoy:      '#FFD700',
  emotionSadness:  '#6495ED',
  emotionAnger:    '#FF4444',
  emotionFear:     '#9370DB',
  emotionSurprise: '#FF8C00',
  emotionNeutral:  '#9E9E9E',

  // Cohérence IA
  coherenceHigh:   '#6FAF3E',
  coherenceMedium: '#F4C63A',
  coherenceLow:    '#E0665A',

  // Interface
  divider:         '#243422',
  inputBackground: '#16201A',
  placeholder:     '#6B7A5C',
  badge:           '#F2932E',
  locationPin:     '#6FAF3E',

  // Legacy light mode fields (kept for backwards compat)
  lightBackground:  '#F5F1E6',
  lightSurface:     '#FFFFFF',
  lightBubbleOwn:   '#6FAF3E',
  lightBubbleOther: '#FFFFFF',
  lightTextPrimary: '#1E2A16',
} as const;

// Type largi (chaque couleur est un `string` hex) pour permettre les
// surcharges Light avec des valeurs différentes des littéraux `as const`.
export type YoumeColors = { [K in keyof typeof YOUME_COLORS]: string };

// ─── Surcharges Light (Forêt de jour) ─────────────────────────────────────────

const LIGHT_OVERRIDES: Partial<YoumeColors> = {
  secondary:      '#F3EDE0',
  background:     '#F5F1E6', // parchemin / clairière
  surface:        '#FFFFFF',
  surfaceVariant: '#EAE0C8', // tan clair
  divider:        '#DCD2B8',
  inputBackground:'#FFFFFF',
  placeholder:    '#9C8F6E',
  textPrimary:    '#1E2A16',
  textSecondary:  '#5A6B45',
  textMuted:      '#8E9A7A',
  textLink:       '#B96A1E',
  bubbleOwn:      '#E8850FC2',
  bubbleOther:    '#14335ED9',
  bubbleOwnText:  '#2A1400',
  bubbleOtherText:'#F2F6FF',
};

// ─── 8 thèmes « Tropical Paradise » ──────────────────────────────────────────
// Chaque thème surcharge la palette de base. `isDark` pilote les icônes/status
// bar et le thème Paper. `swatch` = les 3 couleurs du bouton 3D du sélecteur.

export interface TropicalTheme {
  id: string;
  name: string;
  emoji: string;
  isDark: boolean;
  swatch: [string, string, string];
  overrides: Partial<YoumeColors>;
}

export const TROPICAL_THEMES: TropicalTheme[] = [
  {
    id: 'foret', name: 'Forêt Enchantée', emoji: '🌴', isDark: true,
    swatch: ['#9CD16B', '#4C7A28', '#0A0F08'],
    overrides: {}, // palette de base
  },
  {
    id: 'lagon', name: 'Lagon Turquoise', emoji: '🐚', isDark: true,
    swatch: ['#5EEAD4', '#0E7490', '#042F3C'],
    overrides: {
      primary: '#2DD4BF', primaryDark: '#0E7490', primaryLight: '#7DF3E1',
      secondary: '#0B4A5C',
      gradientStart: '#2DD4BF', gradientMid: '#0E7490', gradientEnd: '#042F3C',
      background: '#04222C', surface: '#0A3341', surfaceVariant: '#0E4453',
      bubbleOwn: '#0E9A8C', bubbleOther: '#0B4A5C',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#D8F5F0',
      textPrimary: '#E4FBF7', textSecondary: '#9AD4CA', textMuted: '#5E9A92',
      textLink: '#FFB454', divider: '#11505F', inputBackground: '#0A3341',
      placeholder: '#4E8A84', badge: '#FFB454', locationPin: '#2DD4BF',
    },
  },
  {
    id: 'sunset', name: 'Coucher de Soleil', emoji: '🌅', isDark: true,
    swatch: ['#FFB347', '#E85D75', '#3B1445'],
    overrides: {
      primary: '#F97362', primaryDark: '#C23A56', primaryLight: '#FFA88C',
      secondary: '#4A1E52',
      gradientStart: '#FFB347', gradientMid: '#E85D75', gradientEnd: '#3B1445',
      background: '#25102E', surface: '#371A41', surfaceVariant: '#472455',
      bubbleOwn: '#E85D75', bubbleOther: '#4A1E52',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#F8E3EE',
      textPrimary: '#FFF1E4', textSecondary: '#E0AFC0', textMuted: '#A57A94',
      textLink: '#FFB347', divider: '#4E2A5C', inputBackground: '#371A41',
      placeholder: '#8E6488', badge: '#FFB347', locationPin: '#F97362',
    },
  },
  {
    id: 'flamant', name: 'Flamant Rose', emoji: '🦩', isDark: false,
    swatch: ['#FFD6E8', '#F472B6', '#BE185D'],
    overrides: {
      primary: '#EC4899', primaryDark: '#BE185D', primaryLight: '#F9A8D4',
      secondary: '#FCE7F3',
      gradientStart: '#F9A8D4', gradientMid: '#EC4899', gradientEnd: '#BE185D',
      background: '#FFF1F7', surface: '#FFFFFF', surfaceVariant: '#FBDCEB',
      bubbleOwn: '#EC4899', bubbleOther: '#FFFFFF',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#500724',
      textPrimary: '#500724', textSecondary: '#9D3B69', textMuted: '#C08BA4',
      textLink: '#0EA5A4', divider: '#F5CADF', inputBackground: '#FFFFFF',
      placeholder: '#C99BB2', badge: '#0EA5A4', locationPin: '#EC4899',
    },
  },
  {
    id: 'ocean', name: 'Océan Profond', emoji: '🌊', isDark: true,
    swatch: ['#7DD3FC', '#2563EB', '#0B1B3A'],
    overrides: {
      primary: '#38BDF8', primaryDark: '#2563EB', primaryLight: '#8FDCFF',
      secondary: '#15305E',
      gradientStart: '#38BDF8', gradientMid: '#2563EB', gradientEnd: '#0B1B3A',
      background: '#081226', surface: '#101F3C', surfaceVariant: '#182B4E',
      bubbleOwn: '#2563EB', bubbleOther: '#15305E',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#DCEBFF',
      textPrimary: '#E8F3FF', textSecondary: '#A9C6E8', textMuted: '#64809F',
      textLink: '#FFC24B', divider: '#1D335A', inputBackground: '#101F3C',
      placeholder: '#54719A', badge: '#FFC24B', locationPin: '#38BDF8',
    },
  },
  {
    id: 'plage', name: 'Plage Dorée', emoji: '🏖️', isDark: false,
    swatch: ['#FDE68A', '#F59E0B', '#0891B2'],
    overrides: {
      primary: '#D97706', primaryDark: '#B45309', primaryLight: '#FBBF24',
      secondary: '#FEF3C7',
      gradientStart: '#FDE68A', gradientMid: '#F59E0B', gradientEnd: '#0891B2',
      background: '#FFFBEB', surface: '#FFFFFF', surfaceVariant: '#FCEEC7',
      bubbleOwn: '#D97706', bubbleOther: '#FFFFFF',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#442C05',
      textPrimary: '#442C05', textSecondary: '#8A6A2B', textMuted: '#B79B62',
      textLink: '#0891B2', divider: '#F1E2B8', inputBackground: '#FFFFFF',
      placeholder: '#BFA671', badge: '#0891B2', locationPin: '#D97706',
    },
  },
  {
    id: 'hibiscus', name: 'Hibiscus', emoji: '🌺', isDark: true,
    swatch: ['#FB7185', '#E11D48', '#14342B'],
    overrides: {
      primary: '#F43F5E', primaryDark: '#BE123C', primaryLight: '#FB8CA0',
      secondary: '#1D4A3C',
      gradientStart: '#FB7185', gradientMid: '#E11D48', gradientEnd: '#14342B',
      background: '#0E241E', surface: '#16362C', surfaceVariant: '#1E463A',
      bubbleOwn: '#E11D48', bubbleOther: '#1D4A3C',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#E4F5EC',
      textPrimary: '#F5FBF3', textSecondary: '#B4D6C2', textMuted: '#6E9683',
      textLink: '#FFC24B', divider: '#245446', inputBackground: '#16362C',
      placeholder: '#5E8674', badge: '#F43F5E', locationPin: '#F43F5E',
    },
  },
  {
    id: 'mangue', name: 'Mangue Passion', emoji: '🥭', isDark: true,
    swatch: ['#FCD34D', '#F97316', '#3A1D0B'],
    overrides: {
      primary: '#F97316', primaryDark: '#C2570C', primaryLight: '#FDBA74',
      secondary: '#4A2A12',
      gradientStart: '#FCD34D', gradientMid: '#F97316', gradientEnd: '#3A1D0B',
      background: '#251204', surface: '#38200D', surfaceVariant: '#472B12',
      bubbleOwn: '#F97316', bubbleOther: '#4A2A12',
      bubbleOwnText: '#FFFFFF', bubbleOtherText: '#FBEBD8',
      textPrimary: '#FFF4E4', textSecondary: '#E3BE93', textMuted: '#A68360',
      textLink: '#FCD34D', divider: '#523218',
      inputBackground: '#38200D',
      placeholder: '#8F6E4C', badge: '#FCD34D', locationPin: '#F97316',
    },
  },
];

export const DEFAULT_THEME_ID = 'foret';

export function getTropicalTheme(themeId: string): TropicalTheme {
  return TROPICAL_THEMES.find((t) => t.id === themeId) ?? TROPICAL_THEMES[0];
}

export function getYoumeColors(isDarkMode: boolean, themeId?: string): YoumeColors {
  if (themeId && themeId !== DEFAULT_THEME_ID) {
    const theme = getTropicalTheme(themeId);
    return { ...YOUME_COLORS, ...theme.overrides } as YoumeColors;
  }
  if (isDarkMode) return YOUME_COLORS;
  return { ...YOUME_COLORS, ...LIGHT_OVERRIDES } as YoumeColors;
}

export function useYoumeColors(): YoumeColors {
  const isDarkMode = useUIStore((s) => s.isDarkMode);
  const themeId = useUIStore((s) => s.themeId);
  return useMemo(() => getYoumeColors(isDarkMode, themeId), [isDarkMode, themeId]);
}

// ─── Police Inter (gras) pour tous les composants react-native-paper ────────
// (Button, TextInput, HelperText, Switch label, etc.) — complète l'override
// global des <Text>/<TextInput> natifs fait dans app/_layout.tsx.
const PAPER_FONTS = configureFonts({ config: { fontFamily: 'Inter_700Bold' } });

/** Thème react-native-paper construit dynamiquement depuis le thème tropical. */
export function buildPaperTheme(themeId: string, isDarkMode: boolean): MD3Theme {
  const t = getTropicalTheme(themeId);
  const dark = themeId === DEFAULT_THEME_ID ? isDarkMode : t.isDark;
  const c = getYoumeColors(dark, themeId);
  const base = dark ? MD3DarkTheme : MD3LightTheme;
  return {
    ...base,
    fonts: PAPER_FONTS,
    colors: {
      ...base.colors,
      primary:          c.primary,
      onPrimary:        '#FFFFFF',
      primaryContainer: c.primaryDark,
      secondary:        c.secondary,
      tertiary:         c.primaryLight,
      background:       c.background,
      surface:          c.surface,
      surfaceVariant:   c.surfaceVariant,
      onSurface:        c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline:          c.divider,
      error:            c.error,
    },
  };
}

// ─── Thèmes React-Native-Paper ───────────────────────────────────────────────

export const YOUME_DARK_THEME: MD3Theme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary:          YOUME_COLORS.primary,
    onPrimary:        '#FFFFFF',
    primaryContainer: YOUME_COLORS.primaryDark,
    secondary:        YOUME_COLORS.secondary,
    tertiary:         YOUME_COLORS.primaryLight,
    background:       YOUME_COLORS.background,
    surface:          YOUME_COLORS.surface,
    surfaceVariant:   YOUME_COLORS.surfaceVariant,
    onSurface:        YOUME_COLORS.textPrimary,
    onSurfaceVariant: YOUME_COLORS.textSecondary,
    outline:          YOUME_COLORS.divider,
    error:            YOUME_COLORS.error,
  },
};

export const YOUME_LIGHT_THEME: MD3Theme = {
  ...MD3LightTheme,
  colors: {
    ...MD3LightTheme.colors,
    primary:          YOUME_COLORS.primary,
    onPrimary:        '#FFFFFF',
    primaryContainer: LIGHT_OVERRIDES.bubbleOwn as string,
    secondary:        LIGHT_OVERRIDES.secondary as string,
    tertiary:         YOUME_COLORS.primaryLight,
    background:       LIGHT_OVERRIDES.background as string,
    surface:          LIGHT_OVERRIDES.surface as string,
    surfaceVariant:   LIGHT_OVERRIDES.surfaceVariant as string,
    onSurface:        LIGHT_OVERRIDES.textPrimary as string,
    onSurfaceVariant: LIGHT_OVERRIDES.textSecondary as string,
    outline:          LIGHT_OVERRIDES.divider as string,
    error:            YOUME_COLORS.error,
  },
};

// ─── Autres constantes (inchangées) ──────────────────────────────────────────

export const SPACING = {
  xs:  4,
  sm:  8,
  md:  16,
  lg:  24,
  xl:  32,
  xxl: 48,
} as const;

export const BORDER_RADIUS = {
  sm:     10,
  md:     14,
  lg:     20,
  xl:     26,
  round:  50,
  bubble: 20,
} as const;

export const TYPOGRAPHY = {
  fontFamily: {
    regular: 'Inter_700Bold',
    medium:  'Inter_700Bold',
    bold:    'Inter_700Bold',
    script:  'DancingScript_700Bold',
  },
  size: {
    xs:      11,
    sm:      12,
    md:      14,
    lg:      16,
    xl:      18,
    xxl:     24,
    heading: 28,
  },
} as const;

export const SHADOW = {
  sm: {
    shadowColor:   '#000',
    shadowOffset:  { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius:  2,
    elevation:     2,
  },
  md: {
    shadowColor:   '#000',
    shadowOffset:  { width: 0, height: 2 },
    shadowOpacity: 0.35,
    shadowRadius:  4,
    elevation:     4,
  },
  glow: {
    shadowColor:   '#E91E8C',
    shadowOffset:  { width: 0, height: 0 },
    shadowOpacity: 0.45,
    shadowRadius:  10,
    elevation:     6,
  },
  // ── Effet "bubble 3D" : ombre large et douce en position basse, comme un
  //    bouton physique qui flotte au-dessus de l'écran. Combiné à un
  //    dégradé clair→foncé et un reflet elliptique (voir Bubble3DButton),
  //    ça donne l'impression d'une sphère/bulle plutôt qu'un carré plat.
  bubble: {
    shadowColor:   '#000',
    shadowOffset:  { width: 0, height: 8 },
    shadowOpacity: 0.4,
    shadowRadius:  12,
    elevation:     10,
  },
  // État "pressé" : ombre resserrée pour simuler l'enfoncement du bouton.
  bubblePressed: {
    shadowColor:   '#000',
    shadowOffset:  { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius:  4,
    elevation:     3,
  },
} as const;

// ─── Tailles des boutons "bubble" ─────────────────────────────────────────────
// Choisies au-dessus du minimum tactile recommandé (44pt Apple / 48dp Google)
// pour que chaque bouton se voie et se comprenne comme actionnable au premier
// coup d'œil, sans avoir à deviner sa fonction.
export const BUBBLE_SIZES = {
  sm: 48,   // action secondaire (ex: pièce jointe)
  md: 60,   // action standard (ex: bouton d'un formulaire)
  lg: 76,   // action principale d'un écran (ex: envoyer, valider)
  xl: 96,   // action héro (ex: bouton d'accueil, CTA principal)
} as const;
