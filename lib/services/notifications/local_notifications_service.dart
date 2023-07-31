import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:find_safe_places/constants/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void notificationTapBackground(NotificationResponse notificationResponse) {
  log('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload} 2');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    log('notification action tapped with input: ${notificationResponse.input}');
  }
}

class LocalNotificationService {
  static final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> setup(
      StreamController<String?> selectNotificationStream) async {
    const androidSetting = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const initSettings = InitializationSettings(
        android: androidSetting, iOS: initializationSettingsDarwin);

    await _localNotificationsPlugin
        .initialize(
          initSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse notificationResponse) {
            log('notificationResponse.actionId ${notificationResponse.actionId}');
            log('notificationResponse.id ${notificationResponse.id}');
            if (notificationResponse.payload != null) {
              String data =
                  '${notificationResponse.actionId}|${notificationResponse.payload}';
              selectNotificationStream.add(data);
            }
          },
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        )
        .then((_) {})
        .catchError((Object error) {
          debugPrint('Error: $error');
        });
  }

  static Future<void> showNotification(String title, String details) async {
    const androidDetail = AndroidNotificationDetails(
        "alert-channel", // channel Id
        "App Alerts" // channel Name
        );

    const iosDetail = DarwinNotificationDetails();

    const noticeDetail = NotificationDetails(
      iOS: iosDetail,
      android: androidDetail,
    );

    const id = 0;

    await _localNotificationsPlugin.show(
      id,
      title,
      details,
      noticeDetail,
    );
  }

  static Future<void> showNotificationAboutEmergency(
    String title,
    String body,
  ) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      "alert-channel", // channel Id
      "App Alerts", // channel Name
      channelDescription: 'Emergencies and other',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kOpenActionId,
          tr('in_safe_place'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          kNavigationActionId,
          tr('emergency_actions'),
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      categoryIdentifier: kDarwinNotificationCategoryPlain,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    const id = 1;

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: 'ActionsInEmergencies',
    );
  }
}
