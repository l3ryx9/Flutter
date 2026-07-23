/**
 * BouncyPressable — bouton avec effet interactif « 3D » à la pression
 *
 * À l'appui : le bouton s'enfonce (scale + légère rotation), puis rebondit
 * avec un ressort à la relâche. Purement Reanimated côté UI — aucun pont
 * worklet → JS, donc aucun risque de crash (même contrainte que l'intro).
 */
import React from 'react';
import { Pressable, type PressableProps, type ViewStyle, type StyleProp } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
} from 'react-native-reanimated';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

interface Props extends PressableProps {
  style?: StyleProp<ViewStyle>;
  /** Échelle en position enfoncée (défaut 0.86). */
  pressedScale?: number;
  children?: React.ReactNode;
}

export function BouncyPressable({
  style,
  pressedScale = 0.86,
  onPressIn,
  onPressOut,
  children,
  ...rest
}: Props) {
  const scale = useSharedValue(1);
  const rotate = useSharedValue(0);

  const animStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }, { rotate: `${rotate.value}deg` }],
  }));

  return (
    <AnimatedPressable
      {...rest}
      style={[style, animStyle]}
      onPressIn={(e) => {
        scale.value = withTiming(pressedScale, { duration: 90 });
        rotate.value = withTiming(-4, { duration: 90 });
        onPressIn?.(e);
      }}
      onPressOut={(e) => {
        scale.value = withSpring(1, { damping: 7, stiffness: 220, mass: 0.6 });
        rotate.value = withSpring(0, { damping: 6, stiffness: 200 });
        onPressOut?.(e);
      }}
    >
      {children}
    </AnimatedPressable>
  );
}
