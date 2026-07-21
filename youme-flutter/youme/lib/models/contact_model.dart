import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum ContactRequestStatus { pending, accepted, rejected }

class ContactModel extends Equatable {
  final String id;
  final String userId;
  final String contactId;
  final UserModel? contactUser;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.userId,
    required this.contactId,
    this.contactUser,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        contactId: json['contact_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, contactId];
}

class ContactRequestModel extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final ContactRequestStatus status;
  final UserModel? senderUser;
  final DateTime createdAt;

  const ContactRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.senderUser,
    required this.createdAt,
  });

  factory ContactRequestModel.fromJson(Map<String, dynamic> json) => ContactRequestModel(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        receiverId: json['receiver_id'] as String,
        status: ContactRequestStatus.values.byName(json['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, status];
}
