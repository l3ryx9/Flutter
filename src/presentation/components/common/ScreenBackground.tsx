/**
 * ScreenBackground — image de fond plein écran + filtre assombrissant optionnel
 *
 * Composant partagé utilisé par tous les écrans de l'app pour afficher une
 * image de fond (jungle/ananas par catégorie) avec un voile noir semi-transparent
 * par-dessus (sauf pour Connexion/Inscription), afin de garder le texte et les
 * composants lisibles.
 *
 * Utilisation par catégorie :
 * - ONGLETS PRINCIPAUX (Accueil, Contacts, Recherche, Paramètres) → avec filtre
 * - CHAT (Chat, Analyse, Insights, Flags, Localisation) → avec filtre
 * - AUTHENTIFICATION (Connexion, Inscription, Oubli MDP, Réinitialisation) → SANS filtre (login/register)
 * - AUTRES (Intro, Suppression compte, Journal de debug) → avec filtre
 */
import React from 'react';
import {
  ImageBackground,
  View,
  StyleSheet,
  type ImageSourcePropType,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

interface ScreenBackgroundProps {
  /** Image de fond (require('...png')) */
  source: ImageSourcePropType;
  /** Applique un filtre noir semi-transparent par-dessus l'image (défaut : true) */
  darken?: boolean;
  /** Opacité du filtre noir, de 0 à 1 (défaut : 0.55) */
  overlayOpacity?: number;
  /** Style additionnel pour le conteneur plein écran */
  style?: StyleProp<ViewStyle>;
  children?: React.ReactNode;
}

export function ScreenBackground({
  source,
  darken = true,
  overlayOpacity = 0.55,
  style,
  children,
}: ScreenBackgroundProps) {
  return (
    <ImageBackground source={source} style={[styles.background, style]} resizeMode="cover">
      {darken && (
        <View
          pointerEvents="none"
          style={[
            StyleSheet.absoluteFillObject,
            { backgroundColor: `rgba(0, 0, 0, ${overlayOpacity})` },
          ]}
        />
      )}
      {children}
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  background: {
    flex: 1,
  },
});
