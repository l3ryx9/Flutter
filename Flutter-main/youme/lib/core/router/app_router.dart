import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/auth/reset_password/reset_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/chats/conversation_list/conversation_list_screen.dart';
import '../../features/chats/chat/chat_screen.dart';
import '../../features/chats/ai_message_insights/ai_insights_screen.dart';
import '../../features/chats/conversation_analysis/conversation_analysis_screen.dart';
import '../../features/chats/relationship_flags/relationship_flags_screen.dart';
import '../../features/contacts/contacts/contacts_screen.dart';
import '../../features/contacts/invitations/invitations_screen.dart';
import '../../features/ai/search/ai_search_screen.dart';
import '../../features/live_location/live_location_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/delete_account/delete_account_screen.dart';
import '../../features/debug/debug_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const home = '/home';
  static const conversations = '/conversations';
  static const chat = '/chat/:conversationId';
  static const aiInsights = '/chat/:conversationId/ai-insights';
  static const conversationAnalysis = '/chat/:conversationId/analysis';
  static const relationshipFlags = '/chat/:conversationId/flags';
  static const contacts = '/contacts';
  static const invitations = '/invitations';
  static const aiSearch = '/ai-search';
  static const liveLocation = '/live-location/:conversationId';
  static const profile = '/profile';
  static const settings = '/settings';
  static const deleteAccount = '/delete-account';
  static const debug = '/debug';
}

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.splash,
      ].contains(state.matchedLocation);

      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.resetPassword, builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'conversations', builder: (_, __) => const ConversationListScreen()),
          GoRoute(
            path: 'chat/:conversationId',
            builder: (_, state) => ChatScreen(conversationId: state.pathParameters['conversationId']!),
            routes: [
              GoRoute(
                path: 'ai-insights',
                builder: (_, state) => AiInsightsScreen(conversationId: state.pathParameters['conversationId']!),
              ),
              GoRoute(
                path: 'analysis',
                builder: (_, state) => ConversationAnalysisScreen(conversationId: state.pathParameters['conversationId']!),
              ),
              GoRoute(
                path: 'flags',
                builder: (_, state) => RelationshipFlagsScreen(conversationId: state.pathParameters['conversationId']!),
              ),
              GoRoute(
                path: 'live-location',
                builder: (_, state) => LiveLocationScreen(conversationId: state.pathParameters['conversationId']!),
              ),
            ],
          ),
          GoRoute(path: 'contacts', builder: (_, __) => const ContactsScreen()),
          GoRoute(path: 'invitations', builder: (_, __) => const InvitationsScreen()),
          GoRoute(path: 'ai-search', builder: (_, __) => const AiSearchScreen()),
          GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: 'delete-account', builder: (_, __) => const DeleteAccountScreen()),
          GoRoute(path: 'debug', builder: (_, __) => const DebugScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route introuvable : ${state.uri}'),
      ),
    ),
  );
}
