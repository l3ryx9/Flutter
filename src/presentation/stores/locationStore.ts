import { create } from 'zustand';
import type { LiveLocationData } from '@infrastructure/location/LocationService';

interface LocationState {
  // Partage de ma position
  isSharing: boolean;
  sharingConversationId: string | null;
  // Position du partenaire (temps réel)
  partnerLocation: LiveLocationData | null;

  setSharing: (sharing: boolean, conversationId?: string) => void;
  setPartnerLocation: (loc: LiveLocationData | null) => void;
}

export const useLocationStore = create<LocationState>((set) => ({
  isSharing: false,
  sharingConversationId: null,
  partnerLocation: null,

  setSharing: (isSharing, sharingConversationId) =>
    set({ isSharing, sharingConversationId: sharingConversationId ?? null }),

  setPartnerLocation: (partnerLocation) => set({ partnerLocation }),
}));
