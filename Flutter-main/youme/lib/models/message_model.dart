import 'package:equatable/equatable.dart';

enum MessageType { text, image, video, voice, location, document, system }
enum MessageStatus { sending, sent, received, read, failed }

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type;
  final String? encryptedText;
  final String? decryptedText;
  final String? mediaUrl;
  final String? voiceDuration;
  final double? locationLat;
  final double? locationLng;
  final String? locationLabel;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, int>? reactions;
  final String? replyToId;
  final bool isDeleted;
  final bool isEdited;
  final Map<String, dynamic>? aiInsight;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    this.encryptedText,
    this.decryptedText,
    this.mediaUrl,
    this.voiceDuration,
    this.locationLat,
    this.locationLng,
    this.locationLabel,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.reactions,
    this.replyToId,
    this.isDeleted = false,
    this.isEdited = false,
    this.aiInsight,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        type: MessageType.values.byName(json['type'] as String? ?? 'text'),
        encryptedText: json['encrypted_text'] as String?,
        decryptedText: json['decrypted_text'] as String?,
        mediaUrl: json['media_url'] as String?,
        voiceDuration: json['voice_duration'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        locationLabel: json['location_label'] as String?,
        status: MessageStatus.values.byName(json['status'] as String? ?? 'sent'),
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
        reactions: (json['reactions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as int)),
        replyToId: json['reply_to_id'] as String?,
        isDeleted: json['is_deleted'] as bool? ?? false,
        isEdited: json['is_edited'] as bool? ?? false,
        aiInsight: json['ai_insight'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'type': type.name,
        'encrypted_text': encryptedText,
        'media_url': mediaUrl,
        'voice_duration': voiceDuration,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'location_label': locationLabel,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'reply_to_id': replyToId,
        'is_deleted': isDeleted,
        'is_edited': isEdited,
      };

  MessageModel copyWith({
    String? decryptedText,
    MessageStatus? status,
    Map<String, int>? reactions,
    DateTime? readAt,
    bool? isDeleted,
    bool? isEdited,
    Map<String, dynamic>? aiInsight,
  }) =>
      MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        type: type,
        encryptedText: encryptedText,
        decryptedText: decryptedText ?? this.decryptedText,
        mediaUrl: mediaUrl,
        voiceDuration: voiceDuration,
        locationLat: locationLat,
        locationLng: locationLng,
        locationLabel: locationLabel,
        status: status ?? this.status,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
        reactions: reactions ?? this.reactions,
        replyToId: replyToId,
        isDeleted: isDeleted ?? this.isDeleted,
        isEdited: isEdited ?? this.isEdited,
        aiInsight: aiInsight ?? this.aiInsight,
      );

  @override
  List<Object?> get props => [id, status, decryptedText, reactions, isDeleted, isEdited];
}
