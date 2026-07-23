/**
 * ThemePicker — sélecteur des 8 thèmes « Tropical Paradise »
 *
 * Chaque thème est une pastille « 3D » : sphère en dégradé (3 couleurs du
 * thème) avec un reflet lumineux en haut à gauche et une ombre portée.
 * Effet interactif : la pastille s'enfonce puis rebondit à la pression
 * (BouncyPressable), et le thème sélectionné est entouré d'un anneau
 * + agrandi en douceur.
 */
import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, { useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { TROPICAL_THEMES, useYoumeColors, SPACING, TYPOGRAPHY } from '@shared/constants/theme';
import { useUIStore } from '@presentation/stores/uiStore';
import { BouncyPressable } from './BouncyPressable';

const SWATCH = 54;

function Swatch({
  themeId,
  name,
  emoji,
  gradient,
  isDark,
  selected,
  ringColor,
  labelColor,
  onSelect,
}: {
  themeId: string;
  name: string;
  emoji: string;
  gradient: [string, string, string];
  isDark: boolean;
  selected: boolean;
  ringColor: string;
  labelColor: string;
  onSelect: (id: string, isDark: boolean) => void;
}) {
  const selStyle = useAnimatedStyle(() => ({
    transform: [{ scale: withSpring(selected ? 1.12 : 1, { damping: 9, stiffness: 180 }) }],
  }), [selected]);

  return (
    <View style={styles.item}>
      <Animated.View style={selStyle}>
        <BouncyPressable
          onPress={() => onSelect(themeId, isDark)}
          style={[styles.swatchWrap, selected && { borderColor: ringColor, borderWidth: 2.5 }]}
          accessibilityLabel={`Thème ${name}`}
        >
          <LinearGradient
            colors={gradient}
            start={{ x: 0.1, y: 0.1 }}
            end={{ x: 0.9, y: 0.95 }}
            style={styles.swatch}
          >
            {/* Reflet « 3D » */}
            <View style={styles.gloss} />
            <Text style={styles.emoji}>{emoji}</Text>
            {selected && (
              <View style={styles.check}>
                <Ionicons name="checkmark" size={12} color="#FFFFFF" />
              </View>
            )}
          </LinearGradient>
        </BouncyPressable>
      </Animated.View>
      <Text style={[styles.label, { color: labelColor }]} numberOfLines={1}>
        {name}
      </Text>
    </View>
  );
}

export function ThemePicker() {
  const colors = useYoumeColors();
  const themeId = useUIStore((s) => s.themeId);
  const setTheme = useUIStore((s) => s.setTheme);

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.row}
    >
      {TROPICAL_THEMES.map((t) => (
        <Swatch
          key={t.id}
          themeId={t.id}
          name={t.name}
          emoji={t.emoji}
          gradient={t.swatch}
          isDark={t.isDark}
          selected={themeId === t.id}
          ringColor={colors.textLink}
          labelColor={themeId === t.id ? colors.textPrimary : colors.textMuted}
          onSelect={setTheme}
        />
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  row: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.sm,
    gap: SPACING.md,
  },
  item: {
    alignItems: 'center',
    width: SWATCH + 22,
  },
  swatchWrap: {
    borderRadius: (SWATCH + 8) / 2,
    padding: 2,
    borderWidth: 2.5,
    borderColor: 'transparent',
    // Ombre portée — effet « posé » 3D
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 5,
    elevation: 6,
  },
  swatch: {
    width: SWATCH,
    height: SWATCH,
    borderRadius: SWATCH / 2,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  gloss: {
    position: 'absolute',
    top: 5,
    left: 9,
    width: SWATCH * 0.42,
    height: SWATCH * 0.26,
    borderRadius: SWATCH,
    backgroundColor: 'rgba(255,255,255,0.35)',
    transform: [{ rotate: '-25deg' }],
  },
  emoji: {
    fontSize: 22,
  },
  check: {
    position: 'absolute',
    bottom: 3,
    right: 3,
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: 'rgba(0,0,0,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    marginTop: 6,
    fontSize: TYPOGRAPHY.size.xs,
    textAlign: 'center',
  },
});
