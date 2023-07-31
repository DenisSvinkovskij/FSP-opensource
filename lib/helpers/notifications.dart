import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/services/firebase/users_firebase.dart';
import 'package:find_safe_places/services/notifications/local_notifications_service.dart';

sendNotificationAboutEmergency(String emergencyId, dynamic title, dynamic body,
    UserModel? user, List localSendedNotificationIds) async {
  if (user != null) {
    var sendedNotify =
        await UsersFirebase.getUserNotification(user.uid, emergencyId);
    if (sendedNotify.exists) return;

    Map<String, dynamic> data = {
      'emergencyId': emergencyId,
      'title': title,
      'body': body,
    };

    await UsersFirebase.setUserNotification(
      userId: user.uid,
      data: data,
      notificationId: emergencyId,
    );
  }
  if (localSendedNotificationIds.contains(emergencyId)) {
    return;
  }

  await LocalNotificationService.showNotificationAboutEmergency(
    title ?? "",
    body ?? "",
  );
}
