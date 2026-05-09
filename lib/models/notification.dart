import 'user.dart';

enum NotificationType {
  like,
  comment,
  follow,
  followRequest,
  followAccepted,
}

class NotificationModel {
  final String id;
  final String recipient;
  final User sender;
  final NotificationType type;
  final Map<String, dynamic>? post;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipient,
    required this.sender,
    required this.type,
    this.post,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'like':
        type = NotificationType.like;
        break;
      case 'comment':
        type = NotificationType.comment;
        break;
      case 'follow':
        type = NotificationType.follow;
        break;
      case 'follow_request':
        type = NotificationType.followRequest;
        break;
      case 'follow_accepted':
        type = NotificationType.followAccepted;
        break;
      default:
        type = NotificationType.like;
    }

    return NotificationModel(
      id: json['_id'] ?? '',
      recipient: json['recipient'] ?? '',
      sender: User.fromJson(json['sender'] ?? {}, ''),
      type: type,
      post: json['post'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
