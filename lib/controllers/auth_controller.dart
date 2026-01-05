// import 'package:get/get.dart';
// import 'package:voiceup/models/models.dart';


// class AuthController extends GetxController {
//   RxBool isAuthenticated = true.obs;
//   RxBool isLoading = false.obs;

//   // Utilisation du UserModel importé
//   final Rx<UserModel> currentUser = UserModel(
//     id: 'user1', // ID nécessaire pour UsersListController
//     displayName: 'Mohamed Amine Hattay',
//     email: 'hattay112@gmail.com',
//     isOnline: true,
//     lastSeen: DateTime.now(),
//     photoURL: 'https://i.pravatar.cc/150?img=3',
//   ).obs;

//   // CORRECTION ICI : Retourner la valeur actuelle, pas null
//   UserModel? get user => currentUser.value;


//   void signInWithEmailAndPassword(String email, String password) async {
//     isLoading.value = true;
//     await Future.delayed(const Duration(seconds: 2));
//     isAuthenticated.value = true;
//     currentUser.value = UserModel(
//       id: 'user1', // Mock ID
//       displayName: 'Mohamed Amine Hattay',
//       email: email,
//       photoURL: 'https://i.pravatar.cc/150?img=3',
//     );
//     isLoading.value = false;
//     print("Login mock pour $email");
//   }

//   void registerWithEmailAndPassword(String email, String password, String name) async {
//     isLoading.value = true;
//     await Future.delayed(const Duration(seconds: 2));
//     isAuthenticated.value = true;
//     currentUser.value = UserModel(
//       id: 'user_new', // Mock ID
//       displayName: name,
//       email: email,
//       photoURL: 'https://i.pravatar.cc/150?img=3',
//     );
//     isLoading.value = false;
//     print("Register mock pour $email / $name");
//   }

//   void logout() {
//     isAuthenticated.value = false;
//     print("Logout mock");
//   }

//   Future<void> signOut() async {}
// }


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voiceup/routes/app_routes.dart';
import 'package:voiceup/models/models.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxBool isAuthenticated = false.obs;
  RxBool isLoading = false.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  UserModel? get user => currentUser.value;

  @override
  void onInit() {
    super.onInit();

    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        isAuthenticated.value = false;
        currentUser.value = null;
      } else {
        isAuthenticated.value = true;
        _loadUserFromFirestore(firebaseUser.uid);
      }
    });
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      isLoading.value = true;

      UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      await _loadUserFromFirestore(uid);

      print("Login success: $email");
      Get.snackbar(
        'Success',
        'Login successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.main);
      });

    } on FirebaseAuthException catch (e) {
      print("Auth error: ${e.code}");
      Get.snackbar(
        'Login Failed',
        e.message ?? 'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      isLoading.value = true;

      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      await user.updateDisplayName(name);

      UserModel newUser = UserModel(
        id: user.uid,
        displayName: name,
        email: email,
        photoURL:
        user.photoURL ?? 'https://ui-avatars.com/api/?name=$name',
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toJson());

      currentUser.value = newUser;
      isAuthenticated.value = true;

      print("Register success: $email");
      Get.snackbar(
        'Success',
        'Register successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed(AppRoutes.main);
      });

    } on FirebaseAuthException catch (e) {
      print("Register error: ${e.code}");
      Get.snackbar(
        'Register Failed',
        e.message ?? 'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserFromFirestore(String uid) async {
    final doc =
        await _firestore.collection('users').doc(uid).get();

    if (doc.exists) {
      currentUser.value = UserModel.fromJson(doc.data()!);
    }
  }

  Future<void> signOut() async {
    if (currentUser.value != null) {
      await _firestore
          .collection('users')
          .doc(currentUser.value!.id)
          .update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }

    await _auth.signOut();
    isAuthenticated.value = false;
    currentUser.value = null;

    print("Logout success");
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(AppRoutes.login);
    });
  }

}
