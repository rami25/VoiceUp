import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final RxBool _isEditing = false.obs;
  final RxBool _isLoading = false.obs;

  bool get isEditing => _isEditing.value;
  bool get isLoading => _isLoading.value;
  UserModel? get currentUser => authController.currentUser.value;

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  GestureTapCallback? get deleteAccount => () {
    print("Delete account mock");
    Get.snackbar("Info", "Delete Account clicked (mock)");
  };

  GestureTapCallback? get signOut => () {
    authController.logout();
    Get.snackbar("Info", "Signed out (mock)");
  };

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    if (currentUser != null) {
      displayNameController.text = currentUser!.displayName;
      emailController.text = currentUser!.email;
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
  }

  void updateProfile() async {
    if (currentUser == null) return;
    _isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    authController.currentUser.value = UserModel(
      displayName: displayNameController.text,
      email: emailController.text,
      photoURL: currentUser!.photoURL,
    );
    _isEditing.value = false;
    _isLoading.value = false;
  }

  @override
  void onClose() {
    displayNameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  String getJoinedData() {
    return "${currentUser?.displayName ?? ''} | ${currentUser?.email ?? ''}";
  }
}
