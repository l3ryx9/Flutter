import 'package:equatable/equatable.dart';

enum FlagSeverity { low, medium, high, critical }
enum FlagType { greenFlag, redFlag }

class MessageInsight extends Equatable {
  final String messageId;
  final String emotion;
  final String summary;
  final List<String> topics;
  final List<String> entities;
  final double emotionScore;
  final DateTime analyzedAt;

  const MessageInsight({
    required this.messageId,
    required this.emotion,
    required this.summary,
    required this.topics,
    required this.entities,
    required this.emotionScore,
    required this.analyzedAt,
  });

  factory MessageInsight.fromJson(Map<String, dynamic> json) => MessageInsight(
        messageId: json['message_id'] as String,
        emotion: json['emotion'] as String? ?? 'neutral',
        summary: json['summary'] as String? ?? '',
        topics: (json['topics'] as List<dynamic>?)?.cast<String>() ?? [],
        entities: (json['entities'] as List<dynamic>?)?.cast<String>() ?? [],
        emotionScore: (json['emotion_score'] as num?)?.toDouble() ?? 0.5,
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      );

  @override
  List<Object?> get props => [messageId];
}

class RelationshipFlag extends Equatable {
  final String id;
  final String conversationId;
  final FlagType type;
  final FlagSeverity severity;
  final String description;
  final String? messageQuote;
  final String? messageId;
  final DateTime detectedAt;

  const RelationshipFlag({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.severity,
    required this.description,
    this.messageQuote,
    this.messageId,
    required this.detectedAt,
  });

  factory RelationshipFlag.fromJson(Map<String, dynamic> json) => RelationshipFlag(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        type: json['type'] == 'green_flag' ? FlagType.greenFlag : FlagType.redFlag,
        severity: FlagSeverity.values.byName(json['severity'] as String? ?? 'low'),
        description: json['description'] as String? ?? '',
        messageQuote: json['message_quote'] as String?,
        messageId: json['message_id'] as String?,
        detectedAt: DateTime.parse(json['detected_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}

class PsychologicalProfile extends Equatable {
  final String userId;
  final String conversationId;
  final List<String> traits;
  final String generalTone;
  final List<String> recurringTopics;
  final List<String> behavioralAdvice;
  final double moodScore;
  final bool possibleAvoidance;
  final DateTime updatedAt;

  const PsychologicalProfile({
    required this.userId,
    required this.conversationId,
    required this.traits,
    required this.generalTone,
    required this.recurringTopics,
    required this.behavioralAdvice,
    required this.moodScore,
    required this.possibleAvoidance,
    required this.updatedAt,
  });

  factory PsychologicalProfile.fromJson(Map<String, dynamic> json) => PsychologicalProfile(
        userId: json['user_id'] as String,
        conversationId: json['conversation_id'] as String,
        traits: (json['traits'] as List<dynamic>?)?.cast<String>() ?? [],
        generalTone: json['general_tone'] as String? ?? '',
        recurringTopics: (json['recurring_topics'] as List<dynamic>?)?.cast<String>() ?? [],
        behavioralAdvice: (json['behavioral_advice'] as List<dynamic>?)?.cast<String>() ?? [],
        moodScore: (json['mood_score'] as num?)?.toDouble() ?? 0.5,
        possibleAvoidance: json['possible_avoidance'] as bool? ?? false,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props => [userId, updatedAt];
}

class DailySummary extends Equatable {
  final String id;
  final String conversationId;
  final DateTime date;
  final String summary;
  final double relationshipScore;
  final List<RelationshipFlag> flags;
  final PsychologicalProfile? profileUser;
  final PsychologicalProfile? profilePartner;
  final List<String> highlightedFacts;

  const DailySummary({
    required this.id,
    required this.conversationId,
    required this.date,
    required this.summary,
    required this.relationshipScore,
    required this.flags,
    this.profileUser,
    this.profilePartner,
    required this.highlightedFacts,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        date: DateTime.parse(json['date'] as String),
        summary: json['summary'] as String? ?? '',
        relationshipScore: (json['relationship_score'] as num?)?.toDouble() ?? 0.5,
        flags: (json['flags'] as List<dynamic>?)?.map((e) => RelationshipFlag.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        highlightedFacts: (json['highlighted_facts'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  @override
  List<Object?> get props => [id];
}
