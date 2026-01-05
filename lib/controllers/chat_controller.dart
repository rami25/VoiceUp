// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:uuid/uuid.dart';
// import 'package:voiceup/models/models.dart';
// import 'package:voiceup/services/mock_firestore_service.dart';

// class ChatController extends GetxController {
//   final FirestoreService _firestoreService = FirestoreService();
//   final SpeechToText _speechToText = SpeechToText();
//   final FlutterTts _flutterTts = FlutterTts();
//   final Uuid _uuid = const Uuid();

//   // Observable Variables
//   ScrollController? _scrollController;
//   ScrollController get scrollController {
//     _scrollController ??= ScrollController();
//     return _scrollController!;
//   }
//   var messages = <MessageModel>[].obs;
//   var isRecording = false.obs;
//   var isSending = false.obs;
//   var transcribedText = "".obs; // Holds the text while user is speaking
//   var currentChatId = "".obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _initSpeech();
//     _initTTS();
//   }

//   // --- INITIALIZATION ---

//   void _initSpeech() async {
//     await _speechToText.initialize();
//   }

//   void _initTTS() async {
//     await _flutterTts.setLanguage("en-US");
//     await _flutterTts.setPitch(1.0);
//   }

//   // --- ACTIONS ---

//   /// 1. Start Recording Audio + Live Transcription
//   Future<void> startVoiceRecord() async {
//     transcribedText.value = "";
//     isRecording.value = true;
    
//     // Start the Speech-to-Text engine
//     await _speechToText.listen(
//       onResult: (result) {
//         transcribedText.value = result.recognizedWords;
//       },
//     );
    
//     // Note: You should also call your recorder.start() method here 
//     // to save the actual .m4a file to a local path.
//   }

//   /// 2. Stop Recording and Upload everything
//   Future<void> stopAndSendVoice(String localFilePath, String senderId, String receiverId) async {
//     isRecording.value = false;
//     await _speechToText.stop();

//     if (localFilePath.isEmpty) return;

//     try {
//       isSending.value = true;

//       // A. Upload the Audio file to Firebase Storage
//       String? audioUrl = await _firestoreService.uploadAudio(localFilePath);

//       if (audioUrl != null) {
//         // B. Create the Multi-Modal Message
//         final message = MessageModel(
//           id: _uuid.v4(),
//           senderId: senderId,
//           receiverId: receiverId,
//           content: audioUrl, // The link to hear it
//           transcription: transcribedText.value, // The text to read it
//           type: MessageType.audio,
//           timestamp: DateTime.now(),
//         );

//         // C. Send to Firestore
//         await _firestoreService.sendMessage(message);
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send voice note");
//     } finally {
//       isSending.value = false;
//     }
//   }

//   /// 3. Text-to-Speech: Listen to any message
//   Future<void> playTextAsSpeech(String text) async {
//     if (text.isNotEmpty) {
//       await _flutterTts.speak(text);
//     }
//   }

//   /// 4. Send standard Text Message
//   Future<void> sendTextMessage(String text, String senderId, String receiverId) async {
//     if (text.trim().isEmpty) return;

//     final message = MessageModel(
//       id: _uuid.v4(),
//       senderId: senderId,
//       receiverId: receiverId,
//       content: text,
//       type: MessageType.text,
//       timestamp: DateTime.now(),
//     );

//     await _firestoreService.sendMessage(message);
//   }

//   // --- STREAM LISTENER ---

//   void listenToMessages(String currentUserId, String otherUserId) {
//     _firestoreService.getMessagesStream(currentUserId, otherUserId).listen((data) {
//       messages.value = data;
//     });
//   }
// }






// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:uuid/uuid.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:voiceup/controllers/auth_controller.dart';
// import 'package:voiceup/models/models.dart';
// import 'package:voiceup/services/mock_firestore_service.dart';

// class ChatController extends GetxController {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthController _authController = Get.find<AuthController>();
//   final TextEditingController messageController = TextEditingController();
//   final Uuid _uuid = Uuid();
  
//   // Audio Recording Instance
//   final AudioRecorder _audioRecorder = AudioRecorder();

//   ScrollController? _scrollController;
//   ScrollController get scrollController {
//     _scrollController ??= ScrollController();
//     return _scrollController!;
//   }

//   // Reactive Variables
//   final RxList<MessageModel> _messages = <MessageModel>[].obs;
//   final RxBool _isLoading = false.obs;
//   final RxBool _isSending = false.obs;
//   final RxString _error = ''.obs;
//   final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
//   final RxString _chatId = ''.obs;
//   final RxBool _isTyping = false.obs;
//   final RxBool _isChatActive = false.obs;
  
