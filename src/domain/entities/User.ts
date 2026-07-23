/**
 * Entité domaine : Utilisateur
 * Représente un utilisateur de YouMe V2.
 */
export interface User {
  id: string;
  email: string;
  username: string;
  displayName: string;
  photoURL?: string;
  bio?: string;
  isOnline: boolean;
  lastSeen: Date;
  createdAt: Date;
  updatedAt: Date;
  isEmailVerified: boolean;
  aiEnabled: boolean;
  fcmToken?: string;
}

export interface UserProfile {
  id: string;
  username: string;
  displayName: string;
  photoURL?: string;
  bio?: string;
  isOnline: boolean;
  lastSeen: Date;
}

export type CreateUserDTO = {
  id: string;
  email: string;
  password?: string;
  username: string;
  displayName: string;
  /**
   * Horodatage ISO du consentement explicite à l'analyse IA des
   * conversations, donné sur l'écran dédié (consent.tsx). Obligatoire :
   * le flux d'inscription empêche la création du compte sans ce
   * consentement (voir app/(auth)/consent.tsx).
   */
  analysisConsentAt: string;
  /** Version du texte de consentement affiché (voir src/shared/constants/consent.ts). */
  analysisConsentVersion: string;
};

export type UpdateUserDTO = Partial<Pick<User, 'displayName' | 'photoURL' | 'bio'>>;
