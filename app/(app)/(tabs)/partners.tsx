/**
 * Écran Partenaires
 * — Barre de recherche en haut
 * — Deux onglets larges : Contacts | Invitations
 */
import React, { useState, useMemo, useCallback, useRef } from 'react';
import { themedAlert } from '@presentation/components/common/ThemedAlert';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ActivityIndicator } from 'react-native-paper';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInUp, FadeOutUp, FadeInDown } from 'react-native-reanimated';
import { ScreenBackground } from '../../../src/presentation/components/common/ScreenBackground';
import { Bubble3DButton } from '../../../src/presentation/components/common/Bubble3DButton';
import { PulseTouchable } from '../../../src/presentation/components/common/PulseTouchable';
import { useYoumeColors, YoumeColors, SPACING, TYPOGRAPHY, BORDER_RADIUS } from '../../../src/shared/constants/theme';
import { Avatar } from '../../../src/presentation/components/common/Avatar';
import { useAuthStore } from '../../../src/presentation/stores/authStore';
import { usePartnerStore } from '../../../src/presentation/stores/partnerStore';
import { useConversationStore } from '../../../src/presentation/stores/conversationStore';
import { partnerRepository } from '../../../src/infrastructure/supabase/PartnerRepository';
import type { Partner, PartnerRequest } from '../../../src/domain/entities/Partner';
import { isEffectivelyOnline } from '../../../src/shared/utils/presence';

type Tab = 'contacts' | 'invitations';

