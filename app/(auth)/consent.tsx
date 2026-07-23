/**
 * Écran de Consentement — Analyse IA des conversations
 *
 * Étape obligatoire du flux d'inscription, entre le formulaire
 * (register.tsx) et la création réelle du compte. Le compte n'est créé
 * qu'après un choix explicite ("J'accepte") sur cet écran ; il n'y a
 * pas de case pré-cochée, pas de configuration alternative, et aucun
 * moyen ailleurs dans l'app de désactiver l'analyse sans supprimer le
 * compte (voir account-deletion.tsx).
 */
import React, { useState } from 'react';
import { themedAlert } from '@presentation/components/common/ThemedAlert';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { router } from 'expo-router';
import { Button } from 'react-native-paper';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { ScreenBackground } from '../../src/presentation/components/common/ScreenBackground';
import { SPACING, TYPOGRAPHY, BORDER_RADIUS } from '../../src/shared/constants/theme';
import { useAuth } from '../../src/presentation/hooks/useAuth';
import { usePendingRegistrationStore } from '../../src/presentation/stores/pendingRegistrationStore';
import {
  ANALYSIS_CONSENT_TEXT,
  ANALYSIS_CONSENT_VERSION,
} from '../../src/shared/constants/consent';

const FS_INPUT_BG   = 'rgba(14, 27, 20, 0.85)';
const FS_BORDER     = 'rgba(219, 90, 150, 0.45)';
const FS_TEXT       = '#E7F2EB';
const FS_TEXT_MUTED = '#95B8A8';
const FS_GREEN      = '#52B788';

export default function ConsentScreen() {
  const { register: registerUser, isLoading } = useAuth();
  const pending = usePendingRegistrationStore((s) => s.pending);
  const clearPending = usePendingRegistrationStore((s) => s.clearPending);
  const [submitting, setSubmitting] = useState(false);

  const handleAccept = async () => {
    if (!pending) {
      // Arrivé directement sur cet écran sans passer par le formulaire
      // (ex: retour arrière puis navigation directe) — on ramène vers
      // le formulaire plutôt que de créer un compte sans ses données.
      router.replace('/(auth)/register');
      return;
    }
    setSubmitting(true);
    try {
      await registerUser(pending.data, pending.antiBot, {
        analysisConsentAt: new Date().toISOString(),
        analysisConsentVersion: ANALYSIS_CONSENT_VERSION,
      });
      clearPending();
      // L'inscription ne connecte plus automatiquement l'utilisateur
      // (voir useAuth.ts : logout() est appelé juste après la création
      // du profil). On revient donc explicitement sur l'écran login,
      // avec un message de confirmation.
      router.replace('/(auth)/login');
      themedAlert.alert('Compte créé', 'Votre compte a été créé avec succès. Vous pouvez maintenant vous connecter.');
    } catch (error: any) {
      themedAlert.alert("Erreur d'inscription", error.message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDecline = () => {
    // Refuser le consentement annule l'inscription : aucun compte n'est
    // créé sans cette acceptation, il n'y a pas de version dégradée de
    // l'app qui contournerait l'analyse.
    clearPending();
    router.replace('/(auth)/register');
  };

  return (
    <ScreenBackground
      source={require('../../assets/images/backgrounds/authentification.png')}
      darken={false}
      style={styles.background}
    >
      <View style={styles.container}>
        <ScrollView contentContainerStyle={styles.scroll}>
          <Animated.View entering={FadeInDown.delay(100)} style={styles.header}>
            <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
              <Ionicons name="arrow-back" size={24} color={FS_TEXT} />
            </TouchableOpacity>
            <Text style={styles.title}>Avant de continuer</Text>
            <Text style={styles.subtitle}>
              Une dernière étape, importante, avant de créer votre compte.
            </Text>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(200)} style={styles.card}>
            <View style={styles.iconRow}>
              <Ionicons name="analytics-outline" size={22} color={FS_GREEN} />
              <Text style={styles.cardTitle}>Analyse IA de vos conversations</Text>
            </View>
            <Text style={styles.bodyText}>{ANALYSIS_CONSENT_TEXT}</Text>

            <View style={styles.divider} />

            <View style={styles.pointRow}>
              <Ionicons name="close-circle-outline" size={18} color={FS_TEXT_MUTED} />
              <Text style={styles.pointText}>
                Ce n'est pas un chiffrement de bout en bout : vos messages sont lisibles côté serveur.
              </Text>
            </View>
            <View style={styles.pointRow}>
              <Ionicons name="trash-outline" size={18} color={FS_TEXT_MUTED} />
              <Text style={styles.pointText}>
                Il n'existe pas d'option pour désactiver l'analyse tout en gardant votre compte :
                la seule façon d'arrêter l'analyse et de supprimer les données déjà générées
                est de supprimer votre compte, à tout moment, depuis les paramètres.
              </Text>
            </View>
          </Animated.View>

          <Animated.View entering={FadeInDown.delay(300)} style={styles.actions}>
            <Button
              mode="contained"
              onPress={handleAccept}
              loading={isLoading || submitting}
              disabled={isLoading || submitting}
              style={styles.acceptButton}
              buttonColor={FS_GREEN}
              contentStyle={styles.buttonContent}
            >
              J'accepte et je crée mon compte
            </Button>
            <TouchableOpacity onPress={handleDecline} disabled={isLoading || submitting}>
              <Text style={styles.declineText}>Je refuse (annuler l'inscription)</Text>
            </TouchableOpacity>
          </Animated.View>
        </ScrollView>
      </View>
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  background: { flex: 1 },
  container: { flex: 1 },
  scroll: { flexGrow: 1, padding: SPACING.lg, paddingTop: SPACING.xl },
  header: { marginBottom: SPACING.lg },
  backButton: { marginBottom: SPACING.md, alignSelf: 'flex-start' },
  title: {
    fontSize: TYPOGRAPHY.size.xxl,
    fontWeight: '700',
    color: FS_TEXT,
    marginBottom: SPACING.xs,
  },
  subtitle: {
    fontSize: TYPOGRAPHY.size.sm,
    color: FS_TEXT_MUTED,
  },
  card: {
    backgroundColor: FS_INPUT_BG,
    borderRadius: BORDER_RADIUS.lg,
    borderWidth: 1,
    borderColor: FS_BORDER,
    padding: SPACING.md,
    marginBottom: SPACING.lg,
  },
  iconRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.xs,
    marginBottom: SPACING.sm,
  },
  cardTitle: {
    fontSize: TYPOGRAPHY.size.md,
    fontWeight: '700',
    color: FS_TEXT,
  },
  bodyText: {
    fontSize: TYPOGRAPHY.size.sm,
    color: FS_TEXT,
    lineHeight: 21,
  },
  divider: {
    height: 1,
    backgroundColor: FS_BORDER,
    marginVertical: SPACING.md,
  },
  pointRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: SPACING.xs,
    marginBottom: SPACING.sm,
  },
  pointText: {
    flex: 1,
    fontSize: TYPOGRAPHY.size.xs,
    color: FS_TEXT_MUTED,
    lineHeight: 18,
  },
  actions: { gap: SPACING.md },
  acceptButton: { borderRadius: BORDER_RADIUS.md },
  buttonContent: { paddingVertical: SPACING.xs },
  declineText: {
    textAlign: 'center',
    fontSize: TYPOGRAPHY.size.sm,
    color: FS_TEXT_MUTED,
    textDecorationLine: 'underline',
  },
});