//   // Voice Specific Reactive States
//   final RxBool _isRecording = false.obs;
//   final RxString _lastRecordingPath = ''.obs;

//   // Getters
//   List<MessageModel> get messages => _messages;
//   bool get isLoading => _isLoading.value;
//   bool get isSending => _isSending.value;
//   String get error => _error.value;
//   UserModel? get otherUser => _otherUser.value;
//   String get chatId => _chatId.value;
//   bool get isTyping => _isTyping.value;
//   bool get isRecording => _isRecording.value;

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeChat();
//     messageController.addListener(_onMessageChanged);
//   }

//   @override
//   void onClose() {
//     _isChatActive.value = false;
//     _markMessagesAsRead();
//     _audioRecorder.dispose(); // Important for memory
//     super.onClose();
//   }

//   void _initializeChat() {
//     final arguments = Get.arguments;
//     if (arguments != null) {
//       _chatId.value = arguments['chatId'] ?? '';
//       _otherUser.value = arguments['otherUser'];
//       _loadMessages();
//       _markMessagesAsRead();
//     }
//   }

//   Future<void> _markMessagesAsRead() async {
//     final currentUserId = _authController.user?.uid;
    
//     // We need a valid user and a chat ID to proceed
//     if (currentUserId != null && _chatId.value.isNotEmpty) {
//       try {
//         // 1. Check if there are any unread messages for the current user in this chat
//         final hasUnread = _messages.any((m) => 
//           m.receiverId == currentUserId && !m.isRead
//         );

//         if (hasUnread) {
//           // 2. Call the service to reset the count in Firestore
//           await _firestoreService.restoreUnreadCount(_chatId.value, currentUserId);
          
//           // 3. Update the local list so the UI reflects the "read" state immediately
//           for (var i = 0; i < _messages.length; i++) {
//             if (_messages[i].receiverId == currentUserId && !_messages[i].isRead) {
//               _messages[i] = _messages[i].copyWith(isRead: true);
//             }
//           }
//           _messages.refresh(); // Notify GetX listeners
//         }
//       } catch (e) {
//         print("Error marking messages as read: $e");
//       }
//     }
//   }
//   // --- Voice Recording Logic ---

//   Future<void> startRecording() async {
//     try {
//       if (await _audioRecorder.hasPermission()) {
//         final directory = await getApplicationDocumentsDirectory();
//         final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
//         const config = RecordConfig(); 

//         await _audioRecorder.start(config, path: path);
//         _isRecording.value = true;
//       }
//     } catch (e) {
//       print("Start recording error: $e");
//     }
//   }

//   Future<void> stopAndSendVoice() async {
//     try {
//       final path = await _audioRecorder.stop();
//       _isRecording.value = false;

//       if (path != null) {
//         _lastRecordingPath.value = path;
//         await _uploadAndSendVoice(path);
//       }
//     } catch (e) {
//       print("Stop recording error: $e");
//     }
//   }

//   Future<void> _uploadAndSendVoice0(String filePath) async {
//     final currentUserId = _authController.user?.uid;
//     final otherUserId = _otherUser.value?.id;

//     if (currentUserId == null || otherUserId == null) return;

//     try {
//       _isSending.value = true;

//       // 1. Upload to Firebase Storage
//       File file = File(filePath);
//       String fileName = '${_uuid.v4()}.m4a';
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child('chats/${_chatId.value}/voices/$fileName');

//       UploadTask uploadTask = ref.putFile(file);
//       TaskSnapshot snapshot = await uploadTask;
//       String downloadUrl = await snapshot.ref.getDownloadURL();

//       // 2. Create Message Model
//       final message = MessageModel(
//         id: _uuid.v4(),
//         senderId: currentUserId,
//         receiverId: otherUserId,
//         content: downloadUrl, // The URL of the voice file
//         type: MessageType.audio, // Ensure your enum supports 'audio'
//         timestamp: DateTime.now(),
//       );

//       // 3. Update UI and Send
//       _messages.add(message);
//       _scrollToBottom();
//       await _firestoreService.sendMessage(message);

//     } catch (e) {
//       Get.snackbar("Error", "Failed to upload voice message");
//     } finally {
//       _isSending.value = false;
//     }
//   }

//   Future<void> _uploadAndSendVoice(String filePath) async {
//     final currentUserId = _authController.user?.uid;
//     final otherUserId = _otherUser.value?.id;

//     if (currentUserId == null || otherUserId == null) return;

//     try {
//       _isSending.value = true;

//       // 1. Validate the file exists (Previosly causing errors on Browser/Emulator)
//       File file = File(filePath);
//       if (!await file.exists()) {
//         print("File does not exist at: $filePath");
//         return;
//       }

