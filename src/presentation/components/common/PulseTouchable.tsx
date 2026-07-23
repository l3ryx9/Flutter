/**
 * PulseTouchable — enveloppe générique pour donner à n'importe quel élément
 * (icône de header, item de liste, badge...) le même retour tactile que les
 * boutons Bubble3D : légère compression au toucher, puis petit rebond
 * ("pulsation") au relâchement, plus un retour haptique léger.
 *
 * Utile pour les éléments qui ne sont pas des boutons ronds/pilule classiques
 * (donc pas Bubble3DButton) mais qui doivent quand même se sentir "vivants"
 * au toucher : icône d'action dans un header, ligne de liste, chip...
 */
import React from 'react';
import { TouchableWithoutFeedback, type StyleProp, type ViewStyle } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';

interface PulseTouchableProps {
  onPress?: () => void;
  onLongPress?: () => void;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  haptic?: boolean;
  children: React.ReactNode;
  accessibilityLabel?: string;
  accessibilityRole?: 'button' | 'none';
}

export function PulseTouchable({
  onPress,
  onLongPress,
  disabled,
  style,
  haptic = true,
  children,
  accessibilityLabel,
  accessibilityRole = 'button',
}: PulseTouchableProps) {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = () => {
    scale.value = withSpring(0.9, { damping: 14, stiffness: 240 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1.05, { damping: 6, stiffness: 300, mass: 0.5 }, () => {
      scale.value = withSpring(1, { damping: 9, stiffness: 260 });
    });
  };

  const handlePress = () => {
    if (disabled) return;
    if (haptic) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
    onPress?.();
  };

  return (
    <TouchableWithoutFeedback
      onPress={handlePress}
      onLongPress={onLongPress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      disabled={disabled}
      accessibilityRole={accessibilityRole}
      accessibilityLabel={accessibilityLabel}
    >
      <Animated.View style={[animatedStyle, disabled && { opacity: 0.45 }, style]}>
        {children}
      </Animated.View>
    </TouchableWithoutFeedback>
  );
}
