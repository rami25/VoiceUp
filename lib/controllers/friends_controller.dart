import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// CORRECTION 1 : On retire "hide FriendshipModel" pour pouvoir utiliser la classe
import 'package:voiceup/models/models.dart';
import 'package:voiceup/routes/app_routes.dart';
import 'package:voiceup/services/mock_firestore_service.dart';
import 'package:voiceup/controllers/auth_controller.dart';

class FriendsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  // On récupère le AuthController, mais on gère le cas où il n'est pas encore prêt
  AuthController get _authController {
    try {
      return Get.find<AuthController>();
    } catch (e) {
      // Cas rare pour le test si AuthController n'est pas injecté
      return Get.put(AuthController());
    }
  }

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;
  final RxList<UserModel> _friends = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxList<UserModel> _filteredFriends = <UserModel>[].obs;
  StreamSubscription? _friendshipsSubscriptions;

  List<FriendshipModel> get friendships => _friendships.toList();
  List<UserModel> get friends => _friends;
  List<UserModel> get filteredFriends => _filteredFriends;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    _loadFriends();

    debounce(_searchQuery, (_) => _filterFriends(),
        time: Duration(milliseconds: 300));
  }

  @override
  void onClose() {
    _friendshipsSubscriptions?.cancel();
    super.onClose();
  }

  Future<void> _loadFriends() async {
    try {
      final currentUserId = _authController.user?.uid ?? 'CURRENT_USER_ID';

      _isLoading.value = true;
      _error.value = '';

      // 3. Fetch the friendships using the latest Future-based method
      // (This uses the Filter.or logic we implemented in the service)
      final friendshipList = await _firestoreService.getFriendsFuture(currentUserId);

      // 4. Update the local RxList
      _friendships.value = friendshipList;

      // 5. Load the details (UserModels) for these friends
      if (friendshipList.isNotEmpty) {
        await _loadFriendDetails(currentUserId, friendshipList);
      }
    } catch (e) {
      print("Error loading friends: $e");
      _error.value = e.toString();
    } finally {
      // 6. Stop loading state regardless of success or failure
      _isLoading.value = false;
    }
  }
  // void _loadFriends() {
  //   // CORRECTION 2 : Fallback sur l'ID du Mock si l'auth est null
  //   final currentUserId = _authController.user?.uid ?? 'CURRENT_USER_ID';

  //   _friendshipsSubscriptions?.cancel();

  //   _isLoading.value = true; // On commence le chargement

  //   _friendshipsSubscriptions = _firestoreService
  //       .getFriendsStream(currentUserId)
  //       .listen((friendshipList) {
  //     _friendships.value = friendshipList;

  //     // On charge les détails des amis basés sur la liste reçue
  //     _loadFriendDetails(
  //         currentUserId, friendshipList);
  //   }, onError: (e) {
  //     _error.value = e.toString();
  //     _isLoading.value = false;
  //   });
  // }

  Future<void> _loadFriendDetails(String currentUserId,
      List<FriendshipModel> friendshipList) async {
    try {
      // _isLoading.value = true; // Déjà géré par le stream listener initial ou on peut le laisser ici

      List<UserModel> friendUsers = [];

      final futures = friendshipList.map((friendship) async {
        // Cette méthode doit exister dans FriendshipModel
        String friendId = friendship.getOtherUserId(currentUserId);
        return await _firestoreService.getUser(friendId);
      }).toList();

      final results = await Future.wait(futures);

      for (var friend in results) {
        if (friend != null) {
          friendUsers.add(friend);
        }
      }

      _friends.value = friendUsers;
      _filterFriends(); // Appliquer le filtre initial (ou vide)

    } catch (e) {
      _error.value = e.toString();
      print("Erreur chargement détails amis: $e");
    } finally {
      _isLoading.value = false;
    }
  }

  void _filterFriends() {
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredFriends.value = _friends;
    } else {
      _filteredFriends.value = _friends.where((friend) {
        return friend.displayName.toLowerCase().contains(query) ||
            friend.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
    // updateSearchQuery('') déclenche le debounce, on peut appeler _filterFriends directement pour l'instantanéité
    _filterFriends();
  }

  Future<void> refreshFriends() async {
    // Simplement recharger la logique
    _loadFriends();
    // Petit délai artificiel pour voir le loader si besoin
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> removeFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove ${friend.displayName} from your friends?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (result == true) {
        final currentUserId = _authController.user?.uid ?? 'CURRENT_USER_ID';

        await _firestoreService.removeFriendShip(currentUserId, friend.id);

        Get.snackbar(
          'Success',
          '${friend.displayName} has been removed from your friends.',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: Duration(seconds: 4),
        );
        // Pas besoin de recharger manuellement, le Stream s'en occupe !
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to remove friend',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> blockFriend(UserModel friend) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${friend.displayName}? You will no longer be able to interact with each other.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      if (result == true) {
        final currentUserId = _authController.user?.uid ?? 'CURRENT_USER_ID';

        await _firestoreService.blockUser(currentUserId, friend.id);

        Get.snackbar(
          'Success',
          '${friend.displayName} has been blocked.',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to block user',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> startChat(UserModel friend) async {
    try {
      // On passe simplement l'utilisateur au ChatController via les arguments
      Get.toNamed(
        AppRoutes.chat,
        arguments: {
          'otherUser': friend,
          // On peut laisser le ChatController déterminer s'il faut créer un ID ou non
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to start chat',
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
      );
      print(e.toString());
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return 'Online';
    }

    if (user.lastSeen == null) {
      return 'Offline';
    }

    final now = DateTime.now();
    final difference = now.difference(user.lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${user.lastSeen!.day}/${user.lastSeen!.month}/${user.lastSeen!.year}';
    }
  }

  void openFriendRequests() {
    Get.toNamed(AppRoutes.friendRequests);
  }

  void clearError() {
    _error.value = '';
  }
}