export default function PartnersScreen() {
  const { user } = useAuthStore();
  const {
    partners,
    pendingRequests,
    isLoading,
    removePartner: removePartnerFromStore,
  } = usePartnerStore();
  const { conversations } = useConversationStore();

  // Un contact ayant déjà une conversation "active" (visible dans l'onglet
  // Messages, càd avec au moins un message envoyé) n'est plus affiché ici —
  // il apparaît dans Messages à la place. Si cette conversation est ensuite
  // supprimée (voir index.tsx : clearConversation, qui ne supprime jamais
  // la relation partners), le contact redevient visible ici.
  const activeConversationIds = useMemo(
    () => new Set(conversations.map((c) => c.id)),
    [conversations]
  );
  const visiblePartners = useMemo(
    () => partners.filter((p) => !activeConversationIds.has(p.conversationId)),
    [partners, activeConversationIds]
  );

  const [activeTab, setActiveTab] = useState<Tab>('contacts');
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [sendingRequest, setSendingRequest] = useState<string | null>(null);
  const searchInputRef = useRef<any>(null);
  const insets = useSafeAreaInsets();
  const colors = useYoumeColors();
  const styles = useMemo(() => getStyles(colors), [colors]);

  const closeSearch = useCallback(() => {
    setIsSearchOpen(false);
    setSearchQuery('');
    setHasSearched(false);
    setSearchResults([]);
  }, []);

  const toggleSearch = useCallback(() => {
    setIsSearchOpen((open) => {
      const next = !open;
      if (!next) {
        setSearchQuery('');
        setHasSearched(false);
        setSearchResults([]);
      } else {
        // Ouvre le clavier une fois le champ monté
        setTimeout(() => searchInputRef.current?.focus(), 150);
      }
      return next;
    });
  }, []);

  const handleSearch = useCallback(async () => {
    const q = searchQuery.trim();
    if (!q || q.length < 2) return;
    setIsSearching(true);
    setHasSearched(true);
    try {
      const { userRepository } = await import('../../../src/infrastructure/supabase/UserRepository');
      const results = await userRepository.searchUsersByUsername(q, user?.id ?? '');
      setSearchResults(results.filter((r) => r.id !== user?.id));
    } catch {
      themedAlert.alert('Erreur', 'Recherche impossible');
      setSearchResults([]);
    } finally {
      setIsSearching(false);
    }
  }, [searchQuery, user?.id]);

  const handleSendRequest = async (receiverUsername: string) => {
    if (!user) return;
    setSendingRequest(receiverUsername);
    try {
      await partnerRepository.sendPartnerRequest({ senderId: user.id, receiverUsername });
      themedAlert.alert('Demande envoyée', `Demande envoyée à @${receiverUsername}`);
    } catch (error: any) {
      themedAlert.alert('Erreur', error.message);
    } finally {
      setSendingRequest(null);
    }
  };

  const handleAccept = async (request: PartnerRequest) => {
    try {
      await partnerRepository.acceptPartnerRequest(request.id);
    } catch (error: any) {
      themedAlert.alert('Erreur', error.message);
    }
  };

  const handleReject = async (request: PartnerRequest) => {
    try {
      await partnerRepository.rejectPartnerRequest(request.id);
    } catch (error: any) {
      themedAlert.alert('Erreur', error.message);
    }
  };

  const handleRemovePartner = (partner: Partner) => {
    themedAlert.alert(
      'Supprimer le contact',
      `Voulez-vous supprimer @${partner.partnerUsername} ?\n\nSa conversation et son analyse IA seront également effacées.`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Supprimer',
          style: 'destructive',
          onPress: async () => {
            if (!user) return;
            try {
              await partnerRepository.removePartner(user.id, partner.partnerId);
              // Mise à jour immédiate de la liste locale — sans ça, le
              // contact supprimé reste affiché jusqu'au prochain rechargement
              // de l'écran (la suppression en base ne déclenche pas toujours
              // l'événement realtime côté client).
              removePartnerFromStore(partner.partnerId);
            } catch (error: any) {
              themedAlert.alert('Erreur', error.message ?? 'Suppression impossible');
            }
          },
        },
      ]
    );
  };

  const renderPartner = useCallback(({ item, index }: { item: Partner; index: number }) => (
    <Animated.View entering={FadeInUp.delay(index * 25)}>
      <TouchableOpacity
        style={styles.item}
        onPress={() => router.push(`/(app)/chat/${item.conversationId}`)}
        activeOpacity={0.75}
      >
        <Avatar
          displayName={item.partnerDisplayName}
          photoURL={item.partnerPhotoURL}
          size={50}
          isOnline={isEffectivelyOnline(item.partnerIsOnline, item.partnerLastSeen)}
        />
        <View style={styles.itemContent}>
          <Text style={styles.itemName}>{item.partnerDisplayName}</Text>
          <Text style={styles.itemUsername}>@{item.partnerUsername}</Text>
        </View>
        <TouchableOpacity
          onPress={() => handleRemovePartner(item)}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          style={styles.deleteButton}
        >
          <Ionicons name="close-circle" size={24} color={colors.error} />
        </TouchableOpacity>
      </TouchableOpacity>
    </Animated.View>
  ), [styles, colors.error]);

  const renderRequest = useCallback(({ item }: { item: PartnerRequest }) => (
    <View style={styles.requestItem}>
      <Avatar displayName={item.senderDisplayName} photoURL={item.senderPhotoURL} size={48} />
      <View style={styles.itemContent}>
        <Text style={styles.itemName}>{item.senderDisplayName}</Text>
        <Text style={styles.itemUsername}>@{item.senderUsername}</Text>
      </View>
      <View style={styles.requestActions}>
        <TouchableOpacity style={styles.acceptButton} onPress={() => handleAccept(item)}>
          <Ionicons name="checkmark" size={18} color="#FFFFFF" />
        </TouchableOpacity>
        <TouchableOpacity style={styles.rejectButton} onPress={() => handleReject(item)}>
          <Ionicons name="close" size={18} color="#FFFFFF" />
        </TouchableOpacity>
      </View>
    </View>
  ), [styles]);

  const renderSearchResult = useCallback(({ item }: { item: any }) => (
    <View style={styles.item}>
      <Avatar displayName={item.displayName} photoURL={item.photoURL} size={48} />
      <View style={styles.itemContent}>
        <Text style={styles.itemName}>{item.displayName}</Text>
        <Text style={styles.itemUsername}>@{item.username}</Text>
      </View>
      <TouchableOpacity
        style={styles.addButton}
        onPress={() => handleSendRequest(item.username)}
        disabled={sendingRequest === item.username}
      >
        {sendingRequest === item.username ? (
          <ActivityIndicator size="small" color="#FFFFFF" />
        ) : (
          <Ionicons name="person-add" size={18} color="#FFFFFF" />
        )}
      </TouchableOpacity>
    </View>
  ), [styles, sendingRequest]);

  // Détermine le contenu à afficher
  const showingSearchResults = searchQuery.trim().length >= 2 && hasSearched;

  return (
    <ScreenBackground source={require('../../../assets/images/backgrounds/onglets-principaux.png')}>
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
      {/* ── Titre de l'écran (toujours visible, gère l'encoche) ── */}
      <View style={[styles.topBar, { paddingTop: insets.top + SPACING.sm }]}>
        <Text style={styles.topBarTitle}>Contacts</Text>
      </View>

      {/* ── Barre de recherche — révélée par le bouton + ── */}
      {isSearchOpen && (
        <Animated.View entering={FadeInDown.duration(200)} exiting={FadeOutUp.duration(150)} style={styles.searchWrapper}>
          <View style={styles.searchBar}>
            <Ionicons name="search" size={18} color={colors.placeholder} style={styles.searchIcon} />
            <TextInput
              ref={searchInputRef}
              style={styles.searchInput}
              placeholder="Rechercher un contact..."
              placeholderTextColor={colors.placeholder}
              value={searchQuery}
              onChangeText={(v) => {
                setSearchQuery(v);
                if (!v.trim()) { setHasSearched(false); setSearchResults([]); }
              }}
              onSubmitEditing={handleSearch}
              autoCapitalize="none"
              returnKeyType="search"
            />
            {isSearching ? (
              <ActivityIndicator size="small" color={colors.primary} style={{ marginRight: 8 }} />
            ) : searchQuery.length > 0 ? (
              <TouchableOpacity
                onPress={() => { setSearchQuery(''); setHasSearched(false); setSearchResults([]); }}
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
              >
                <Ionicons name="close-circle" size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
              </TouchableOpacity>
            ) : null}
            <PulseTouchable onPress={closeSearch} style={styles.searchCloseBtn} accessibilityLabel="Fermer la recherche">
              <Ionicons name="chevron-up" size={18} color={colors.textMuted} />
            </PulseTouchable>
          </View>
        </Animated.View>
      )}

      {showingSearchResults ? (
        /* ── Résultats de recherche ── */
        <View style={styles.flex}>
          <FlatList
            data={searchResults}
            keyExtractor={(item) => item.id}
            renderItem={renderSearchResult}
            ItemSeparatorComponent={() => <View style={styles.separator} />}
            contentContainerStyle={styles.listContent}
            ListEmptyComponent={
              <View style={styles.empty}>
                <Ionicons name="person-outline" size={48} color={colors.textMuted} />
                <Text style={styles.emptyText}>Aucun résultat</Text>
                <Text style={styles.emptySubtext}>Essayez un autre username</Text>
              </View>
            }
          />
        </View>
      ) : (
        <>
          {/* ── Onglets larges ── */}
          <View style={styles.tabs}>
            <PulseTouchable
              style={[styles.tab, activeTab === 'contacts' && styles.tabActive]}
              onPress={() => setActiveTab('contacts')}
            >
              <Ionicons
                name="people"
                size={20}
                color={activeTab === 'contacts' ? colors.primary : colors.textMuted}
                style={styles.tabIcon}
              />
              <Text style={[styles.tabText, activeTab === 'contacts' && styles.tabTextActive]}>
                Contacts
              </Text>
              {visiblePartners.length > 0 && (
                <View style={[styles.tabBadge, activeTab === 'contacts' && styles.tabBadgeActive]}>
                  <Text style={[styles.tabBadgeText, activeTab === 'contacts' && styles.tabBadgeTextActive]}>
                    {visiblePartners.length}
                  </Text>
                </View>
              )}
            </PulseTouchable>

            <View style={styles.tabDivider} />

            <PulseTouchable
              style={[styles.tab, activeTab === 'invitations' && styles.tabActive]}
              onPress={() => setActiveTab('invitations')}
            >
              <Ionicons
                name="mail"
                size={20}
                color={activeTab === 'invitations' ? colors.primary : colors.textMuted}
                style={styles.tabIcon}
              />
              <Text style={[styles.tabText, activeTab === 'invitations' && styles.tabTextActive]}>
                Invitations
              </Text>
              {pendingRequests.length > 0 && (
                <View style={[styles.tabBadge, styles.tabBadgeAlert]}>
                  <Text style={styles.tabBadgeAlertText}>{pendingRequests.length}</Text>
                </View>
              )}
            </PulseTouchable>
          </View>

          {/* ── Contenu ── */}
          <View style={styles.flex}>
            {activeTab === 'contacts' ? (
              <FlatList
                data={visiblePartners}
                renderItem={renderPartner}
                keyExtractor={(item) => item.partnerId}
                ItemSeparatorComponent={() => <View style={styles.separator} />}
                contentContainerStyle={styles.listContent}
                ListEmptyComponent={
                  <View style={styles.empty}>
                    <Ionicons name="people-outline" size={56} color={colors.textMuted} />
                    <Text style={styles.emptyText}>Aucun contact</Text>
                    <Text style={styles.emptySubtext}>Recherchez des utilisateurs par username</Text>
                  </View>
                }
              />
            ) : (
              <FlatList
                data={pendingRequests}
                renderItem={renderRequest}
                keyExtractor={(item) => item.id}
                contentContainerStyle={styles.listContent}
                ListEmptyComponent={
                  <View style={styles.empty}>
                    <Ionicons name="mail-outline" size={56} color={colors.textMuted} />
                    <Text style={styles.emptyText}>Aucune invitation</Text>
                    <Text style={styles.emptySubtext}>Vos demandes reçues apparaissent ici</Text>
                  </View>
                }
              />
            )}
          </View>
        </>
      )}

      {/* ── Bouton flottant « + » : révèle/masque la barre de recherche ── */}
      {!isSearchOpen && (
        <Bubble3DButton
          icon="add"
          size="lg"
          variant="primary"
          colors={colors}
          onPress={toggleSearch}
          accessibilityLabel="Rechercher un contact"
          style={styles.fab}
        />
      )}
    </KeyboardAvoidingView>
    </ScreenBackground>
  );
}

