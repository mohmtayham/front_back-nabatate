// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'dart:io' show Platform;

// import '../../firebase_options.dart';

// /// Background handler (Android / iOS فقط)
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
// }

// /// Local notifications (غير مدعوم على Web)
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> setupFlutterNotifications() async {
//   if (kIsWeb) return;

//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const DarwinInitializationSettings iosSettings =
//       DarwinInitializationSettings();

//   const InitializationSettings settings = InitializationSettings(
//     android: androidSettings,
//     iOS: iosSettings,
//   );

//   await flutterLocalNotificationsPlugin.initialize(settings);
// }

// class FirebaseNotifications {
//   final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

//   /// Initialize Firebase + Notifications
//   static Future<void> initializeFirebase() async {
//     try {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );

//       if (!kIsWeb) {
//         FirebaseMessaging.onBackgroundMessage(
//           _firebaseMessagingBackgroundHandler,
//         );
//       }

//       await FirebaseNotifications().initNotifications();

//       if (!kIsWeb) {
//         await setupFlutterNotifications();
//       }
//     } catch (e) {
//       debugPrint('Error initializing Firebase: $e');
//     }
//   }

//   /// Init notifications safely for all platforms
//   Future<void> initNotifications() async {
//     try {
//       // Request permission (Web / Mobile)
//       NotificationSettings settings =
//           await firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );

//       if (settings.authorizationStatus ==
//           AuthorizationStatus.authorized) {
//         debugPrint('Notification permission granted');
//       } else {
//         debugPrint('Notification permission denied');
//         return;
//       }

//       // iOS only (not Web)
//       if (!kIsWeb && Platform.isIOS) {
//         String? apnsToken =
//             await firebaseMessaging.getAPNSToken();
//         debugPrint('APNS Token: $apnsToken');
//       }

//       // FCM Token (Web + Mobile)
//       if (!kReleaseMode) {
//         String? token = await firebaseMessaging.getToken();
//         debugPrint('FCM Token: $token');
//       }

//       handleForegroundNotification();
//       handleBackgroundNotification();
//     } catch (e) {
//       debugPrint('Error initializing notifications: $e');
//     }
//   }

//   /// Foreground notifications
//   void handleForegroundNotification() {
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint('Notification arrived');

//       if (!kIsWeb && message.notification != null) {
//         showNotification(
//           message.notification!.title,
//           message.notification!.body,
//         );
//       }
//     });
//   }

//   /// Background & terminated notifications
//   Future<void> handleBackgroundNotification() async {
//     FirebaseMessaging.instance.getInitialMessage().then((message) {});

//     FirebaseMessaging.onMessageOpenedApp.listen((message) {});
//   }

//   /// Local notification (Android / iOS فقط)
//   void showNotification(String? title, String? body) async {
//     if (kIsWeb) return;

//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'channel_id',
//       'channel_name',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: DarwinNotificationDetails(),
//     );

//     await flutterLocalNotificationsPlugin.show(
//       0,
//       title,
//       body,
//       details,
//     );
//   }
// }
