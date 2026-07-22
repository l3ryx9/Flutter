import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? publicKey;
  final bool aiEnabled;
  final bool notificationsEnabled;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.publicKey,
    this.aiEnabled = true,
    this.notificationsEnabled = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen'] as String) : null,
        publicKey: json['public_key'] as String?,
        aiEnabled: json['ai_enabled'] as bool? ?? true,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'is_online': isOnline,
        'last_seen': lastSeen?.toIso8601String(),
        'public_key': publicKey,
        'ai_enabled': aiEnabled,
        'notifications_enabled': notificationsEnabled,
        'created_at': createdAt.toIso8601String(),
      };

  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    }
    return email.substring(0, 1).toUpperCase();
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? publicKey,
    bool? aiEnabled,
    bool? notificationsEnabled,
  }) =>
      UserModel(
        id: id, email: email,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isOnline: isOnline ?? this.isOnline,
        lastSeen: lastSeen ?? this.lastSeen,
        publicKey: publicKey ?? this.publicKey,
        aiEnabled: aiEnabled ?? this.aiEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, displayName, avatarUrl, isOnline, lastSeen, aiEnabled, notificationsEnabled];
}
