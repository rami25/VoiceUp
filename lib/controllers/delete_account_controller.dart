import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voiceup/controllers/auth_controller.dart';
import 'package:voiceup/routes/app_routes.dart';

class DeleteAccountController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxBool _obscurePassword = true.obs;

  bool get isLoading => _isLoading.value;
  bool get obscurePassword => _obscurePassword.value;

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> deleteAccount() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();

      Get.snackbar(
        'Account Deleted',
        'Your account has been permanently deleted',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 3),
      );

      await _authController.signOut();

      Get.offAllNamed(AppRoutes.login);

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'requires-recent-login':
          message = 'Please log in again to delete your account';
          break;
        default:
          message = 'Failed to delete account';
      }

      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
