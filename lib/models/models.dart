import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,     
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name, 
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // factory FriendRequestModel.fromMap(
  //   Map<String, dynamic> map,
  //   String id,
  // ) {
  //   return FriendRequestModel(
  //     id: id,
  //     senderId: map['senderId'],
  //     receiverId: map['receiverId'],
  //     status: FriendRequestStatus.values.firstWhere(
  //       (e) => e.name == map['status'],
  //     ),
  //     createdAt: (map['createdAt'] as Timestamp).toDate(),
  //   );
  // }

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      status: FriendRequestStatus.values
          .firstWhere((e) => e.name == map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory FriendRequestModel.fromMapWithId(Map<String, dynamic> map, String id) {
    return FriendRequestModel(
      id: id, // Use Firestore document ID
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }



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
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoURL: json['photoURL'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isOnline': isOnline,
      'lastSeen':
          lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '', // MUST exist in Firestore
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserModel.fromMapWithId(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] ?? 'Unknown',
      email: map['email'] ?? '',
      photoURL: map['profilePictureUrl'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? (map['lastSeen'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : null,
    };
  }
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

  factory FriendshipModel.fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      isBlocked: map['isBlocked'] ?? false,
    );
  }
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
  final String receiverId; // Who gets the notification
  final String senderId;   // Who sent the friend request
  final String requestId;  // ID of the friend request doc to accept/decline
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.requestId,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    this.type = NotificationType.friendRequest, // Default to friendRequest
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      receiverId: map['receiverId'] ?? '',
      senderId: map['senderId'] ?? '',
      requestId: map['requestId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.friendRequest,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiverId': receiverId,
      'senderId': senderId,
      'requestId': requestId,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type.name,
    };
  }
}
// class NotificationModel {
//   final String id;
//   final String title;
//   final String body;
//   final DateTime timestamp;
//   final bool isRead;
//   final NotificationType type;
//   final Map<String, dynamic> data;


//   NotificationModel({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.timestamp,
//     required this.isRead,
//     required this.type,
//     this.data = const {},
//   });

//   DateTime get createdAt => timestamp;
//   factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
//     return NotificationModel(
//       id: id,
//       title: map['title'] ?? '',
//       body: map['body'] ?? '',
//       timestamp: (map['timestamp'] as Timestamp).toDate(),
//       isRead: map['isRead'] ?? false,
//       type: NotificationType.values.firstWhere(
//         (e) => e.name == map['type'],
//         orElse: () => NotificationType.system,
//       ),
//       data: Map<String, dynamic>.from(map['data'] ?? {}),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'body': body,
//       'timestamp': Timestamp.fromDate(timestamp),
//       'isRead': isRead,
//       'type': type.name,
//       'data': data,
//     };
//   }
// }




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
  final int? duration;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.duration = 0
  });

// THE MISSING METHOD:
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    int? duration,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      duration: duration ?? this.duration,
    );
  }
  // Utile pour la simulation : convertir en Map (format JSON/Firebase)
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id': id,
  //     'senderId': senderId,
  //     'receiverId': receiverId,
  //     'content': content,
  //     'type': type.toString(),
  //     'timestamp': timestamp.toIso8601String(),
  //     'isRead': isRead,
  //     'isEdited': isEdited,
  //   };
  // }
  // Inside MessageModel class
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name, // Use .name for cleaner strings like "text"
      'timestamp': FieldValue.serverTimestamp(), // This ensures it is a Timestamp, not a String
      'isRead': isRead,
      'isEdited': isEdited,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      // Convert string back to Enum
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      // Firebase uses Timestamps, convert to DateTime
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
    );
  }
}


// enum MessageType { text, audio }

// class MessageModel {
//   final String id;
//   final String senderId;
//   final String receiverId;
//   final String content; // This is the Text OR the Audio URL
//   final String? transcription; // Audio converted to Text
//   final String? translatedText; // Text translated to another language
//   final MessageType type;
//   final DateTime timestamp;

//   MessageModel({
//     required this.id,
//     required this.senderId,
//     required this.receiverId,
//     required this.content,
//     this.transcription,
//     this.translatedText,
//     required this.type,
//     required this.timestamp,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'senderId': senderId,
//       'receiverId': receiverId,
//       'content': content,
//       'transcription': transcription,
//       'translatedText': translatedText,
//       'type': type.name,
//       'timestamp': timestamp,
//     };
//   }

//   factory MessageModel.fromMap(Map<String, dynamic> map) {
//     return MessageModel(
//       id: map['id'] ?? '',
//       senderId: map['senderId'] ?? '',
//       receiverId: map['receiverId'] ?? '',
//       content: map['content'] ?? '',
//       transcription: map['transcription'],
//       translatedText: map['translatedText'],
//       type: map['type'] == 'audio' ? MessageType.audio : MessageType.text,
//       timestamp: (map['timestamp'] as Timestamp).toDate(),
//     );
//   }
// }