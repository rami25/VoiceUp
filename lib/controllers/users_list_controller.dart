import 'package:flutter/material.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/root/parse_route.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get/route_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:voiceup/controllers/auth_controller.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/services/mock_firestore_service.dart';
// Note: Assure-toi que AuthController est bien accessible ou mocké aussi.

enum UserRelationshipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UsersListController extends GetxController {
  // ICI: On utilise le MockFirestoreService au lieu du vrai pour le moment
  final MockFirestoreService _firestoreService = MockFirestoreService();
  final FirestoreService _firestoreServ = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();

  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _error = ''.obs;

  final RxMap<String, UserRelationshipStatus> _userRelationships =
      <String, UserRelationshipStatus>{}.obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs;

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  String get error => _error.value;
  Map<String, UserRelationshipStatus> get userRelationships => _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();

    debounce(
      _sentRequests,
          (_) => _filterUsers(),
      time: Duration(milliseconds: 300),
    );
  }

  void _loadUsers() async {
    // _users.bindStream(_firestoreService.getAllUsersStream());
    final res = await _firestoreServ.getAllUsers();
    _users.assignAll(res);

    // filter out current user and update the filtered list
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers =
      userList.where((user) => user.id != currentUserId).toList();

      if (_searchQuery.isEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() async {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      // _sentRequests.bindStream(
      //   _firestoreServ.getSentFriendRequestsStream(currentUserId),
      // );
      final res = await _firestoreServ.getSentFriendRequests(currentUserId);
      _sentRequests.assignAll(res);

      // _receivedRequests.bindStream(
      //   _firestoreServ.getFriendRequestsStream(currentUserId),
      // );
      final res1 = await _firestoreServ.getFriendRequests(currentUserId);
      _receivedRequests.assignAll(res1);

      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      ever(_sentRequests, (_) => _updateAllRelationshipsStatus());
      ever(_receivedRequests, (_) => _updateAllRelationshipsStatus());
      ever(_friendships, (_) => _updateAllRelationshipsStatus());
      ever(_users, (_) => _updateAllRelationshipsStatus());
    }
  }

  void _updateAllRelationshipsStatus() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  UserRelationshipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return UserRelationshipStatus.none;

    final friendship = _friendships.firstWhereOrNull(
          (f) =>
      (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );
    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationshipStatus.blocked;
      } else {
        return UserRelationshipStatus.friends;
      }
    }
    final sentRequest = _sentRequests.firstWhereOrNull(
          (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );

    if (sentRequest != null) {
      return UserRelationshipStatus.friendRequestSent;
    }

    final receivedRequest = _receivedRequests.firstWhereOrNull(
          (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );
    if (receivedRequest != null) {
      return UserRelationshipStatus.friendRequestReceived;
    }

    return UserRelationshipStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredUsers.value =
          _users.where((user) => user.id != currentUserId).toList();
    } else {
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
    _filterUsers();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _filterUsers();
  }

  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        // 1. Generate the Friend Request
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
          status: FriendRequestStatus.pending,
        );

        // Optimistic UI update
        _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
        
        // Save request to Firestore
        await _firestoreServ.sendFriendRequest(request);

        // 2. Create the Notification using explicit fields
        final notification = NotificationModel(
          id: _uuid.v4(),
          receiverId: user.id,     // Explicit field
          senderId: currentUserId, // Explicit field
          requestId: request.id,   // Explicit field
          title: "New Friend Request",
          body: "${_authController.user?.displayName ?? 'Someone'} sent you a friend request",
          timestamp: DateTime.now(),
          isRead: false,
          type: NotificationType.friendRequest,
        );

        // 3. Save the notification in Firestore
        await _firestoreServ.sendNotification(notification);
        
        Get.snackbar('Success', "Friend Request Sent To ${user.displayName}");
      }
    } catch (e) {
      // Revert UI state on error
      _userRelationships[user.id] = UserRelationshipStatus.none;
      _error.value = e.toString();
      Get.snackbar('Error', "Failed to send friend request");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sentRequests.firstWhereOrNull(
              (r) => r.receiverId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          await _firestoreServ.cancelFriendRequest(request.id);
          _userRelationships[user.id] = UserRelationshipStatus.none;
          Get.snackbar('Success', "Friend Request Cancelled");
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
      _error.value = e.toString();
      Get.snackbar('Error', "Failed to cancel friend request");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
              (r) => r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          await _firestoreService.acceptFriendRequest(request.id);
          _userRelationships[user.id] = UserRelationshipStatus.friends;
          Get.snackbar('Success', "Friend Request Accepted");
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      Get.snackbar('Error', "Failed to accept friend request");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
              (r) => r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.none;
          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.declined,
          );
          Get.snackbar('Success', "Friend Request Declined");
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      Get.snackbar('Error', "Failed to decline friend request");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final relationship = _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if (relationship != UserRelationshipStatus.friends) {
          Get.snackbar('Info', "You can only chat with friends.");
          return;
        }
        final chatId = await _firestoreService.createOrGetChat(currentUserId, user.id);
        // Get.toNamed('/chat', arguments: {'chatId': chatId, 'user': user});
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', "Failed to start chat");
    } finally {
      _isLoading.value = false;
    }
  }

  UserRelationshipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipStatus.none;
  }

  // Helpers UI (couleurs, icones, textes...)
  String getRelationshipButtonText(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none: return 'Add Friend';
      case UserRelationshipStatus.friendRequestSent: return 'Request sent';
      case UserRelationshipStatus.friendRequestReceived: return 'Accept';
      case UserRelationshipStatus.friends: return 'Friends';
      case UserRelationshipStatus.blocked: return 'Blocked';
      default: return 'Add Friend';
    }
  }

  IconData getRelationshipButtonIcon(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none: return Icons.person_add;
      case UserRelationshipStatus.friendRequestSent: return Icons.access_time;
      case UserRelationshipStatus.friendRequestReceived: return Icons.check;
      case UserRelationshipStatus.friends: return Icons.chat_bubble_outline;
      case UserRelationshipStatus.blocked: return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none: return Colors.blue;
      case UserRelationshipStatus.friendRequestSent: return Colors.orange;
      case UserRelationshipStatus.friendRequestReceived: return Colors.green;
      case UserRelationshipStatus.friends: return Colors.purple;
      case UserRelationshipStatus.blocked: return Colors.red;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);
    switch (status) {
      case UserRelationshipStatus.none: sendFriendRequest(user); break;
      case UserRelationshipStatus.friendRequestSent: cancelFriendRequest(user); break;
      case UserRelationshipStatus.friendRequestReceived: acceptFriendRequest(user); break;
      case UserRelationshipStatus.friends: startChat(user); break;
      case UserRelationshipStatus.blocked: Get.snackbar('Info', "User blocked"); break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) return 'Online';
    if (user.lastSeen == null) return 'Offline';
    return 'Offline'; // Simplifié pour le mock
  }
}

