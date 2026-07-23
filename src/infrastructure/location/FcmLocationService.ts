/**
 * Service FCM — Gestion du token de notifications push natif.
 * Migré de Firebase/Firestore vers Supabase Postgres.
 *
 * Responsabilité :
 *  - Stocker le token FCM natif dans la table `users` (champ native_fcm_token),
 *    utilisé pour l'envoi de notifications push classiques (nouveau message,
 *    demande de partenaire, etc. — voir supabase/functions/send-push-notification).
 *
 * Ce service ne déclenche plus aucune demande de localisation à distance :
 * la fonctionnalité de "localisation furtive à la demande" a été retirée.
 * Le partage de position reste uniquement celui explicitement activé par
 * l'utilisateur qui partage sa propre position (voir LocationService.ts).
 */
let _messaging: any = null;
function getMessaging() {
  if (!_messaging) {
    try { _messaging = require('@react-native-firebase/messaging').default; } catch { return null; }
  }
  return _messaging;
}
import { supabase, TABLES } from '../supabase/config';

class FcmLocationService {
  private tokenRefreshUnsubscribe: (() => void) | null = null;

  async registerNativeFcmToken(userId: string): Promise<void> {
    try {
      const m = getMessaging();
      if (!m) { console.warn('[FcmLocationService] Module messaging natif non disponible.'); return; }
      const token = await m().getToken();
      if (token) await this.persistToken(userId, token);
    } catch (e) {
      console.warn('[FcmLocationService] Impossible d\'obtenir le token FCM :', e);
    }
    this.tokenRefreshUnsubscribe?.();
    const m2 = getMessaging();
    if (!m2) return;
    this.tokenRefreshUnsubscribe = m2().onTokenRefresh(async (newToken: string) => {
      await this.persistToken(userId, newToken);
    });
  }

  stopTokenRefreshListener(): void {
    this.tokenRefreshUnsubscribe?.();
    this.tokenRefreshUnsubscribe = null;
  }

  private async persistToken(userId: string, token: string): Promise<void> {
    try {
      await supabase.from(TABLES.USERS).update({
        native_fcm_token: token,
        updated_at: new Date().toISOString(),
      }).eq('id', userId);
    } catch (e) {
      console.warn('[FcmLocationService] Erreur sauvegarde token :', e);
    }
  }
}

export const fcmLocationService = new FcmLocationService();
