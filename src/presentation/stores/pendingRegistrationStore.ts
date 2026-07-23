/**
 * Store éphémère (mémoire uniquement, jamais persisté sur disque) pour
 * porter les données du formulaire d'inscription entre l'écran
 * `register.tsx` et l'écran dédié `consent.tsx`. Le mot de passe ne doit
 * jamais transiter par des query params d'URL — ce store en mémoire est
 * réinitialisé après usage et à la fermeture de l'app.
 */
import { create } from 'zustand';
import type { RegisterFormData } from '@shared/validators/authValidators';
import type { AntiBotSignals } from '@presentation/hooks/useAuth';

interface PendingRegistration {
  data: RegisterFormData;
  antiBot: AntiBotSignals;
}

interface PendingRegistrationState {
  pending: PendingRegistration | null;
  setPending: (pending: PendingRegistration) => void;
  clearPending: () => void;
}

export const usePendingRegistrationStore = create<PendingRegistrationState>((set) => ({
  pending: null,
  setPending: (pending) => set({ pending }),
  clearPending: () => set({ pending: null }),
}));
