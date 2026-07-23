/**
 * applyGlobalFont — force la police Inter (gras) sur TOUT le texte de
 * l'application, sans avoir à modifier chaque style individuellement.
 *
 * Pourquoi pas simplement `Text.defaultProps.style` ?
 * → `defaultProps` n'est utilisé par React que lorsque le composant ne
 *   reçoit AUCUNE valeur pour cette prop. Or la quasi-totalité des <Text>
 *   de ce projet reçoivent déjà un `style={...}` (même sans fontFamily),
 *   ce qui rend `defaultProps.style` inopérant dans la pratique.
 *
 * On patche donc directement la méthode `render` de Text/TextInput pour
 * injecter `fontFamily: Inter_700Bold` en PREMIER dans le tableau de style
 * du rendu final. Comme les styles React Native se fusionnent de gauche à
 * droite (les entrées suivantes gagnent sur les clés en conflit), tout
 * `fontFamily` explicitement défini par un écran (ex: les styles
 * "monospace" du journal de debug ou des coordonnées GPS) continue de
 * gagner — seul le texte qui ne précise rien récupère Inter Bold.
 */
import React from 'react';
import { Text, TextInput } from 'react-native';

let applied = false;

export function applyGlobalFont(fontFamily: string) {
  if (applied) return;
  applied = true;

  patchComponent(Text as any, fontFamily);
  patchComponent(TextInput as any, fontFamily);
}

function patchComponent(Component: any, fontFamily: string) {
  try {
    const originalRender = Component.render;
    if (typeof originalRender === 'function') {
      Component.render = function patchedRender(...args: any[]) {
        const origin = originalRender.apply(this, args);
        if (!origin || !origin.props) return origin;
        return React.cloneElement(origin, {
          style: [{ fontFamily }, origin.props.style],
        });
      };
    }
  } catch {
    // Si l'implémentation interne de RN change et que ce patch échoue,
    // on ne casse jamais l'app — le texte retombe simplement sur la
    // police système (fallback silencieux).
  }

  // Filet de sécurité additionnel (sans effet dans la plupart des cas
  // puisque presque tous les <Text> passent déjà un `style`, mais gratuit
  // et sans risque pour les rares cas où aucun style n'est fourni).
  try {
    Component.defaultProps = Component.defaultProps || {};
    Component.defaultProps.style = [{ fontFamily }, Component.defaultProps.style];
  } catch {
    // idem — jamais bloquant
  }
}
