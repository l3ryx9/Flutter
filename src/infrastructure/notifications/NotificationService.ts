/**
 * Service de Notifications Push
 * Utilise Expo Notifications + Supabase pour stocker le token FCM.
 */
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';
import { userRepository } from '@infrastructure/supabase/UserRepository';

// ── Initialisation MMKV défensive (même pattern que uiStore) ─────────────────
let notifStorage: {
  getBoolean(key: string): boolean | undefined;
  set(key: string, value: boolean): void;
};

try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { MMKV } = require('react-native-mmkv');
  notifStorage = new MMKV({ id: 'youme-ui-prefs' });
} catch {
  const _mem: Record<string, boolean> = {};
  notifStorage = {
    getBoolean: (key: string) => _mem[key],
    set: (key: string, value: boolean) => { _mem[key] = value; },
  };
}

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export class NotificationService {
  async registerForPushNotifications(userId: string): Promise<string | null> {
    if (!Device.isDevice) {
      console.warn('[NotificationService] Émulateur — notifications non disponibles');
      return null;
    }

    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      // Demander la permission UNE SEULE FOIS (première connexion).
      // Si déjà demandé et refusé, on ne redemande plus.
      const alreadyAsked = notifStorage.getBoolean('notificationPermissionAsked') ?? false;
      if (!alreadyAsked) {
        notifStorage.set('notificationPermissionAsked', true);
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }
    }

    if (finalStatus !== 'granted') {
      console.warn('[NotificationService] Permission de notification refusée ou non demandée');
      return null;
    }

    if (Platform.OS === 'android') {
      await Notifications.setNotificationChannelAsync('messages', {
        name: 'Messages',
        importance: Notifications.AndroidImportance.MAX,
        vibrationPattern: [0, 250, 250, 250],
        lightColor: '#00A884',
        // Son système par défaut (notification.wav absent des assets)
        sound: 'default',
      });
    }

    try {
      const projectId = Constants.expoConfig?.extra?.eas?.projectId;
      const token = await Notifications.getExpoPushTokenAsync({ projectId });
      await userRepository.updateFcmToken(userId, token.data);
      return token.data;
    } catch (error) {
      console.error('[NotificationService] Erreur token :', error);
      return null;
    }
  }

  setupListeners(
    onNotification: (notification: Notifications.Notification) => void,
    onResponse: (response: Notifications.NotificationResponse) => void
  ): () => void {
    const notifSub = Notifications.addNotificationReceivedListener(onNotification);
    const responseSub = Notifications.addNotificationResponseReceivedListener(onResponse);
    return () => { notifSub.remove(); responseSub.remove(); };
  }

  async scheduleLocalNotification(
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<void> {
    try {
      await Notifications.scheduleNotificationAsync({
        content: { title, body, data: data ?? {} },
        trigger: null,
      });
    } catch (error) {
      console.error('[NotificationService] Erreur scheduleLocalNotification :', error);
    }
  }
}

export const notificationService = new NotificationService();
