class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? receiverId;
  final String? listingId;
  final String body;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? senderAvatarUrl;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    this.listingId,
    required this.body,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String?,
      listingId: json['listingId'] as String?,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'listingId': listingId,
      'body': body,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
    };
  }
}

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? listingId;
  final String? listingTitle;
  final String lastMessageBody;
  final DateTime lastMessageAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.listingId,
    this.listingTitle,
    required this.lastMessageBody,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String,
      otherUserAvatarUrl: json['otherUserAvatarUrl'] as String?,
      listingId: json['listingId'] as String?,
      listingTitle: json['listingTitle'] as String?,
      lastMessageBody: json['lastMessageBody'] as String,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: (json['unreadCount'] as int?) ?? 0,
    );
  }
}
