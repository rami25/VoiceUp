import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:voiceup/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:voiceup/routes/app_pages.dart';
import 'package:voiceup/theme/app_theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "VoiceUp",
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:record/record.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';

// void main() {
//   runApp(const VoiceTestApp());
// }

// class VoiceTestApp extends StatelessWidget {
//   const VoiceTestApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: VoiceTestPage(),
//     );
//   }
// }

// class VoiceTestPage extends StatefulWidget {
//   const VoiceTestPage({super.key});

//   @override
//   State<VoiceTestPage> createState() => _VoiceTestPageState();
// }

// class _VoiceTestPageState extends State<VoiceTestPage> {
//   final AudioRecorder _recorder = AudioRecorder();
//   final AudioPlayer _player = AudioPlayer();

//   bool isRecording = false;
//   String? audioPath;

//   Future<void> startRecording() async {
//     final mic = await Permission.microphone.request();
//     if (!mic.isGranted) return;

//     final dir = await getTemporaryDirectory();
//     audioPath = '${dir.path}/voice_test.m4a';

//     await _recorder.start(
//       const RecordConfig(
//         encoder: AudioEncoder.aacLc,
//         sampleRate: 44100,
//         bitRate: 128000,
//       ),
//       path: audioPath!,
//     );

//     setState(() => isRecording = true);
//   }

//   Future<void> stopRecording() async {
//     await _recorder.stop();
//     setState(() => isRecording = false);
//   }

//   Future<void> playRecording() async {
//     if (audioPath == null) return;
//     await _player.setFilePath(audioPath!);
//     _player.play();
//   }

//   @override
//   void dispose() {
//     _recorder.dispose();
//     _player.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Voice Test")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               isRecording ? Icons.mic : Icons.mic_none,
//               size: 90,
//               color: isRecording ? Colors.red : Colors.blue,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: isRecording ? null : startRecording,
//               child: const Text("Start Recording"),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: isRecording ? stopRecording : null,
//               child: const Text("Stop Recording"),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: audioPath != null ? playRecording : null,
//               child: const Text("Play Recording"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

