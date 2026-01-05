// mock_firestore_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:voiceup/models/models.dart';

class FirestoreService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // --- STATE MANAGEMENT POUR LA SIMULATION ---
  // Ce contrôleur permet de dire à l'application "Hé, les données ont changé !"
  final StreamController<List<MessageModel>> _messageStreamController = StreamController<List<MessageModel>>.broadcast();

  // --- DONNÉES MOCKÉES (BASE DE DONNÉES LOCALE) ---

  // 1. Liste des messages (Simulation de la collection 'messages')
  final List<MessageModel> _fakeMessages = [
    MessageModel(
      id: 'msg_1',
      senderId: 'user_1',
      receiverId: 'CURRENT_USER_ID',
      content: "Salut ! Alors, tu avances sur le code ?",
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 60)),
      // isRead: true,
    ),
    MessageModel(
      id: 'msg_2',
      senderId: 'CURRENT_USER_ID',
      receiverId: 'user_1',
      content: "Oui, j'ai fini l'intégration du MockService.",
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 55)),
      // isRead: true,
    ),
    MessageModel(
      id: 'msg_3',
      senderId: 'user_1',
      receiverId: 'CURRENT_USER_ID',
      content: "Super nouvelle ! On test ça quand ?",
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      // isRead: false,
    ),
  ];

  // 2. Liste des conversations
  final List<ChatModel> _fakeChats = [
    ChatModel(
      id: 'chat_mock_1',
      userIds: ['user_1', 'CURRENT_USER_ID'],
      lastMessage: "Super nouvelle ! On test ça quand ?",
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
      unreadCount: 1,
      lastMessageSenderId: 'user_1',
    ),
    ChatModel(
      id: 'chat_mock_2',
      userIds: ['user_2', 'CURRENT_USER_ID'],
      lastMessage: "Ok, on fait comme ça.",
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      lastMessageSenderId: 'CURRENT_USER_ID',
    ),
  ];

  // 3. Liste des utilisateurs
  final List<UserModel> _fakeUsers = [
    UserModel(
        id: 'user_1',
        displayName: 'Thomas Shelby',
        email: 'tommy@test.com',
        photoURL: 'https://i.pravatar.cc/150?u=1',
        isOnline: true,
        lastSeen: DateTime.now()),
    UserModel(
        id: 'user_2',
        displayName: 'Arthur Shelby',
        email: 'arthur@test.com',
        photoURL: null,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(minutes: 15))),
    UserModel(
        id: 'user_3',
        displayName: 'Polly Gray',
        email: 'polly@test.com',
        photoURL: 'https://i.pravatar.cc/150?u=3',
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(days: 2))),
    UserModel(
        id: 'user_4',
        displayName: 'John Shelby',
        email: 'john@test.com',
        photoURL: '',
        isOnline: true,
        lastSeen: DateTime.now()),
    UserModel(
        id: 'user_5',
        displayName: 'Grace Burgess',
        email: 'grace@test.com',
        photoURL: 'https://i.pravatar.cc/150?u=5',
        isOnline: true,
        lastSeen: DateTime.now()),
    UserModel(
        id: 'user_6',
        displayName: 'Ada Thorne',
        email: 'ada@test.com',
        photoURL: null,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 5))),
  ];

  // 4. Liste des amis
  final List<FriendshipModel> _fakeFriendships = [
    FriendshipModel(user1Id: 'CURRENT_USER_ID', user2Id: 'user_1'), // Thomas
    FriendshipModel(user1Id: 'CURRENT_USER_ID', user2Id: 'user_2'), // Arthur
    FriendshipModel(user1Id: 'user_3', user2Id: 'CURRENT_USER_ID'), // Polly
  ];

  // 5. Liste des requêtes d'amis
  final List<FriendRequestModel> _fakeRequests = [
    FriendRequestModel(
      id: 'req_mock_1',
      senderId: 'user_5',
      receiverId: 'CURRENT_USER_ID',
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    FriendRequestModel(
      id: 'req_mock_2',
      senderId: 'user_6',
      receiverId: 'CURRENT_USER_ID',
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // 6. Liste des notifications
  final List<NotificationModel> _fakeNotifications = [
    // NotificationModel(
    //   id: 'notif_1',
    //   title: 'Nouveau message',
    //   body: 'Thomas Shelby vous a envoyé une photo.',
    //   timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    //   isRead: false,
    //   type: NotificationType.newMessage,
    // ),
    // NotificationModel(
    //   id: 'notif_2',
    //   title: 'Demande d\'ami',
    //   body: 'Grace Burgess souhaite vous ajouter en ami.',
    //   timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    //   isRead: true,
    //   type: NotificationType.friendRequest,
    // ),
    // NotificationModel(
    //   id: 'notif_3',
    //   title: 'Mise à jour système',
    //   body: 'VoiceUp v2.0 est maintenant disponible !',
    //   timestamp: DateTime.now().subtract(const Duration(days: 1)),
    //   isRead: false,
    //   type: NotificationType.system,
    // ),
  ];

  // --- LECTURE (Streams / Futures) ---

  Future<UserModel?> getUser0(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulation : Si l'ID est celui de l'utilisateur actuel
    if (userId == 'CURRENT_USER_ID') {
      return UserModel(
        id: 'CURRENT_USER_ID',
        displayName: 'Moi',
        email: 'me@voiceup.com',
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    }
    return _fakeUsers.firstWhereOrNull((u) => u.id == userId);
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      // 1. Reference the 'users' collection with the specific document ID
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      // 2. Check if the document actually exists in Firestore
      if (doc.exists && doc.data() != null) {
        // 3. Convert the Firestore map data into your UserModel
        // Assuming you have a fromMap factory in your UserModel
        return UserModel.fromMapWithId(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      print("User with ID $userId not found in Firestore.");
      return null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<List<UserModel>> getAllUsers() async {
    // return Stream.value(_fakeUsers);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(); // Fetch all documents once

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          displayName: data['displayName'] ?? '',
          email: data['email'] ?? '',
          photoURL: data['photoURL'] ?? '',
          isOnline: data['isOnline'] ?? false,
          lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
        );
      }).toList();

      return users;
    } catch (e) {
      print("Error fetching users: $e");
      return []; // Return empty list on error
    }
  }

  Stream<List<FriendshipModel>> getFriendsStream(String currentUserId) {
    final myFriends = _fakeFriendships.where((f) =>
    f.user1Id == currentUserId ||
        f.user2Id == currentUserId ||
        f.user1Id == 'CURRENT_USER_ID' ||
        f.user2Id == 'CURRENT_USER_ID').toList();

    return Stream.value(myFriends);
  }

  Future<List<FriendshipModel>> getFriendsFuture(String currentUserId) async {
    try {
      // We use Filter.or to find documents where the user is either side of the friendship
      final querySnapshot = await _firestore
          .collection('friendships')
          .where(
            Filter.or(
              Filter('user1Id', isEqualTo: currentUserId),
              Filter('user2Id', isEqualTo: currentUserId),
            ),
          )
          .get();

      // Map the documents to your FriendshipModel
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return FriendshipModel(
          user1Id: data['user1Id'] ?? '',
          user2Id: data['user2Id'] ?? '',
          isBlocked: data['isBlocked'] ?? false,
        );
      }).toList();
    } catch (e) {
      print("Error fetching friends: $e");
      return []; // Return empty list on error
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String currentUserId) {
    return Stream.value(_fakeRequests.where((r) =>
    (r.receiverId == currentUserId || r.receiverId == 'CURRENT_USER_ID') &&
        r.status == FriendRequestStatus.pending).toList());
  }
  Future<List<FriendRequestModel>> getFriendRequests(String currentUserId) async {
      try {
        final querySnapshot = await _firestore
            .collection('friend_requests')
            .where('receiverId', isEqualTo: currentUserId)
            // .where('status', isEqualTo: 'pending')
            // .orderBy('createdAt', descending: true)
            .get();

        print('done');
        return querySnapshot.docs
            .map((doc) => FriendRequestModel.fromMapWithId(doc.data(), doc.id))
            .toList();
        
      } catch (e) {
        print("Error fetching friend requests: $e");
        return [];
      }
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String currentUserId) {
    return Stream.value(_fakeRequests.where((r) =>
    r.senderId == currentUserId &&
        r.status == FriendRequestStatus.pending).toList());
  }

  Future<List<FriendRequestModel>> getSentFriendRequests(String currentUserId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    // return querySnapshot.docs
    //     .map((doc) => FriendRequestModel.fromMap(doc.data()))
    //     .toList();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      // Add doc.id manually in case your model needs it
      return FriendRequestModel.fromMap({
        'id': doc.id,         // Firestore document ID
        ...data,              // spread all other fields
      });
    }).toList();
  }


  Stream<List<ChatModel>> getUserChatsStream(String currentUserId) {
    // Note: Dans une vraie implémentation mock complexe, on utiliserait aussi un StreamController ici.
    // Pour l'instant, on renvoie la liste filtrée.
    final myChats = _fakeChats.where((chat) {
      return chat.userIds.contains(currentUserId) ||
          chat.userIds.contains('CURRENT_USER_ID');
    }).toList();

    myChats.sort((a, b) {
      final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });

    return Stream.value(myChats);
  }
  Future<List<ChatModel>> getUserChatsFuture(String currentUserId) async {
    try {
      // 1. Query Firestore for chats where the user is a participant
      final querySnapshot = await _firestore
          .collection('chats')
          .where('userIds', arrayContains: currentUserId)
          .get();

      // 2. Map the documents to your ChatModel
      List<ChatModel> chats = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Handle the timestamp safely
        DateTime? lastTime;
        if (data['lastMessageTime'] != null) {
          lastTime = (data['lastMessageTime'] as Timestamp).toDate();
        }

        return ChatModel(
          id: data['id'] ?? doc.id,
          userIds: List<String>.from(data['userIds'] ?? []),
          lastMessage: data['lastMessage'],
          lastMessageTime: lastTime,
          unreadCount: data['unreadCount'] ?? 0,
          lastMessageSenderId: data['lastMessageSenderId'] ?? '',
        );
      }).toList();

      // 3. Manual Sort (Most recent first)
      // We sort in Dart to avoid complex Firestore composite indexes
      chats.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

      return chats;
    } catch (e) {
      print("Error fetching user chats: $e");
      return [];
    }
  }

  // Stream<List<NotificationModel>> getNotificationsStream(String currentUserId) {
  //   _fakeNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  //   return Stream.value(List.from(_fakeNotifications));
  // }

  Stream<List<NotificationModel>> getNotificationsStream(String currentUserId) {
    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots() // This replaces .get()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  Future<void> sendNotification(NotificationModel notification) async {
    try {
    // If you want Firestore to generate the ID automatically:
    await _firestore.collection('notifications').add(notification.toMap());
    
    // OR, if you want to keep using your specific notification.id:
    // await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    
    // print('Notification sent successfully to ${notification.receiverId}');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications(String currentUserId) async {
  try {
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: currentUserId) // Matches your composite index
        .orderBy('timestamp', descending: true)        // Matches your composite index
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      
      return NotificationModel(
        id: doc.id,
        receiverId: data['receiverId'] ?? '',
        senderId: data['senderId'] ?? '',
        requestId: data['requestId'] ?? '',
        title: data['title'] ?? '',
        body: data['body'] ?? '',
        // Safety check for timestamp
        timestamp: data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate() 
            : DateTime.now(),
        isRead: data['isRead'] ?? false,
        type: NotificationType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => NotificationType.friendRequest,
        ),
      );
    }).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // --- LOGIQUE DES MESSAGES (Cruciale pour le Chat) ---

  Stream<List<MessageModel>> getMessagesStream(String currentUserId, String otherUserId) {
    // 1. Fonction pour filtrer les messages entre les deux utilisateurs
    List<MessageModel> getFilteredMessages() {
      final messages = _fakeMessages.where((m) {
        return (m.senderId == currentUserId && m.receiverId == otherUserId) ||
            (m.senderId == otherUserId && m.receiverId == currentUserId);
      }).toList();
      // Tri du plus ancien au plus récent
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    }

    // 2. Création d'un Stream manuel qui écoute les changements globaux
    late StreamController<List<MessageModel>> controller;
    StreamSubscription? subscription;

    controller = StreamController<List<MessageModel>>(
      onListen: () {
        // A. Envoyer les données actuelles immédiatement
        controller.add(getFilteredMessages());

        // B. Écouter les futures mises à jour (via sendMessage, deleteMessage...)
        subscription = _messageStreamController.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(getFilteredMessages());
          }
        });
      },
      onCancel: () {
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
  Future<List<MessageModel>> getMessagesFuture0(String currentUserId, String otherUserId) async {
    try {
      // 1. Generate the unique Chat ID (alphabetical sort ensures both users use the same ID)
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatId = ids.join('_');

      // 2. Fetch messages from the subcollection
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false) // Oldest to newest
          .get();

      // 3. Map the documents to your MessageModel
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          content: data['content'] ?? '',
          type: MessageType.values.firstWhere(
            (e) => e.toString() == data['type'],
            orElse: () => MessageType.text,
          ),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          // isRead: data['isRead'] ?? false,
          // isEdited: data['isEdited'] ?? false,
        );
      }).toList();
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  Future<List<MessageModel>> getMessagesFuture(String currentUserId, String otherUserId) async {
    try {
      List<String> ids = [currentUserId, otherUserId];
      ids.sort();
      String chatId = ids.join('_');

      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        DateTime messageTime;

        // FIX: Check the type of the timestamp field dynamically
        var ts = data['timestamp'];
        if (ts is Timestamp) {
          messageTime = ts.toDate();
        } else if (ts is String) {
          // If it's the String causing the error, parse it
          messageTime = DateTime.tryParse(ts) ?? DateTime.now();
        } else {
          messageTime = DateTime.now();
        }

        return MessageModel(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          content: data['content'] ?? '',
          type: MessageType.values.firstWhere(
            (e) => e.name == data['type'] || e.toString() == data['type'],
            orElse: () => MessageType.text,
          ),
          timestamp: messageTime,
          // isRead: data['isRead'] ?? false,
          // isEdited: data['isEdited'] ?? false,
        );
      }).toList();
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  // --- ÉCRITURE (Actions) ---

  Future<void> sendMessage0(MessageModel message) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Latence artificielle

    // 1. Ajout à la base de données locale
    _fakeMessages.add(message);

    // 2. Mise à jour de la liste des Chats (Last Message)
    final chatIndex = _fakeChats.indexWhere((c) =>
    c.userIds.contains(message.senderId) && c.userIds.contains(message.receiverId)
    );

    if (chatIndex != -1) {
      final oldChat = _fakeChats[chatIndex];
      _fakeChats[chatIndex] = ChatModel(
        id: oldChat.id,
        userIds: oldChat.userIds,
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: oldChat.unreadCount + 1,
        lastMessageSenderId: message.senderId,
      );
    }

    // 3. Déclencher la mise à jour pour que l'UI réagisse
    _messageStreamController.add(_fakeMessages);
    print("MOCK: Message envoyé : ${message.content}");
  }

  Future<void> sendMessage(MessageModel message) async {
    final batch = _firestore.batch();

    // 1. Create a Unique Chat ID (alphabetical sort to match your getFriends logic)
    List<String> ids = [message.senderId, message.receiverId];
    ids.sort();
    String chatId = ids.join('_');

    // 2. Reference for the Message and the Chat Metadata
    DocumentReference messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(); // Auto-generated ID for message

    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    // 3. Save Message Data
    batch.set(messageRef, message.toMap());

    // 4. Update ChatModel fields in Firebase
    batch.set(chatRef, {
      'id': chatId,
      'userIds': [message.senderId, message.receiverId],
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': message.senderId,
      // Increment unread count for the receiver
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

Future<String?> uploadAudio(String localFilePath) async {
    try {
      // 1. Create a File object from the local path
      File file = File(localFilePath);

      // 2. Check if the file actually exists to avoid crashes
      if (!await file.exists()) {
        print("Upload Error: Local file not found at $localFilePath");
        return null;
      }

      // 3. Create a unique filename (using a timestamp or UUID)
      String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 4. Create a reference to where the file will live in Firebase Storage
      // Path: chats/voice_messages/filename.m4a
      Reference ref = _storage
          .ref()
          .child('chats')
          .child('voice_messages')
          .child(fileName);

      // 5. Start the upload task
      UploadTask uploadTask = ref.putFile(file);

      // 6. Wait for the upload to finish and get the snapshot
      TaskSnapshot snapshot = await uploadTask;

      // 7. Retrieve the public Download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Firebase Storage Error: $e");
      return null;
    }
  }
  Future<void> markMessageAsRead0(String id) async {
    final index = _fakeMessages.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _fakeMessages[index];
      _fakeMessages[index] = MessageModel(
        id: old.id,
        senderId: old.senderId,
        receiverId: old.receiverId,
        content: old.content,
        type: old.type,
        timestamp: old.timestamp,
        // isRead: true, // Marqué comme lu
        // isEdited: old.isEdited,
      );
    }
  }
  Future<void> markMessageAsRead1(String messageId) async {
    try {
      // Direct update because the ID is at the top level
      await _firestore
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print("Error: $e");
    }
  }
  Future<void> markMessageAsRead(String messageId) async {
    try {
      final query = await _firestore
          .collectionGroup('messages')
          .where(FieldPath.documentId, isEqualTo: messageId)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'isRead': true});
      }
    } catch (e) {
      print("MarkAsRead Error: $e");
    }
  }
  Future<void> restoreUnreadCount0(String chatId, String currentUserId) async {
    final index = _fakeChats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final old = _fakeChats[index];
      _fakeChats[index] = ChatModel(
        id: old.id,
        userIds: old.userIds,
        lastMessage: old.lastMessage,
        lastMessageTime: old.lastMessageTime,
        unreadCount: 0, // Remise à zéro
        lastMessageSenderId: old.lastMessageSenderId,
      );
    }
  }

  Future<void> restoreUnreadCount(String chatId, String currentUserId) async {
    try {
      // 1. Reference the specific chat document in the 'chats' collection
      final chatRef = _firestore.collection('chats').doc(chatId);

      // 2. Update the unreadCount field to 0
      await chatRef.update({
        'unreadCount': 0,
      });

      print("Firebase: Unread count reset to 0 for chat: $chatId");
    } catch (e) {
      print("Error resetting unread count: $e");
      // Depending on your error handling, you might want to rethrow or show a snackbar
    }
  }

  Future<void> updateUserLastSeen0(String chatId, String currentUserId) async {
    // Simule un appel API
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> updateUserLastSeen(String chatId, String currentUserId) async {
    try {
      // 1. Reference the specific chat document
      final chatRef = _firestore.collection('chats').doc(chatId);

      // 2. Update a nested map to track each user's activity in this chat
      // We use a map 'lastSeenBy' so both users can have their own timestamp 
      // without overwriting each other.
      await chatRef.update({
        'lastSeenBy.$currentUserId': FieldValue.serverTimestamp(),
      });

      print("Firebase: Updated last seen for user $currentUserId in chat $chatId");
    } catch (e) {
      print("Error updating chat last seen: $e");
    }
  }

  Future<bool> isUnfriended0(String currentUserId, String otherUserId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Vérifie si l'amitié existe
    final isFriend = _fakeFriendships.any((f) =>
    (f.user1Id == currentUserId && f.user2Id == otherUserId) ||
        (f.user1Id == otherUserId && f.user2Id == currentUserId) ||
        (f.user1Id == 'CURRENT_USER_ID' && f.user2Id == otherUserId) ||
        (f.user1Id == otherUserId && f.user2Id == 'CURRENT_USER_ID')
    );
    return !isFriend;
  }
  Future<bool> isUnfriended(String currentUserId, String otherUserId) async {
    try {
      // 1. We query the friendships collection
      // We use the 'participants' array check if you added it, 
      // or a combined filter if you didn't.
      final query = await _firestore
          .collection('friendships')
          .where(
            Filter.or(
              Filter.and(
                Filter('user1Id', isEqualTo: currentUserId),
                Filter('user2Id', isEqualTo: otherUserId),
              ),
              Filter.and(
                Filter('user1Id', isEqualTo: otherUserId),
                Filter('user2Id', isEqualTo: currentUserId),
              ),
            ),
          )
          .limit(1) // We only need to know if at least ONE exists
          .get();

      // 2. If the query is empty, they are NOT friends (isUnfriended = true)
      return query.docs.isEmpty;
      
    } catch (e) {
      print("Error checking friendship status: $e");
      // In case of error, we return true to be safe and block the message
      return true; 
    }
  }

  Future<void> deleteMessage0(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeMessages.removeWhere((m) => m.id == id);
    // Notifier l'UI de la suppression
    _messageStreamController.add(_fakeMessages);
    print("MOCK: Message $id supprimé");
  }
  Future<void> deleteMessage(String id) async {
    try {
      final query = await _firestore
          .collectionGroup('messages')
          .where(FieldPath.documentId, isEqualTo: id)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      }
    } catch (e) {
      print("Delete Error: $e");
    }
  }

  Future<void> editMessage0(String id, String newContent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _fakeMessages.indexWhere((m) => m.id == id);
    if (index != -1) {
      final old = _fakeMessages[index];
      _fakeMessages[index] = MessageModel(
        id: old.id,
        senderId: old.senderId,
        receiverId: old.receiverId,
        content: newContent,
        type: old.type,
        timestamp: old.timestamp,
        // isRead: old.isRead,
        // isEdited: true, // Marqué comme édité
      );
      // Notifier l'UI de la modification
      _messageStreamController.add(_fakeMessages);
      print("MOCK: Message $id édité");
    }
  }

  Future<void> editMessage(String id, String newContent) async {
    try {
      final query = await _firestore
          .collectionGroup('messages')
          .where(FieldPath.documentId, isEqualTo: id)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'content': newContent,
          'isEdited': true,
        });
      }
    } catch (e) {
      print("Edit Error: $e");
    }
  }

  // --- AUTRES ACTIONS (AMIS / CHATS / NOTIFS) ---

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    // await Future.delayed(const Duration(seconds: 1));
    // _fakeRequests.add(request);
    // print("MOCK: Requête envoyée de ${request.senderId} à ${request.receiverId}");
    // Optional: prevent duplicate requests
    // final existing = await _firestore
    //     .collection('friend_requests')
    //     .where('senderId', isEqualTo: request.senderId)
    //     .where('receiverId', isEqualTo: request.receiverId)
    //     .where('status', isEqualTo: 'pending')
    //     .get();

    // if (existing.docs.isNotEmpty) {
    //   throw Exception('Friend request already sent');
    // }

    await FirebaseFirestore.instance
      .collection('friend_requests')
      .doc(request.id) // <-- use the request.id here
      .set(request.toMap());
  }

  Future<void> cancelFriendRequest(String requestId) async {
    // await Future.delayed(const Duration(seconds: 1));
    // _fakeRequests.removeWhere((r) => r.id == requestId);
    // await _firestore
    //   .collection('friend_requests')
    //   .doc(requestId)
    //   .delete();
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId) // delete using the doc ID
          .delete();

      print("Request $requestId deleted successfully");
    } catch (e) {
      print("Failed to delete request: $e");
    }
  }

  Future<void> acceptFriendRequest0(String requestId) async {
    await Future.delayed(const Duration(seconds: 1));
    final request = _fakeRequests.firstWhereOrNull((r) => r.id == requestId);

    if (request != null) {
      final newFriendship = FriendshipModel(
          user1Id: request.senderId, user2Id: request.receiverId);
      _fakeFriendships.add(newFriendship);
      _fakeRequests.removeWhere((r) => r.id == requestId);
      print("MOCK: Requête $requestId acceptée");
    }
  }
  Future<void> acceptFriendRequest(String requestId) async {
  try {
    final requestDoc = await _firestore.collection('friend_requests').doc(requestId).get();
    
    if (!requestDoc.exists) return;

    final senderId = requestDoc.data()?['senderId'];
    final receiverId = requestDoc.data()?['receiverId'];

    final WriteBatch batch = _firestore.batch();

    final String friendshipId = "${senderId}_$receiverId";
    final DocumentReference friendshipRef = _firestore.collection('friendships').doc(friendshipId);

    batch.set(friendshipRef, {
      'user1Id': senderId,
      'user2Id': receiverId,
      'isBlocked': false, // Default value from your model
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    batch.delete(requestDoc.reference);

    await batch.commit();
    
    print("Firebase: Friendship $friendshipId created and request deleted.");
    } catch (e) {
      print("Error accepting friend request in Firebase: $e");
      rethrow;
    }
  }

  Future<void> respondToFriendRequest(String requestId, FriendRequestStatus status) async {
    await Future.delayed(const Duration(seconds: 1));
    if (status == FriendRequestStatus.declined) {
      _fakeRequests.removeWhere((r) => r.id == requestId);
    }
    print("MOCK: Réponse à la requête $requestId : $status");
  }

  Future<void> removeFriendShip(String currentUserId, String friendId) async {
    await Future.delayed(const Duration(seconds: 1));
    _fakeFriendships.removeWhere((f) =>
    (f.user1Id == currentUserId && f.user2Id == friendId) ||
        (f.user1Id == friendId && f.user2Id == currentUserId) ||
        (f.user1Id == 'CURRENT_USER_ID' && f.user2Id == friendId));
    print("MOCK: Amitié avec $friendId supprimée");
  }

  Future<void> blockUser(String currentUserId, String friendId) async {
    await Future.delayed(const Duration(seconds: 1));
    print("MOCK: Ami $friendId bloqué");
  }

  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    await Future.delayed(const Duration(seconds: 1));
    print("MOCK: Utilisateur $blockedUserId débloqué par $currentUserId");
  }

  Future<void> deleteChatForUser(String chatId, String currentUserId) async {
    await Future.delayed(const Duration(seconds: 1));
    _fakeChats.removeWhere((chat) => chat.id == chatId);
    print("MOCK: Chat $chatId supprimé pour $currentUserId");
  }

  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    await Future.delayed(const Duration(seconds: 1));

    final existingChat = _fakeChats.firstWhereOrNull((chat) {
      final ids = chat.userIds;
      return ids.contains(currentUserId) && ids.contains(otherUserId);
    });

    if (existingChat != null) {
      return existingChat.id;
    } else {
      final newId = 'chat_mock_${DateTime.now().millisecondsSinceEpoch}';
      final newChat = ChatModel(
        id: newId,
        userIds: [currentUserId, otherUserId],
        lastMessage: null,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );

      _fakeChats.add(newChat);
      return newId;
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _fakeNotifications.indexWhere((n) => n.id == id);
    // if (index != -1) {
    //   final oldNotif = _fakeNotifications[index];
    //   _fakeNotifications[index] = NotificationModel(
    //     id: oldNotif.id,
    //     title: oldNotif.title,
    //     body: oldNotif.body,
    //     timestamp: oldNotif.timestamp,
    //     isRead: true,
    //     type: oldNotif.type,
    //   );
    // }
  }

  Future<void> markAllNotificationsAsRead(String currentUserId) async {
    await Future.delayed(const Duration(seconds: 1));
    for (var i = 0; i < _fakeNotifications.length; i++) {
      final oldNotif = _fakeNotifications[i];
      if (!oldNotif.isRead) {
        // _fakeNotifications[i] = NotificationModel(
        //   id: oldNotif.id,
        //   title: oldNotif.title,
        //   body: oldNotif.body,
        //   timestamp: oldNotif.timestamp,
        //   isRead: true,
        //   type: oldNotif.type,
        // );
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fakeNotifications.removeWhere((n) => n.id == id);
  }
}