//       // 2. Upload to Firebase Storage
//       String fileName = '${_uuid.v4()}.m4a';
//       // Use a clean path for the reference
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child('chats')
//           .child(_chatId.value)
//           .child('voices')
//           .child(fileName);

//       UploadTask uploadTask = ref.putFile(file);
      
//       // Optional: Monitor upload progress here if you want a progress bar
//       TaskSnapshot snapshot = await uploadTask;
//       String downloadUrl = await snapshot.ref.getDownloadURL();

//       // 3. Create Message Model (Using the Storage URL)
//       final message = MessageModel(
//         id: _uuid.v4(),
//         senderId: currentUserId,
//         receiverId: otherUserId,
//         content: downloadUrl, 
//         type: MessageType.audio, 
//         timestamp: DateTime.now(),
//         isRead: false,
//       );

//       // 4. THE KEY CHANGE: Send to Firebase FIRST
//       // Do not just add to the local list. Let the Stream handle the UI update.
//       await _firestoreService.sendMessage(message);

//       // 5. Update UI locally for "Snappy" feel (Optimistic Update)
//       if (!_messages.any((m) => m.id == message.id)) {
//         _messages.add(message);
//         _scrollToBottom();
//       }

//     } catch (e) {
//       print("Full Error in _uploadAndSendVoice: $e");
//       Get.snackbar("Error", "Failed to upload voice message: ${e.toString()}");
//     } finally {
//       _isSending.value = false;
//     }
//   }

//   // --- Core Message Logic ---

//   Future<void> _loadMessages() async {
//     final currentUserId = _authController.user?.uid;
//     final otherUserId = _otherUser.value?.id;

//     if (currentUserId != null && otherUserId != null) {
//       try {
//         _isLoading.value = true;
//         final messageList = await _firestoreService.getMessagesFuture(currentUserId, otherUserId);
//         _messages.assignAll(messageList);
        
//         if (_isChatActive.value) {
//           _markUnreadMessagesAsRead(messageList);
//         }
//         Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());
//       } catch (e) {
//         _error.value = "Failed to load chat history";
//       } finally {
//         _isLoading.value = false;
//       }
//     }
//   }

//   Future<void> sendMessage() async {
//     // Keeping this for text, but you can hide the UI for it
//     final currentUserId = _authController.user?.uid;
//     final otherUserId = _otherUser.value?.id;
//     final content = messageController.text.trim();
//     messageController.clear();

//     if (currentUserId == null || otherUserId == null || content.isEmpty) return;

//     try {
//       _isSending.value = true;
//       final message = MessageModel(
//         id: _uuid.v4(),
//         senderId: currentUserId,
//         receiverId: otherUserId,
//         content: content,
//         type: MessageType.text,
//         timestamp: DateTime.now(),
//       );
//       _messages.add(message);
//       _scrollToBottom();
//       await _firestoreService.sendMessage(message);
//     } catch (e) {
//       Get.snackbar("Error", "Failed to send message");
//     } finally {
//       _isSending.value = false;
//     }
//   }

