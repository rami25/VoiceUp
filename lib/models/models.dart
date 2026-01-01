// --- ENUMS ---

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  friendRequestDeclined,
  newMessage, // Corrigé : "newMessage" au lieu de "message"
  friendRemoved,
  system,     // Ajouté : type système
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

// --- MODELS ---

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });
}

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? photoURL;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    this.id = '',
    required this.displayName,
    required this.email,
    this.photoURL,
    this.isOnline = false,
    this.lastSeen,
  });

  String get uid => id;
}

class FriendshipModel {
  final String user1Id;
  final String user2Id;
  final bool isBlocked;

  FriendshipModel({
    required this.user1Id,
    required this.user2Id,
    this.isBlocked = false,
  });

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }
}

class ChatModel {
  final String id;
  final List<String> userIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String lastMessageSenderId;

  ChatModel({
    required this.id,
    required this.userIds,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.lastMessageSenderId = '',
  });

  String getOtherParticipant(String currentUserId) {
    return userIds.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCount(String currentUserId) => unreadCount;

  bool isMessageSeen(String currentUserId, String otherUserId) {
    return lastMessageSenderId == currentUserId;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.data = const {},
  });

  DateTime get createdAt => timestamp;
}
// Ajoutez cet Enum avec les autres Enums au début du fichier
enum MessageType {
  text,
  image,
  audio,
  video,
  file,
}

// Ajoutez cette classe avec les autres Models
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
  });

  // Utile pour la simulation : convertir en Map (format JSON/Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
    };
  }
}