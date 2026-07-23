/**
 * Route d'entrée « / » — Expo Router
 *
 * Rôle : jouer l'intro animée « YouMe » PUIS rediriger vers le bon groupe
 * de routes selon l'état d'authentification.
 *
 * ⚠️ Correctif « on ne voit pas l'intro » :
 *   Avant, l'intro n'était affichée que tant que `isInitialized` était faux.
 *   Or Supabase vérifie la session en quelques centaines de millisecondes —
 *   l'app redirigeait donc vers le login/accueil avant même que la première
 *   lettre n'apparaisse. Désormais l'intro est TOUJOURS jouée en entier
 *   (état local `introDone`), et la redirection n'a lieu que quand
 *   l'animation est finie ET l'auth déterminée.
 *
 * Style : fond tropical en dégradé (lagon → jungle → coucher de soleil)
 * avec le motif ananas en filigrane. Pas d'image statique — uniquement
 * l'animation des lettres.
 */
import { Redirect } from 'expo-router';
import React, { useCallback, useState } from 'react';
import { StyleSheet } from 'react-native';
import { useAuthStore } from '@presentation/stores/authStore';
import { ScreenBackground } from '../src/presentation/components/common/ScreenBackground';
import { AnimatedYouMe } from '@presentation/components/common/AnimatedYouMe';

export default function Index() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isInitialized   = useAuthStore((s) => s.isInitialized);
  const [introDone, setIntroDone] = useState(false);

  const handleIntroDone = useCallback(() => setIntroDone(true), []);

  // L'intro se joue toujours en entier, même si l'auth est déjà prête.
  if (!isInitialized || !introDone) {
    return (
      <ScreenBackground
        source={require('../assets/images/backgrounds/autres.png')}
        style={styles.splash}
      >
        <AnimatedYouMe color="#F4C63A" onDone={handleIntroDone} />
      </ScreenBackground>
    );
  }

  return (
    <Redirect href={isAuthenticated ? '/(app)/(tabs)' : '/(auth)/login'} />
  );
}

const styles = StyleSheet.create({
  splash: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
