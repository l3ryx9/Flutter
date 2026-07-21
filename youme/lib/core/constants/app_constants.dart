class AppConstants {
  AppConstants._();

  static const String appName = 'YouMe';
  static const String appVersion = '1.0.0';

  // Supabase
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Crypto
  static const int keyLength = 32;
  static const String curveType = 'X25519';

  // Pagination
  static const int pageSize = 30;
  static const int messagesPageSize = 50;

  // Heartbeat
  static const Duration onlineHeartbeat = Duration(seconds: 30);
  static const Duration onlineTimeout = Duration(seconds: 90);

  // AI
  static const int flagsAnalysisInterval = 20; // messages
  static const Duration dailyAnalysisTime = Duration(hours: 0); // midnight

  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);

  // Storage buckets
  static const String bucketAvatars = 'avatars';
  static const String bucketMedia = 'media';
  static const String bucketVoice = 'voice';

  // Realtime channels
  static const String channelMessages = 'messages';
  static const String channelPresence = 'presence';
  static const String channelLocation = 'location';

  // Anti-bot
  static const int minFillDuration = 3; // seconds
  static const int arithmeticRange = 20;

  // Location
  static const double mockLocationThreshold = 0.7;
  static const Duration liveLocationInterval = Duration(seconds: 5);

  // Notifications
  static const String notifChannelId = 'youme_main';
  static const String notifChannelName = 'YouMe Notifications';

  // Error log
  static const int maxErrorLogEntries = 500;

  // Assets
  static const String introLottie = 'assets/animations/intro.json';
  static const String loadingLottie = 'assets/animations/loading.json';
  static const String heartLottie = 'assets/animations/heart.json';
  static const String emptyLottie = 'assets/animations/empty.json';
  static const String successLottie = 'assets/animations/success.json';
}

class SupabaseKeys {
  SupabaseKeys._();
  // Tables
  static const String profiles = 'profiles';
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String contacts = 'contacts';
  static const String contactRequests = 'contact_requests';
  static const String messageReactions = 'message_reactions';
  static const String aiMessageInsights = 'ai_message_insights';
  static const String conversationAnalysis = 'conversation_analysis';
  static const String relationshipFlags = 'relationship_flags';
  static const String psychologicalProfiles = 'psychological_profiles';
  static const String dailySummaries = 'daily_summaries';
  static const String highlightedFacts = 'highlighted_facts';
  static const String monthlySummaries = 'monthly_summaries';
  static const String deviceTokens = 'device_tokens';
  static const String liveLocations = 'live_locations';
  static const String botProtectionLogs = 'bot_protection_logs';

  // Edge Functions
  static const String fnAnalyzeMessage = 'analyze-message';
  static const String fnAnalyzeFlags = 'analyze-flags';
  static const String fnDailyAnalysis = 'daily-analysis';
  static const String fnMonthlySummary = 'monthly-summary';
  static const String fnGeminiChat = 'gemini-chat';
  static const String fnValidateBot = 'validate-bot';
  static const String fnSendPushLocation = 'send-push-location';
  static const String fnTranscribeVoice = 'transcribe-voice';
  static const String fnDeleteAccount = 'delete-account';
}
