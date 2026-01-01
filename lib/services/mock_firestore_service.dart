// mock_firestore_service.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:voiceup/models/models.dart';

class FirestoreService {

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
      isRead: true,
    ),
    MessageModel(
      id: 'msg_2',
      senderId: 'CURRENT_USER_ID',
      receiverId: 'user_1',
      content: "Oui, j'ai fini l'intégration du MockService.",
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 55)),
      isRead: true,
    ),
    MessageModel(
      id: 'msg_3',
      senderId: 'user_1',
      receiverId: 'CURRENT_USER_ID',
      content: "Super nouvelle ! On test ça quand ?",
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
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
    NotificationModel(
      id: 'notif_1',
      title: 'Nouveau message',
      body: 'Thomas Shelby vous a envoyé une photo.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      type: NotificationType.newMessage,
    ),
    NotificationModel(
      id: 'notif_2',
      title: 'Demande d\'ami',
      body: 'Grace Burgess souhaite vous ajouter en ami.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      type: NotificationType.friendRequest,
    ),
    NotificationModel(
      id: 'notif_3',
      title: 'Mise à jour système',
      body: 'VoiceUp v2.0 est maintenant disponible !',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
      type: NotificationType.system,
    ),
  ];

  // --- LECTURE (Streams / Futures) ---

  Future<UserModel?> getUser(String userId) async {
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

  Stream<List<UserModel>> getAllUsersStream() {
    return Stream.value(_fakeUsers);
  }

  Stream<List<FriendshipModel>> getFriendsStream(String currentUserId) {
    final myFriends = _fakeFriendships.where((f) =>
    f.user1Id == currentUserId ||
        f.user2Id == currentUserId ||
        f.user1Id == 'CURRENT_USER_ID' ||
        f.user2Id == 'CURRENT_USER_ID').toList();

    return Stream.value(myFriends);
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String currentUserId) {
    return Stream.value(_fakeRequests.where((r) =>
    (r.receiverId == currentUserId || r.receiverId == 'CURRENT_USER_ID') &&
        r.status == FriendRequestStatus.pending).toList());
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String currentUserId) {
    return Stream.value(_fakeRequests.where((r) =>
    r.senderId == currentUserId &&
        r.status == FriendRequestStatus.pending).toList());
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

  Stream<List<NotificationModel>> getNotificationsStream(String currentUserId) {
    _fakeNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Stream.value(List.from(_fakeNotifications));
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

  // --- ÉCRITURE (Actions) ---

  Future<void> sendMessage(MessageModel message) async {
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

  Future<void> markMessageAsRead(String id) async {
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
        isRead: true, // Marqué comme lu
        isEdited: old.isEdited,
      );
    }
  }

  Future<void> restoreUnreadCount(String chatId, String currentUserId) async {
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

  Future<void> updateUserLastSeen(String chatId, String currentUserId) async {
    // Simule un appel API
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<bool> isUnfriended(String currentUserId, String otherUserId) async {
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

  Future<void> deleteMessage(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeMessages.removeWhere((m) => m.id == id);
    // Notifier l'UI de la suppression
    _messageStreamController.add(_fakeMessages);
    print("MOCK: Message $id supprimé");
  }

  Future<void> editMessage(String id, String newContent) async {
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
        isRead: old.isRead,
        isEdited: true, // Marqué comme édité
      );
      // Notifier l'UI de la modification
      _messageStreamController.add(_fakeMessages);
      print("MOCK: Message $id édité");
    }
  }

  // --- AUTRES ACTIONS (AMIS / CHATS / NOTIFS) ---

  Future<void> sendFriendRequest(FriendRequestModel request) async {
    await Future.delayed(const Duration(seconds: 1));
    _fakeRequests.add(request);
    print("MOCK: Requête envoyée de ${request.senderId} à ${request.receiverId}");
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await Future.delayed(const Duration(seconds: 1));
    _fakeRequests.removeWhere((r) => r.id == requestId);
    print("MOCK: Requête $requestId annulée");
  }

  Future<void> acceptFriendRequest(String requestId) async {
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
    if (index != -1) {
      final oldNotif = _fakeNotifications[index];
      _fakeNotifications[index] = NotificationModel(
        id: oldNotif.id,
        title: oldNotif.title,
        body: oldNotif.body,
        timestamp: oldNotif.timestamp,
        isRead: true,
        type: oldNotif.type,
      );
    }
  }

  Future<void> markAllNotificationsAsRead(String currentUserId) async {
    await Future.delayed(const Duration(seconds: 1));
    for (var i = 0; i < _fakeNotifications.length; i++) {
      final oldNotif = _fakeNotifications[i];
      if (!oldNotif.isRead) {
        _fakeNotifications[i] = NotificationModel(
          id: oldNotif.id,
          title: oldNotif.title,
          body: oldNotif.body,
          timestamp: oldNotif.timestamp,
          isRead: true,
          type: oldNotif.type,
        );
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _fakeNotifications.removeWhere((n) => n.id == id);
  }
}