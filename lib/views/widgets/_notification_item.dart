import 'package:flutter/material.dart';
import 'package:voiceup/models/models.dart';
import 'package:voiceup/theme/app_theme.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final UserModel? user;
  final String timeText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.user,
    required this.timeText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead
          ? Colors.transparent
          : AppTheme.primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.grey.shade200 : AppTheme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Show User Avatar if available, otherwise show Category Icon
              _buildLeadingImage(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getNotificationBody(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingImage() {
    // If we have user data (like for friend requests), show their profile picture
    if (user != null && user!.photoURL!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(user!.photoURL!),
      );
    }

    // Default: Show the notification type icon
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  String _getNotificationBody() {
    if (user == null) return notification.body;

    final name = user!.displayName.isNotEmpty ? user!.displayName : 'Someone';

    switch (notification.type) {
      case NotificationType.friendRequest:
        return '$name sent you a friend request';
      case NotificationType.friendRequestAccepted:
        return '$name accepted your friend request';
      case NotificationType.friendRequestDeclined:
        return '$name declined your friend request';
      case NotificationType.newMessage:
        return '$name sent you a message';
      case NotificationType.friendRemoved:
        return 'You are no longer friends with $name';
      case NotificationType.system:
        return notification.body;
      default:
        return notification.body;
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:voiceup/models/models.dart';
// import 'package:voiceup/theme/app_theme.dart';

// class NotificationItem extends StatelessWidget {
//   final NotificationModel notification;
//   final UserModel? user;
//   final String timeText;
//   final IconData icon;
//   final Color iconColor;
//   final VoidCallback onTap;
//   final VoidCallback onDelete;

//   const NotificationItem({
//     super.key,
//     required this.notification,
//     this.user,
//     required this.timeText,
//     required this.icon,
//     required this.iconColor,
//     required this.onTap,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: notification.isRead
//           ? null
//           : AppTheme.primaryColor.withOpacity(0.05),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: iconColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: Icon(icon, color: iconColor, size: 24),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                 Row(
//                 children: [
//                 Expanded(
//                 child: Text(
//                   notification.title,
//                   style: Theme.of(context).textTheme.bodyLarge
//                       ?.copyWith(
//                     fontWeight: notification.isRead
//                         ? FontWeight.normal
//                         : FontWeight.w600,
//                   ),
//                 ),
//                 ),
//                   if (!notification.isRead)
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: AppTheme.primaryColor,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//           ],
//               ),
//                     SizedBox(height: 4),
//                     Text(
//                       _getNotificationBody(),
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppTheme.textSecondaryColor,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       timeText,
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppTheme.textSecondaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 onPressed: onDelete,
//                 icon: Icon(Icons.close),
//                 color: AppTheme.textSecondaryColor,
//                 iconSize: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//   String _getNotificationBody() {
//     String body = notification.body;

//     if (user != null) {
//       switch (notification.type) {
//         case NotificationType.friendRequest:
//           body = '${user!.displayName} sent you a friend request';
//           break;

//         case NotificationType.friendRequestAccepted:
//           body = '${user!.displayName} accepted your friend request';
//           break;

//         case NotificationType.friendRequestDeclined:
//           body = '${user!.displayName} declined your friend request';
//           break;

//         case NotificationType.newMessage:
//           body = '${user!.displayName} sent you a message';
//           break;

//         case NotificationType.friendRemoved:
//           body = 'You are no longer friends with${user!.displayName}';
//           break;
//         case NotificationType.system:
//           // TODO: Handle this case.
//           throw UnimplementedError();
//       }
//     }
//     return body;
//   }
// }