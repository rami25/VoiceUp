import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:voiceup/controllers/friend_requests_controller.dart';
import 'package:voiceup/theme/app_theme.dart';
import 'package:voiceup/views/widgets/friend_request_item.dart';

class FriendRequestsView extends GetView<FriendRequestsController> {
  const FriendRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildTabToggle(),
          Expanded(
            child: Obx(() {
              // Using a simple Switch or IndexedStack based on the selected tab
              return RefreshIndicator(
                onRefresh: () async => controller.loadFriendRequests(), // Assuming you have this method
                child: controller.selectedTabIndex == 0
                    ? _buildReceivedRequestsTab()
                    : _buildSentRequestsTab(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Obx(() => Row(
            children: [
              _buildTabButton(
                index: 0,
                label: 'Received (${controller.receivedRequests.length})',
                icon: Icons.inbox,
              ),
              _buildTabButton(
                index: 1,
                label: 'Sent (${controller.sentRequests.length})',
                icon: Icons.send,
              ),
            ],
          )),
    );
  }

  Widget _buildTabButton({required int index, required String label, required IconData icon}) {
    final isSelected = controller.selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceivedRequestsTab() {
    if (controller.receivedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No Friend Requests',
        message: 'When someone sends you a friend request, it will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.receivedRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final request = controller.receivedRequests[index];
        final sender = controller.getUser(request.senderId);

        if (sender == null) return const SizedBox.shrink();

        return FriendRequestItem(
          request: request,
          user: sender,
          timeText: controller.getRequestTimeText(request.createdAt),
          isReceived: true,
          onAccept: () => controller.acceptRequest(request),
          onDecline: () => controller.declineFriendRequest(request),
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
    // FIX: Checked sentRequests instead of receivedRequests
    if (controller.sentRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        title: 'No Sent Requests',
        message: 'Friend requests you send will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.sentRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final request = controller.sentRequests[index];
        // FIX: For sent requests, we want the data of the RECEIVER
        final receiver = controller.getUser(request.receiverId);

        if (receiver == null) return const SizedBox.shrink();

        return FriendRequestItem(
          request: request,
          user: receiver,
          timeText: controller.getRequestTimeText(request.createdAt),
          isReceived: false,
          statusText: controller.getStatusText(request.status),
          statusColor: controller.getStatusColor(request.status),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String message}) {
    return Center(
      child: SingleChildScrollView( // Added scrollview to prevent overflow on small screens
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(title, style: Get.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: Get.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_navigation/src/extension_navigation.dart';
// import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
// import 'package:get/get_state_manager/src/simple/get_view.dart';
// import 'package:voiceup/controllers/friend_requests_controller.dart';
// import 'package:voiceup/theme/app_theme.dart';
// import 'package:voiceup/views/widgets/friend_request_item.dart';

// class FriendRequestsView extends GetView<FriendRequestsController> {
//   const FriendRequestsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: Text('Friend Requests'),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () => Get.back(),
//           ),
//         ),

//         body: Column(
//           children: [
//             Container(
//               margin: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppTheme.cardColor,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppTheme.borderColor),
//               ),
//               child: Obx(() =>
//                   Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => controller.changeTab(0),
//                           child: Container(
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               decoration: BoxDecoration(
//                                   color: controller.selectedTabIndex == 0
//                                       ? AppTheme.primaryColor
//                                       : Colors.transparent,
//                                   borderRadius: BorderRadius.circular(12)
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.inbox,
//                                     color: controller.selectedTabIndex == 0
//                                         ? Colors.white
//                                         : AppTheme.textSecondaryColor,
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     'Received (${controller.receivedRequests
//                                         .length})',
//                                     style: TextStyle(
//                                       color: controller.selectedTabIndex == 0
//                                           ? Colors.white
//                                           : AppTheme.textSecondaryColor,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => controller.changeTab(1),
//                           child: Container(
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               decoration: BoxDecoration(
//                                   color: controller.selectedTabIndex == 1
//                                       ? AppTheme.primaryColor
//                                       : Colors.transparent,
//                                   borderRadius: BorderRadius.circular(12)
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.send,
//                                     color: controller.selectedTabIndex == 1
//                                         ? Colors.white
//                                         : AppTheme.textSecondaryColor,
//                                   ),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     'Sent (${controller.sentRequests.length})',
//                                     style: TextStyle(
//                                       color: controller.selectedTabIndex == 1
//                                           ? Colors.white
//                                           : AppTheme.textSecondaryColor,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//               ),
//             ),
//             Expanded(
//               child: Obx(() {
//                 return IndexedStack(
//                   index: controller.selectedTabIndex,
//                   children: [
//                     _buildReceivedRequestsTab(),
//                     _buildSentRequestsTab(),
//                   ],
//                 );
//               }),
//             ),

//           ],
//         )
//     );
//   }

//   Widget _buildReceivedRequestsTab() {
//     return Obx(() {
//       if (controller.receivedRequests.isEmpty) {
//         return _buildEmptyState(
//           icon: Icons.inbox_outlined,
//           title: 'No Friend Requests',
//           message: 'When someone sends you a friend request, it will appear here.',
//         );
//       }
//       return ListView.separated(
//         padding: EdgeInsets.all(16),
//         itemCount: controller.receivedRequests.length,
//         separatorBuilder: (context, index) => SizedBox(height: 8),
//         itemBuilder: (context, index) {
//           final request = controller.receivedRequests[index];
//           final sender = controller.getUser(request.senderId);

//           if (sender == null) {
//             return SizedBox.shrink();
//           }
//           return FriendRequestItem(
//             request: request,
//             user: sender,
//             timeText: controller.getRequestTimeText(request.createdAt),
//             isReceived: true,
//             onAccept: () => controller.acceptRequest(request),
//             onDecline: () => controller.declineFriendRequest(request),
//           );
//         },
//       );
//     });
//   }

//   Widget _buildSentRequestsTab() {
//     return Obx(() {
//       if (controller.receivedRequests.isEmpty) {
//         return _buildEmptyState(
//           icon: Icons.inbox_outlined,
//           title: 'No Sent Requests',
//           message: 'Friend Requests you send will appear here.',
//         );
//       }
//       return ListView.separated(
//         padding: EdgeInsets.all(16),
//         itemCount: controller.sentRequests.length,
//         separatorBuilder: (context, index) => SizedBox(height: 8),
//         itemBuilder: (context, index) {
//           final request = controller.sentRequests[index];
//           final receiver = controller.getUser(request.senderId);

//           if (receiver == null) {
//             return SizedBox.shrink();
//           }
//           return FriendRequestItem(
//             request: request,
//             user: receiver,
//             timeText: controller.getRequestTimeText(request.createdAt),
//             isReceived: false,
//             statusText: controller.getStatusText(request.status),
//             statusColor: controller.getStatusColor(request.status),
//           );
//         },
//       );
//     });
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String message,
//   }) {
//     return Center(
//       child: Padding(
//         padding:  EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: AppTheme.primaryColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(50),
//               ),
//               child: Icon(
//                 icon,
//                 size: 40,
//                 color: AppTheme.primaryColor,
//               ),
//             ),
//             SizedBox(height: 24),
//             Text(
//               title,
//               style: Get.textTheme.headlineSmall?.copyWith(
//                 color: AppTheme.textPrimaryColor,
//               ),
//             ),
//             SizedBox(height: 8),
//             Text(
//               message,
//               style: Get.textTheme.bodyMedium?.copyWith(
//                 color: AppTheme.textSecondaryColor,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }}