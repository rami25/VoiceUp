import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voiceup/controllers/auth_controller.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/services/mock_firestore_service.dart';

class FriendRequestsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<FriendRequestModel> _receivedRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _sentRequests = <FriendRequestModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxInt _selectedTabIndex = 0.obs;

  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  int get selectedTabIndex => _selectedTabIndex.value;
  @override
  void onInit() {
    super.onInit();
    loadFriendRequests();
    _loadUsers();
  }

  void loadFriendRequests() async {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      // _receivedRequests.bindStream(
      //   _firestoreService.getFriendRequestsStream(currentUserId),
      // );
      final res = await _firestoreService.getFriendRequests(currentUserId);
      _receivedRequests.assignAll(res);

      _sentRequests.bindStream(
        _firestoreService.getSentFriendRequestsStream(currentUserId),
      );
    }
  }
  void _loadUsers() async {
    final res = await _firestoreService.getAllUsers(); // List<UserModel>
    Map<String, UserModel> userMap = {};
    for (var user in res) {
      userMap[user.id] = user;
    }
    _users.assignAll(userMap); // _users is RxMap<String, UserModel>
    // _users.bindStream(
    //   _firestoreService.getAllUsersStream().map((userList) {
    //     Map<String, UserModel> userMap = {};
    //     for (var user in userList) {
    //       userMap[user.id] = user;
    //     }
    //     return userMap;
    //   }),
    // );
  }
  void changeTab(int index) {
    _selectedTabIndex.value = index;
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      await _firestoreService.acceptFriendRequest(request.id);
      // await _firestoreService.respondToFriendRequest(
      //   request.id,
      //   FriendRequestStatus.accepted,
      // );

      Get.snackbar('Success', 'Friend request accepted');
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to accept friend request';
    } finally {
      _isLoading.value = false;
    }
  }
  Future<void> declineFriendRequest(FriendRequestModel request) async {
    try {
      _isLoading.value = true;
      await _firestoreService.respondToFriendRequest(
        request.id,
        FriendRequestStatus.declined,
      );

      Get.snackbar('Success', 'Friend request declined');
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to decline friend request';
    } finally {
      _isLoading.value = false;
    }
  }
  Future<void> unblockUser(String userId) async {
    try {
      _isLoading.value = true;
      await _firestoreService.unblockUser(_authController.user!.uid, userId);
      Get.snackbar('Success', 'User unblocked successfully');
    } catch (e) {
      print(e.toString());
      _error.value = 'Failed to unblock user';
    } finally {
      _isLoading.value = false;
    }
  }
  String getRequestTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
  String getStatusText(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return "Pending";
      case FriendRequestStatus.accepted:
        return "Accepted";
      case FriendRequestStatus.declined:
        return "Declined";
    }
  }
  Color getStatusColor(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return Colors.orange;
      case FriendRequestStatus.accepted:
        return Colors.green;
      case FriendRequestStatus.declined:
        return Colors.red;
    }
  }
 void clearError(){
    _error.value ='';
 }
}