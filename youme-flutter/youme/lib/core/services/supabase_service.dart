import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../utils/error_logger.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final res = await client
          .from(SupabaseKeys.profiles)
          .select()
          .eq('id', userId)
          .single();
      return res;
    } catch (e) {
      ErrorLogger.log('getProfile', e.toString());
      return null;
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await client
        .from(SupabaseKeys.profiles)
        .update(data)
        .eq('id', currentUserId!);
  }

  // Storage
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes as dynamic,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  // Edge Functions
  static Future<Map<String, dynamic>> callFunction(
    String name, {
    Map<String, dynamic>? body,
  }) async {
    final res = await client.functions.invoke(name, body: body);
    return res.data as Map<String, dynamic>;
  }

  // Realtime
  static RealtimeChannel subscribeToTable({
    required String table,
    required String schema,
    Map<String, dynamic>? filter,
    required void Function(Map<String, dynamic>) onInsert,
    void Function(Map<String, dynamic>)? onUpdate,
    void Function(Map<String, dynamic>)? onDelete,
  }) {
    var channel = client.channel('table_$table');
    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: schema,
      table: table,
      callback: (payload) => onInsert(payload.newRecord),
    );
    if (onUpdate != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: schema,
        table: table,
        callback: (payload) => onUpdate(payload.newRecord),
      );
    }
    if (onDelete != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: schema,
        table: table,
        callback: (payload) => onDelete(payload.oldRecord),
      );
    }
    channel.subscribe();
    return channel;
  }
}
