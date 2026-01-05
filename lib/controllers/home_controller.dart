import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:voiceup/controllers/auth_controller.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/routes/app_routes.dart';
import 'package:voiceup/services/mock_firestore_service.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ChatModel> _allChats = <ChatModel>[].obs;
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxString _activeFilter = 'All'.obs;

  List<ChatModel> get chats => _getFilteredChats();

  List<ChatModel> get allChats => _allChats;

  List<ChatModel> get filteredChats => _filteredChats;

  List<NotificationModel> get notifications => _notifications;

  bool get isLoading => _isLoading.value;

  String get error => _error.value;

  String get searchQuery => _searchQuery.value;

  bool get isSearching => _isSearching.value;

  String get activeFilter => _activeFilter.value;

  Map<String, UserModel> get users => _users;

  DateTime get now => DateTime.now();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _loadChats();
    _loadUsers();
    _loadNotifications();
  }

  // void _loadChats() {
  //   final currentUserId = _authController.user?.uid;
  //   if (currentUserId != null) {
  //     _allChats.bindStream(_firestoreService.getUserChatsStream(currentUserId));

  //     ever(_allChats, (_) {
  //       if (_isSearching.value && _searchQuery.value.isNotEmpty) {
  //         _performSearch(_searchQuery.value);
  //       }
  //     });

  //     ever(_activeFilter, (_) {
  //       if (_searchQuery.value.isNotEmpty) {
  //         _performSearch(_searchQuery.value);
  //       }
  //     });
  //   }
  // }

  Future<void> _loadChats() async {
    final currentUserId = _authController.user?.uid;
    
    if (currentUserId != null) {
      try {
        _isLoading.value = true;
        _error.value = '';

        // 1. Fetch the chats using the new Future-based method
        final chatList = await _firestoreService.getUserChatsFuture(currentUserId);

        // 2. Update the RxList
        _allChats.assignAll(chatList);

        // 3. Manually trigger search/filter logic if needed
        // Since we don't have a stream 'ever' watching for us, 
        // we run it immediately after the data is loaded.
        if (_searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }

      } catch (e) {
        _error.value = "Failed to load inbox: $e";
        print("Error in _loadChats: $e");
      } finally {
        _isLoading.value = false;
      }
    }
  }

  void _loadUsers() async {
    final res = await _firestoreService.getAllUsers(); // List<UserModel>
    Map<String, UserModel> userMap = {};
    for (var user in res) {
      userMap[user.id] = user;
    }
    _users.assignAll(userMap); // _users is RxMap<String, UserModel>
  }

  // void _loadUsers() {
  //   _users.bindStream(
  //     _firestoreService.getAllUsersStream().map((userList) {
  //       Map<String, UserModel> userMap = {};
  //       for (var user in userList) {
  //         userMap[user.id] = user;
  //       }
  //       return userMap;
  //     }),
  //   );
  // }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      return _users[otherUserId];
    }
    return null;
  }

  String formatLastMessageTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  List<ChatModel> _getFilteredChats() {
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;
    switch (_activeFilter.value) {
      case 'Unread':
        return _applyUnreadFilter(baseList);
      case 'Recent':
        return _applyRecentFilter(baseList);
      case 'Active':
        return _applyActiveFilter(baseList);
      case 'All':
      default:
        return baseList;
    }
  }

  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return [];

    return chats
        .where((chat) => chat.getUnreadCount(currentUserId) > 0)
        .toList();
  }

  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(threeDaysAgo);
    }).toList();
  }

  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(oneWeekAgo);
    }).toList();
  }

  void setFilter(String filterType) {
    _activeFilter.value = filterType;

    if (filterType == 'All') {
      if (_searchQuery.value.isEmpty) {
        _isSearching.value = false;
        _filteredChats.clear();
      }
    }
  }

  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _clearSearch();
    } else {
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();

    _filteredChats.value = _allChats.where((chat) {
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;

      final displayNameMatch =
          otherUser.displayName.toLowerCase().contains(lowercaseQuery) ?? false;

      final emailMatch =
          otherUser.email.toLowerCase().contains(lowercaseQuery) ?? false;

      final lastMessageMatch =
          chat.lastMessage?.toLowerCase().contains(lowercaseQuery) ?? false;

      return displayNameMatch || emailMatch || lastMessageMatch;
    }).toList();
    _sortSearchResults(lowercaseQuery);
  }

  void _sortSearchResults(String query) {
    _filteredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      final exactMatchA =
          userA.displayName.toLowerCase().startsWith(query) ?? false;

      final exactMatchB =
          userB.displayName.toLowerCase().startsWith(query) ?? false;

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;
      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
  }

  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
  }

  void searchUserByName(String name) {
    onSearchChanged(name);
  }

  void searchByLastMessage(String message) {
    onSearchChanged(message);
  }

  List<ChatModel> getUnreadChats() {
    return _applyUnreadFilter(chats);
  }

  List<ChatModel> getActiveChats() {
    return _applyActiveFilter(_allChats);
  }

  List<ChatModel> getRecentChats({int limit = 10}) {
    final recentChats = _applyRecentFilter(_allChats);

    final sortedChats = List<ChatModel>.from(recentChats);
    sortedChats.sort((a, b) {
      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });

    return sortedChats.take(limit).toList();
  }

  int getUnreadCount() {
    return getUnreadChats().length;
  }

  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  int getActiveCount() {
    return getActiveChats().length;
  }

  List<String> getSearchSuggestions() {
    final suggestions = <String>[];

    for (var chat in _allChats) {
      final otherUser = getOtherUser(chat);
      if (otherUser?.displayName != null) {
        suggestions.add(otherUser!.displayName);
      }
    }

    return suggestions.toSet().toList();
  }

  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);
    if (otherUser != null) {
      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chat.id, 'otherUser': otherUser},
      );
    }
  }

  void openFriends() {
    Get.toNamed(AppRoutes.friends);
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> refreshChats() async {
    _isLoading.value = true;

    try {
      await Future.delayed(Duration(seconds: 1));

      if (_isSearching.value && _searchQuery.value.isNotEmpty) {
        _performSearch(_searchQuery.value);
      }
    } catch (e) {
      _error.value = 'Failed to refresh chats';
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return 0;
    int total = 0;
    for (var chat in _allChats) {
      total += (chat.getUnreadCount(currentUserId) ?? 0).toInt();
    }
    return total;
  }

  int getUnreadNotificationsCount() {
      return _notifications
          .where((notif) => !notif.isRead)
          .length;
    }

    Future<void> deleteChat(ChatModel chat) async {
      try {
        final currentUserId = _authController.user?.uid;
        if (currentUserId == null) return;

        final otherUser = getOtherUser(chat);

        final result = await Get.dialog<bool>(
          AlertDialog(
            title: Text('Delete Chat'),
            content: Text('Are you sure you want to delete the chat with ${otherUser?.displayName ?? 'this user'}?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Delete',style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (result == true) {
          await _firestoreService.deleteChatForUser(chat.id, currentUserId);

          Get.snackbar(
            'Success',
            'Chat deleted successfully',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        print(e.toString());
        Get.snackbar(
          'Error',
          'Failed to delete chat',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        print(e.toString());
      }
    }
  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }
  }