//   // --- Utility Methods ---

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController != null && _scrollController!.hasClients) {
//         _scrollController!.animateTo(
//           _scrollController!.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
//     final currentUserId = _authController.user?.uid;
//     if (currentUserId == null) return;
//     try {
//       final unreadMessages = messageList.where((m) =>
//           m.receiverId == currentUserId && !m.isRead && m.senderId != currentUserId).toList();

//       for (var message in unreadMessages) {
//         await _firestoreService.markMessageAsRead(message.id);
//       }

//       if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
//         await _firestoreService.restoreUnreadCount(_chatId.value, currentUserId);
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   bool isMyMessage(MessageModel message) => message.senderId == _authController.user?.uid;

//   String formatMessageTime(DateTime timestamp) {
//     // ... (Your existing formatting logic)
//     return "${timestamp.hour}:${timestamp.minute}";
//   }

//   void _onMessageChanged() => _isTyping.value = messageController.text.isNotEmpty;
  
//   void onChatResumed() {
//     _isChatActive.value = true;
//     _markUnreadMessagesAsRead(_messages);
//   }

//   void onChatPaused() => _isChatActive.value = false;

//   Future<void> deleteChat() async { /* ... Same as your previous logic ... */ }
// }






import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:uuid/uuid.dart';
import 'package:voiceup/controllers/auth_controller.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/services/mock_firestore_service.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController messageController = TextEditingController();
  final Uuid _uuid = Uuid();

  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
  final RxString _chatId = ''.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatActive = false.obs;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  String get error => _error.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    _initializeChat();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    _isChatActive.value = true;
  }
  @override
  void onClose() {
    // TODO: implement onClose
    _isChatActive.value = false;
    _markMessagesAsRead();
    super.onClose();
  }
  void _initializeChat() {
    final arguments = Get.arguments;
    if (arguments != null) {
      _chatId.value = arguments['chatId'] ?? '';
      _otherUser.value = arguments['otherUser'];
      _loadMessages();
      _markMessagesAsRead();
    }
  }
  // void _loadMessages() {
  //   final currentUserId = _authController.user?.uid;
  //   final otherUserId = _otherUser.value?.id;

  //   if (currentUserId != null && otherUserId != null) {
  //     _messages.bindStream(
  //         _firestoreService.getMessagesStream(currentUserId, otherUserId)
  //     );

  //     ever(_messages, (List<MessageModel> messageList) {
  //       if (_isChatActive.value) {
  //         _markUnreadMessagesAsRead(messageList);
  //       }
  //       _scrollToBottom();
  //     });
  //   }
  // }
  Future<void> _loadMessages() async {
  final currentUserId = _authController.user?.uid;
  final otherUserId = _otherUser.value?.id;

  if (currentUserId != null && otherUserId != null) {
    try {
      _isLoading.value = true;
      _error.value = '';

      // 1. Fetch messages once from Firestore
      final messageList = await _firestoreService.getMessagesFuture(currentUserId, otherUserId);

      // 2. Update the RxList manually
      _messages.assignAll(messageList);
      print(_messages);

      // 3. Handle side effects (Read status and Scroll)
      if (_isChatActive.value) {
        // We can run this without 'await' if we don't want to block the UI
        _markUnreadMessagesAsRead(messageList);
      }
      
      // Give the UI a frame to render the new list before scrolling
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToBottom());

    } catch (e) {
        _error.value = "Failed to load chat history: $e";
        print("Error in _loadMessages: $e");
      } finally {
        _isLoading.value = false;
      }
    }
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  Future<void> _markUnreadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      final unreadMessages = messageList.where((message) =>
      message.receiverId == currentUserId &&
          !message.isRead &&
          message.senderId != currentUserId
      ).toList();

      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        await _firestoreService.restoreUnreadCount(_chatId.value, currentUserId);
      }
      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      print(e);
    }
  }
  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Delete Chat"),
          content: Text("Are you sure you want to delete this chat? This action cannot be undone"),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text("Delete"),
            ),
          ],
        ),
      );
      if (result == true) {
        _isLoading.value = true;
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        Get.delete<ChatController>(tag: _chatId.value);
        Get.back();
        Get.snackbar("Success", 'Chat Deleted');
      }
    } catch (e) {
      _error.value = e.toString();
      print(e);
      Get.snackbar("Error", 'Failed to delete chat');
    } finally {
      _isLoading.value = false;
    }
  }
  void _onMessageChanged() {
    _isTyping.value = messageController.text.isNotEmpty;
  }

  Future<void> sendMessage() async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();
    messageController.clear();

    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      Get.snackbar("Error", 'You cannot send messages to this user');
      return;
    }
    if (await _firestoreService.isUnfriended(currentUserId, otherUserId)) {
      Get.snackbar(
        "Error",
        'You cannot send messages to this user as you are not friends',
      );
      return;
    }
    try {
      _isSending.value = true;

      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      _messages.add(message);
      _isTyping.value = false;
      _scrollToBottom();
      await _firestoreService.sendMessage(message);
    } catch (e) {
     Get.snackbar("Error", "You cannot send message");
    } finally {
      _isSending.value = false;
    }
  }
  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        await _firestoreService.restoreUnreadCount(_chatId.value, currentUserId);
      }
      catch(e) {
        print(e);
      }
    }
  }
  void onChatResumed() {
    _isChatActive.value = true;
    _markUnreadMessagesAsRead(_messages);
  }

  void onChatPaused() {
    _isChatActive.value = false;
  }
  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar("Success", 'Message Delete');
    } catch(e) {
      Get.snackbar('Error', 'Failed to delete message');
      print(e);
    }
  }

  Future<void> editMessage(MessageModel message,String newContent) async {
    try {
      await _firestoreService.editMessage(message.id,newContent);
      Get.snackbar("Success", 'Message Edited');
    } catch(e) {
      Get.snackbar('Error', 'Failed to Edit message');
      print(e);
    }
  }
  bool isMyMessage(MessageModel message){
    return message.senderId == _authController.user?.uid;
  }

  String formatMessageTime(DateTime timestamp){
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if(difference.inMinutes < 1){
      return "Just now";
    }
    else if(difference.inHours < 1){
      return '${difference.inMinutes}m ago';
    }
    else if(difference.inDays < 1){
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    else if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
void clearError(){
    _error.value='';
}
}
