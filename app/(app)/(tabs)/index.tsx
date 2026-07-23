/**
 * Écran Principal — Liste des Conversations
 */
import React, { useCallback, useMemo } from 'react';
import {
  View,
  Text,
  Image,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
  Alert,
} from 'react-native';
import { router } from 'expo-router';
import Animated, { FadeInUp, Layout } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { useYoumeColors, YoumeColors, SPACING, TYPOGRAPHY, BORDER_RADIUS } from '../../../src/shared/constants/theme';
import { Avatar } from '../../../src/presentation/components/common/Avatar';
import { ScreenBackground } from '../../../src/presentation/components/common/ScreenBackground';
import { formatConversationDate } from '../../../src/shared/utils/dateUtils';
import { useConversationStore } from '../../../src/presentation/stores/conversationStore';
import type { ConversationWithPartner } from '../../../src/domain/entities/Conversation';
import { messageRepository } from '../../../src/infrastructure/supabase/MessageRepository';
import { isEffectivelyOnline } from '../../../src/shared/utils/presence';

export default function ConversationsScreen() {
  const { conversations, removeConversation, isLoading } = useConversationStore();
  const [refreshing, setRefreshing] = React.useState(false);
  const colors = useYoumeColors();
  const styles = useMemo(() => getStyles(colors), [colors]);

  const handleDeleteConversation = useCallback((item: ConversationWithPartner) => {
    Alert.alert(
      'Supprimer la conversation',
      `Voulez-vous supprimer la conversation avec ${item.partnerDisplayName} ?\n\nLe contact restera dans votre liste de contacts.`,
      [
        {
          text: 'Supprimer',
          style: 'destructive',
          onPress: async () => {
            try {
              // Vide la conversation (messages + last_message) sans
              // supprimer la ligne `conversations` ni la relation
              // `partners` — voir clearConversation() pour le détail.
              // Le contact réapparaît ainsi dans l'onglet Contacts.
              await messageRepository.clearConversation(item.id);
              removeConversation(item.id);
            } catch {
              Alert.alert('Erreur', 'Impossible de supprimer la conversation.');
            }
          },
        },
        { text: 'Annuler', style: 'cancel' },
      ]
    );
  }, [removeConversation]);

  const renderItem = useCallback(
    ({ item, index }: { item: ConversationWithPartner; index: number }) => (
      <Animated.View entering={FadeInUp.delay(index * 30)} layout={Layout.springify()}>
        <TouchableOpacity
          style={styles.item}
          onPress={() => router.push(`/(app)/chat/${item.id}`)}
          onLongPress={() => handleDeleteConversation(item)}
          delayLongPress={400}
          activeOpacity={0.7}
        >
          <Avatar
            displayName={item.partnerDisplayName}
            photoURL={item.partnerPhotoURL}
            size={52}
            isOnline={isEffectivelyOnline(item.partnerIsOnline, item.partnerLastSeen)}
          />
          <View style={styles.itemContent}>
            <View style={styles.itemHeader}>
              <Text style={styles.itemName} numberOfLines={1}>
                {item.partnerDisplayName}
              </Text>
              <Text style={styles.itemTime}>
                {item.lastMessage ? formatConversationDate(
                  item.lastMessage.createdAt instanceof Date
                    ? item.lastMessage.createdAt
                    : new Date(String(item.lastMessage.createdAt))
                ) : ''}
              </Text>
            </View>
            <View style={styles.itemFooter}>
              <Text style={styles.itemLastMessage} numberOfLines={1}>
                {item.lastMessage?.type === 'voice'
                  ? '🎤 Message vocal'
                  : item.lastMessage?.content ?? 'Commencer la conversation'}
              </Text>
              {item.unreadCount > 0 && (
                <View style={styles.unreadBadge}>
                  <Text style={styles.unreadText}>{item.unreadCount}</Text>
                </View>
              )}
            </View>
          </View>
        </TouchableOpacity>
      </Animated.View>
    ),
    [styles, handleDeleteConversation]
  );

  return (
    <ScreenBackground
      source={require('../../../assets/images/backgrounds/onglets-principaux.png')}
      style={styles.container}
    >
      {/* ── Header — logo YouMe ── */}
      <View style={styles.header}>
        <Image
          source={require('../../../assets/images/you-me-logo.webp')}
          style={styles.headerLogo}
          resizeMode="contain"
        />
      </View>

      {/* Liste des conversations */}
      <FlatList
        data={conversations}
        renderItem={renderItem}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => setRefreshing(false)}
            tintColor={colors.primary}
          />
        }
        ListEmptyComponent={
          <View style={styles.empty}>
            <Ionicons name="chatbubbles-outline" size={64} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>Aucune conversation</Text>
            <Text style={styles.emptySubtitle}>
              Ajoutez des partenaires pour commencer à discuter
            </Text>
          </View>
        }
        ItemSeparatorComponent={() => <View style={styles.separator} />}
        contentContainerStyle={{ paddingBottom: 72 }}
      />
    </ScreenBackground>
  );
}

function getStyles(colors: YoumeColors) {
  return StyleSheet.create({
    container: { flex: 1, backgroundColor: 'transparent' },

    // ── Header ──
    header: {
      backgroundColor: 'transparent',
      paddingTop: 48,
      paddingBottom: 14,
      paddingHorizontal: SPACING.lg,
      alignItems: 'center',
      justifyContent: 'center',
    },
    headerLogo: {
      width: '55%',
      maxWidth: 220,
      aspectRatio: 800 / 323,
      alignSelf: 'center',
      opacity: 1,
    },

    // ── Liste ──
    item: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      gap: SPACING.md,
      // Un peu transparent : laisse deviner la photo de fond derrière chaque ligne
      backgroundColor: 'rgba(10, 15, 8, 0.78)',
    },
    itemContent: { flex: 1 },
    itemHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
    itemName: { fontSize: TYPOGRAPHY.size.md, fontWeight: '600', color: colors.textPrimary, flex: 1 },
    itemTime: { fontSize: TYPOGRAPHY.size.xs, color: colors.textMuted, marginLeft: SPACING.sm },
    itemFooter: { flexDirection: 'row', alignItems: 'center', marginTop: 3 },
    itemLastMessage: { flex: 1, fontSize: TYPOGRAPHY.size.sm, color: colors.textSecondary },
    unreadBadge: {
      backgroundColor: colors.primary,
      borderRadius: 10,
      minWidth: 20,
      height: 20,
      justifyContent: 'center',
      alignItems: 'center',
      paddingHorizontal: 4,
    },
    unreadText: { fontSize: TYPOGRAPHY.size.xs, color: '#FFFFFF', fontWeight: '700' },
    separator: { height: 1, backgroundColor: colors.divider, marginLeft: 80 },
    empty: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingTop: 80, gap: SPACING.md },
    emptyTitle: { fontSize: TYPOGRAPHY.size.lg, color: colors.textSecondary, fontWeight: '600' },
    emptySubtitle: { fontSize: TYPOGRAPHY.size.sm, color: colors.textMuted, textAlign: 'center' },
  });
            }
