import 'package:flutter/material.dart';
import 'package:nabtatcompany/services/notification_service.dart';
import 'package:nabtatcompany/models/app_notification.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: NotificationService().getAllNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return const Center(
              child: Text('لا توجد إشعارات'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(n.title),
                subtitle: Text(n.body),
                trailing: Text(
                  DateFormat('yyyy-MM-dd').format(n.scheduledDate),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