function getStyles(colors: YoumeColors) {
  return StyleSheet.create({
    container: { flex: 1, backgroundColor: 'transparent' },
    flex: { flex: 1 },

    // ── Barre de titre ──
    topBar: {
      paddingHorizontal: SPACING.md,
      paddingBottom: SPACING.sm,
      backgroundColor: 'transparent',
    },
    topBarTitle: {
      fontSize: TYPOGRAPHY.size.xxl,
      fontWeight: '800',
      color: colors.textPrimary,
    },

    // ── Barre de recherche ──
    searchWrapper: {
      backgroundColor: 'transparent',
      paddingBottom: SPACING.md,
      paddingHorizontal: SPACING.md,
    },
    searchBar: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#FFFFFF',
      borderRadius: BORDER_RADIUS.xl,
      height: 48,
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.08,
      shadowRadius: 4,
      elevation: 2,
    },
    searchIcon: { marginLeft: 14, marginRight: 6 },
    searchInput: {
      flex: 1,
      color: '#1A1A1A',
      fontSize: TYPOGRAPHY.size.md,
      paddingVertical: 0,
    },
    searchCloseBtn: { paddingHorizontal: 10, paddingVertical: 6 },
    fab: {
      position: 'absolute',
      right: SPACING.lg,
      bottom: SPACING.lg,
    },

    // ── Onglets larges ──
    tabs: {
      flexDirection: 'row',
      backgroundColor: colors.secondary,
      borderBottomWidth: 1,
      borderBottomColor: colors.divider,
    },
    tab: {
      flex: 1,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'center',
      paddingVertical: 16,
      gap: 7,
    },
    tabActive: {
      borderBottomWidth: 3,
      borderBottomColor: colors.primary,
    },
    tabIcon: { },
    tabText: {
      fontSize: TYPOGRAPHY.size.md,
      fontWeight: '600',
      color: colors.textMuted,
    },
    tabTextActive: {
      color: colors.primary,
    },
    tabBadge: {
      backgroundColor: `${colors.textMuted}33`,
      borderRadius: 10,
      minWidth: 22,
      height: 22,
      justifyContent: 'center',
      alignItems: 'center',
      paddingHorizontal: 5,
    },
    tabBadgeActive: {
      backgroundColor: `${colors.primary}22`,
    },
    tabBadgeText: {
      fontSize: TYPOGRAPHY.size.xs,
      fontWeight: '700',
      color: colors.textMuted,
    },
    tabBadgeTextActive: {
      color: colors.primary,
    },
    tabBadgeAlert: {
      backgroundColor: colors.error,
      borderRadius: 10,
      minWidth: 22,
      height: 22,
      justifyContent: 'center',
      alignItems: 'center',
      paddingHorizontal: 5,
    },
    tabBadgeAlertText: {
      fontSize: TYPOGRAPHY.size.xs,
      fontWeight: '700',
      color: '#FFFFFF',
    },
    tabDivider: {
      width: 1,
      backgroundColor: colors.divider,
      marginVertical: 10,
    },

    // ── Items ──
    listContent: { flexGrow: 1, paddingBottom: 84 },
    item: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      gap: SPACING.md,
      backgroundColor: 'transparent',
    },
    requestItem: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.md,
      gap: SPACING.md,
    },
    itemContent: { flex: 1 },
    itemName: { fontSize: TYPOGRAPHY.size.md, fontWeight: '600', color: colors.textPrimary },
    itemUsername: { fontSize: TYPOGRAPHY.size.sm, color: colors.textSecondary, marginTop: 1 },
    deleteButton: { padding: 2 },

    requestActions: { flexDirection: 'row', gap: SPACING.sm },
    acceptButton: {
      backgroundColor: colors.success,
      width: 38,
      height: 38,
      borderRadius: 19,
      justifyContent: 'center',
      alignItems: 'center',
    },
    rejectButton: {
      backgroundColor: colors.error,
      width: 38,
      height: 38,
      borderRadius: 19,
      justifyContent: 'center',
      alignItems: 'center',
    },
    addButton: {
      backgroundColor: colors.primary,
      width: 38,
      height: 38,
      borderRadius: 19,
      justifyContent: 'center',
      alignItems: 'center',
    },

    separator: { height: 1, backgroundColor: colors.divider, marginLeft: 78 },

    empty: {
      alignItems: 'center',
      paddingTop: 60,
      paddingHorizontal: SPACING.xl,
      gap: SPACING.sm,
    },
    emptyText: { fontSize: TYPOGRAPHY.size.lg, color: colors.textSecondary, fontWeight: '600' },
    emptySubtext: { fontSize: TYPOGRAPHY.size.sm, color: colors.textMuted, textAlign: 'center' },
  });
              }