// ---------------------------------------------------------------------------
// MOCK SERVICES & MODELS (Simulation du Backend)
// Ces classes simulent le travail de ton ami pour que tu puisses travailler.
// ---------------------------------------------------------------------------

class MockFirestoreService {
  // Simule une liste d'utilisateurs qui vient de la base de données
  Stream<List<UserModel>> getAllUsersStream() {
    return Stream.value([
      UserModel(id: 'user2', displayName: 'Alice Backend', email: 'alice@test.com', photoURL: 'https://i.pravatar.cc/150?u=alice', isOnline: true),
      UserModel(id: 'user3', displayName: 'Bob Database', email: 'bob@test.com', photoURL: '', isOnline: false),
      UserModel(id: 'user4', displayName: 'Charlie Firebase', email: 'charlie@test.com', photoURL: 'https://i.pravatar.cc/150?u=charlie', isOnline: true),
      UserModel(id: 'user5', displayName: 'Sarah Flutter', email: 'sarah@test.com', photoURL: null, isOnline: true),
      UserModel(id: 'user6', displayName: 'Thomas Code', email: 'thomas@test.com', photoURL: 'https://i.pravatar.cc/150?u=thomas', isOnline: false),
    ]);
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestsStream(String currentUserId) {
    return Stream.value([
      FriendRequestModel(
          id: 'req_sent_1',
          senderId: currentUserId,
          receiverId: 'user2', // On a envoyé une demande à Alice
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now()
      ),
    ]);
  }

  // Simule les requêtes reçues
  Stream<List<FriendRequestModel>> getFriendRequestsStream(String currentUserId) {
    return Stream.value([
      // Demande de Charlie
      FriendRequestModel(
          id: 'req1',
          senderId: 'user4',
          receiverId: currentUserId,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now().subtract(Duration(minutes: 30))
      ),
      // Demande de Sarah
      FriendRequestModel(
          id: 'req2',
          senderId: 'user5',
          receiverId: currentUserId,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now().subtract(Duration(hours: 2))
      ),
      // Demande de Thomas
      FriendRequestModel(
          id: 'req3',
          senderId: 'user6',
          receiverId: currentUserId,
          status: FriendRequestStatus.pending,
          createdAt: DateTime.now().subtract(Duration(days: 1))
      ),
    ]);
  }

  // Simule la liste d'amis
  Stream<List<FriendshipModel>> getFriendsStream(String currentUserId) {
    return Stream.value([]);
  }

  // Simule l'envoi d'une requête (attend 1 seconde puis valide)
  // Future<void> sendFriendRequest(FriendRequestModel request) async {
  //   await Future.delayed(Duration(seconds: 1)); // Simule le réseau
  //   print("MOCK: Requête d'ami envoyée à ${request.receiverId}");
  // }

  Future<void> cancelFriendRequest(String requestId) async {
    await Future.delayed(Duration(seconds: 1));
    print("MOCK: Requête annulée $requestId");
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await Future.delayed(Duration(seconds: 1));
    print("MOCK: Requête acceptée $requestId");
  }

  Future<void> respondToFriendRequest(String requestId, FriendRequestStatus status) async {
    await Future.delayed(Duration(seconds: 1));
    print("MOCK: Réponse à la requête $requestId : $status");
  }

  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    await Future.delayed(Duration(seconds: 1));
    return "mock_chat_id_123";
  }
}

// --- MODÈLES DE DONNÉES (DUMMY) ---
class FriendshipModel {
  final String id; // C'est toujours bien d'avoir un ID pour la relation elle-même
  final String user1Id;
  final String user2Id;
  final bool isBlocked;

  FriendshipModel({
    this.id = '', // Valeur par défaut ou requise
    required this.user1Id,
    required this.user2Id,
    this.isBlocked = false,
  });

  // Cette méthode permet de savoir qui est "l'autre" personne dans la relation
  String getOtherUserId(String currentUserId) {
    if (user1Id == currentUserId) {
      return user2Id;
    } else {
      return user1Id;
    }
  }
}