// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:voiceup/controllers/chat_controller.dart';
// import 'package:voiceup/models/models.dart';
// import 'package:voiceup/theme/app_theme.dart';
// import 'package:get/get.dart';

// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMe;

//   const MessageBubble({required this.message, required this.isMe});

//   @override
//   Widget build(BuildContext context) {
//     final ChatController controller = Get.find<ChatController>();

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Column(
//         crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Container(
//             margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: isMe ? Colors.blue : Colors.grey[200],
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Display Content
//                 if (message.type == MessageType.audio)
//                   const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [Icon(Icons.play_arrow), Text("Voice Message")],
//                   )
//                 else
//                   Text(
//                     message.content,
//                     style: TextStyle(color: isMe ? Colors.white : Colors.black),
//                   ),

//                 // Display Transcription if available
//                 if (message.transcription != null && message.transcription!.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top:5.0),
//                     child: Text(
//                       "Text: ${message.transcription}",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: isMe ? Colors.white70 : Colors.black54,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           // Action: Speak this message
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: InkWell(
//               onTap: () => controller.playTextAsSpeech(
//                 message.type == MessageType.audio ? (message.transcription ?? "") : message.content
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.volume_up, size: 14, color: Colors.grey),
//                   SizedBox(width: 4),
//                   Text("Listen", style: TextStyle(fontSize: 10, color: Colors.grey)),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:voiceup/models/models.dart';
// import 'package:voiceup/theme/app_theme.dart';

// class MessageBubble extends StatefulWidget {
//   final MessageModel message;
//   final bool isMyMessage;
//   final bool showTime;
//   final String timeText;
//   final VoidCallback? onLongPress;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMyMessage,
//     required this.showTime,
//     required this.timeText,
//     this.onLongPress,
//   });

//   @override
//   State<MessageBubble> createState() => _MessageBubbleState();
// }

// class _MessageBubbleState extends State<MessageBubble> {
//   late AudioPlayer _audioPlayer;
//   bool _isPlaying = false;
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.message.type == MessageType.audio) {
//       _audioPlayer = AudioPlayer();

//       // Listen to player state (playing/paused/stopped)
//       _audioPlayer.onPlayerStateChanged.listen((state) {
//         if (mounted) {
//           setState(() => _isPlaying = state == PlayerState.playing);
//         }
//       });

//       // Listen to audio duration
//       _audioPlayer.onDurationChanged.listen((newDuration) {
//         if (mounted) setState(() => _duration = newDuration);
//       });

//       // Listen to current position
//       _audioPlayer.onPositionChanged.listen((newPosition) {
//         if (mounted) setState(() => _position = newPosition);
//       });
      
//       // Reset when finished
//       _audioPlayer.onPlayerComplete.listen((event) {
//         if (mounted) setState(() => _position = Duration.zero);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     if (widget.message.type == MessageType.audio) {
//       _audioPlayer.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _playPause() async {
//     if (_isPlaying) {
//       await _audioPlayer.pause();
//     } else {
//       await _audioPlayer.play(UrlSource(widget.message.content));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         if (widget.showTime) ...[
//           const SizedBox(height: 16),
//           Center(
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//               decoration: BoxDecoration(
//                 color: AppTheme.textSecondaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 widget.timeText,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: AppTheme.textSecondaryColor,
//                     ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ] else
//           const SizedBox(height: 4),
//         Row(
//           mainAxisAlignment: widget.isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             if (!widget.isMyMessage) const SizedBox(width: 8),
//             Flexible(
//               child: GestureDetector(
//                 onLongPress: widget.onLongPress,
//                 child: Container(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.75,
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//                   decoration: BoxDecoration(
//                     color: widget.isMyMessage ? AppTheme.primaryColor : AppTheme.cardColor,
//                     borderRadius: BorderRadius.only(
//                       topLeft: const Radius.circular(20),
//                       topRight: const Radius.circular(20),
//                       bottomLeft: widget.isMyMessage ? const Radius.circular(20) : const Radius.circular(4),
//                       bottomRight: widget.isMyMessage ? const Radius.circular(4) : const Radius.circular(20),
//                     ),
//                     border: widget.isMyMessage ? null : Border.all(color: AppTheme.borderColor, width: 1),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: widget.message.type == MessageType.audio 
//                       ? _buildAudioContent() 
//                       : _buildTextContent(),
//                 ),
//               ),
//             ),
//             if (widget.isMyMessage) ...[
//               const SizedBox(width: 8),
//               _buildMessageStatus(),
//             ],
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTextContent() {
//     return Text(
//       widget.message.content,
//       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: widget.isMyMessage ? Colors.white : AppTheme.textPrimaryColor,
//           ),
//     );
//   }

//   Widget _buildAudioContent() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         IconButton(
//           constraints: const BoxConstraints(),
//           padding: EdgeInsets.zero,
//           icon: Icon(
//             _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
//             color: widget.isMyMessage ? Colors.white : AppTheme.primaryColor,
//             size: 38,
//           ),
//           onPressed: _playPause,
//         ),
//         const SizedBox(width: 8),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               width: 120,
//               child: LinearProgressIndicator(
//                 value: _duration.inMilliseconds > 0 
//                     ? _position.inMilliseconds / _duration.inMilliseconds 
//                     : 0.0,
//                 backgroundColor: widget.isMyMessage 
//                     ? Colors.white.withOpacity(0.2) 
//                     : AppTheme.primaryColor.withOpacity(0.1),
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   widget.isMyMessage ? Colors.white : AppTheme.primaryColor,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               _formatDuration(_isPlaying ? _position : _duration),
//               style: TextStyle(
//                 fontSize: 10,
//                 color: widget.isMyMessage ? Colors.white70 : AppTheme.textSecondaryColor,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$twoDigitMinutes:$twoDigitSeconds";
//   }

//   Widget _buildMessageStatus() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 4),
//       child: Icon(
//         widget.message.isRead ? Icons.done_all : Icons.done,
//         size: 16,
//         color: widget.message.isRead ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
//       ),
//     );
//   }
// }








import 'package:flutter/material.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final bool showTime;
  final String timeText;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showTime,
    required this.timeText,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTime) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ] else
          SizedBox(height: 4),
        Row(
          mainAxisAlignment: isMyMessage
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMyMessage) ...[
              SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ), // BoxConstraints
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? AppTheme.primaryColor
                        : AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: isMyMessage
                          ? Radius.circular(20)
                          : Radius.circular(4),
                      bottomRight: isMyMessage
                          ? Radius.circular(4)
                          : Radius.circular(20),
                    ),
                          border: isMyMessage
                          ? null
                              : Border.all(color: AppTheme.borderColor, width: 1),
                          boxShadow: [
                          BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          ),
                          ],
                          ),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isMyMessage
                          ? Colors.white
                          : AppTheme.textPrimaryColor,
                    ),
                    ),
                    if (message.isEdited) ...[
                    SizedBox(height: 4),
                    Text(
                    "Edited",
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(
                    color: isMyMessage
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                    ),
                    ),
                    ],
                    ],
                    ),
                    ),
     ),
  ),
    if (isMyMessage) ...[SizedBox(width: 8), _buildMessageStatus()],
 ],
),
],
);
}
  Widget _buildMessageStatus() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Icon(
        message.isRead ? Icons.done_all : Icons.done,
        size: 16,
        color: message.isRead
            ? AppTheme.primaryColor
            : AppTheme.textSecondaryColor,
      ),
    );
  }
}