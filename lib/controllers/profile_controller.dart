import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voiceup/models/models.dart';
import 'auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();

  final RxBool _isEditing = false.obs;
  final RxBool _isLoading = false.obs;

  bool get isEditing => _isEditing.value;
  bool get isLoading => _isLoading.value;

  // CORRECTION ICI : J'ai ajouté le '?' après UserModel
  UserModel? get currentUser => authController.currentUser.value;

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  GestureTapCallback? get deleteAccount => () {
    print("Delete account mock");
    Get.snackbar("Info", "Delete Account clicked (mock)");
  };

  GestureTapCallback? get signOut => () {
    authController.signOut();
    Get.snackbar("Info", "Signed out");
  };

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    // Maintenant cette condition est valide car currentUser peut être null
    if (currentUser != null) {
      displayNameController.text = currentUser!.displayName;
      emailController.text = currentUser!.email;
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      _loadUserData(); // Reset les champs si on annule
    }
  }


  void updateProfile() async {
    if (currentUser == null) return;
    _isLoading.value = true;
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.id);

      await userDoc.update({
        'displayName': displayNameController.text,
        'email': emailController.text,
        // If you want to allow updating photoURL or other fields, add them here
      });

      authController.currentUser.value = UserModel(
        id: currentUser!.id,
        displayName: displayNameController.text,
        email: emailController.text,
        photoURL: currentUser!.photoURL,
        isOnline: currentUser!.isOnline,
        lastSeen: currentUser!.lastSeen,
      );

      _isEditing.value = false;
      Get.snackbar("Success", "Profile updated");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update profile: ${e.toString()}",
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
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