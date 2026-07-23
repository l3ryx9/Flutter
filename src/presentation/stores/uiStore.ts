/**
 * Store Zustand — UI et Préférences
 */
import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

// ── Initialisation MMKV défensive ────────────────────────────────────────────
// MMKV est un module natif. Si le build natif n'est pas disponible (Expo Go,
// environnement de CI, émulateur sans support natif), new MMKV() lance une
// exception au chargement du module et fait planter l'app au démarrage avant
// que le moindre composant React ne soit monté. On enveloppe l'import dans un
// try/catch : si MMKV est disponible on l'utilise (performances maximales),
// sinon on bascule sur un shim AsyncStorage-based synchrone en mémoire.
let mmkv: {
  getBoolean(key: string): boolean | undefined;
  getString(key: string): string | undefined;
  set(key: string, value: boolean | string): void;
} | null = null;

try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { MMKV } = require('react-native-mmkv');
  mmkv = new MMKV({ id: 'youme-ui-prefs' });
} catch {
  // MMKV non disponible (Expo Go ou build non natif) — shim en mémoire.
  const _mem: Record<string, boolean | string> = {};
  mmkv = {
    getBoolean: (key: string) => (typeof _mem[key] === 'boolean' ? (_mem[key] as boolean) : undefined),
    getString: (key: string) => (typeof _mem[key] === 'string' ? (_mem[key] as string) : undefined),
    set: (key: string, value: boolean | string) => { _mem[key] = value; },
  };
}

const storage = mmkv!;

interface UIState {
  isDarkMode: boolean;
  /** Thème tropical actif (id — voir TROPICAL_THEMES dans theme.ts). */
  themeId: string;
  /**
   * Toujours `true` : l'analyse IA des conversations n'est pas désactivable
   * depuis l'app. Le consentement est donné une fois, explicitement, à
   * l'inscription (voir écran de consentement) ; la seule façon d'arrêter
   * l'analyse et de faire supprimer les données associées est de supprimer
   * son compte (voir account-deletion.tsx). Ce champ reste lu par
   * AIMessageAnalyzer par simplicité, mais aucune UI ne doit permettre de
   * le faire passer à `false`.
   */
  aiEnabled: boolean;
  notificationsEnabled: boolean;
  notificationPermissionAsked: boolean; // true après la première demande de permission
  isOnboarded: boolean;
  activeTab: string;

  toggleDarkMode: () => void;
  setTheme: (themeId: string, isDark: boolean) => void;
  setNotificationsEnabled: (enabled: boolean) => void;
  setNotificationPermissionAsked: () => void;
  setIsOnboarded: (onboarded: boolean) => void;
  setActiveTab: (tab: string) => void;
  loadPersistedState: () => void;
}

export const useUIStore = create<UIState>((set, get) => ({
  isDarkMode: true,
  themeId: storage.getString('themeId') ?? 'foret',
  aiEnabled: true,
  notificationsEnabled: storage.getBoolean('notificationsEnabled') ?? true,
  notificationPermissionAsked: storage.getBoolean('notificationPermissionAsked') ?? false,
  isOnboarded: storage.getBoolean('isOnboarded') ?? false,
  activeTab: 'index',

  toggleDarkMode: () => {
    const next = !get().isDarkMode;
    storage.set('isDarkMode', next);
    set({ isDarkMode: next });
  },
  setTheme: (themeId, isDark) => {
    storage.set('themeId', themeId);
    storage.set('isDarkMode', isDark);
    // isDarkMode reste synchronisé pour les écrans qui s'en servent (icônes,
    // status bar…) — chaque thème tropical est intrinsèquement clair ou sombre.
    set({ themeId, isDarkMode: isDark });
  },
  setNotificationsEnabled: (notificationsEnabled) => {
    storage.set('notificationsEnabled', notificationsEnabled);
    set({ notificationsEnabled });
  },
  setNotificationPermissionAsked: () => {
    storage.set('notificationPermissionAsked', true);
    set({ notificationPermissionAsked: true });
  },
  setIsOnboarded: (isOnboarded) => {
    storage.set('isOnboarded', isOnboarded);
    set({ isOnboarded });
  },
  setActiveTab: (activeTab) => set({ activeTab }),
  loadPersistedState: () => {
    set({
      isDarkMode: storage.getBoolean('isDarkMode') ?? true,
      themeId: storage.getString('themeId') ?? 'foret',
      aiEnabled: true,
      notificationsEnabled: storage.getBoolean('notificationsEnabled') ?? true,
      notificationPermissionAsked: storage.getBoolean('notificationPermissionAsked') ?? false,
      isOnboarded: storage.getBoolean('isOnboarded') ?? false,
    });
  },
}));
