import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'message_model.dart';

class ConversationModel extends Equatable {
  final String id;
  final List<String> participantIds;
  final UserModel? partner;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? relationshipScore;
  final bool isPartnerOnline;
  final bool isPartnerTyping;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    this.partner,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.relationshipScore,
    this.isPartnerOnline = false,
    this.isPartnerTyping = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
        id: json['id'] as String,
        participantIds: (json['participant_ids'] as List<dynamic>).cast<String>(),
        unreadCount: json['unread_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        relationshipScore: (json['relationship_score'] as num?)?.toDouble(),
      );

  ConversationModel copyWith({
    UserModel? partner,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    double? relationshipScore,
    bool? isPartnerOnline,
    bool? isPartnerTyping,
  }) =>
      ConversationModel(
        id: id,
        participantIds: participantIds,
        partner: partner ?? this.partner,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        relationshipScore: relationshipScore ?? this.relationshipScore,
        isPartnerOnline: isPartnerOnline ?? this.isPartnerOnline,
        isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
      );

  @override
  List<Object?> get props => [id, lastMessage, unreadCount, isPartnerOnline, isPartnerTyping];
}
