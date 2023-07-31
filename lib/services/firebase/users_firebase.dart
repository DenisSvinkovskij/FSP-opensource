import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_safe_places/models/user.dart';
import 'package:find_safe_places/utils/exeption.dart';
import 'package:find_safe_places/utils/index.dart';

class UsersFirebase {
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(
      userId) async {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  static Future<void> updateUser(
      String userId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true))
        .onError((error, stackTrace) => print(error))
        .catchError((onError) {
      log('$onError');
    });
  }

  static Future<void> updateUserForFamily(
      String userId, Map<String, dynamic> data, List familyIds) async {
    if (familyIds.length > 500) {
      throw CustomException('Family too big');
    }

    var batch = FirebaseFirestore.instance.batch();

    for (var id in familyIds) {
      String doc = 'users/$id/userFamily/$userId';
      batch.set(
        FirebaseFirestore.instance.doc(doc),
        data,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  static Stream getUsersSafePlaces(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userSafePlaces')
        .snapshots();
  }

  static saveSafePlace(
    String userId,
    Map<String, dynamic> data,
    String? savedPlaceDocId,
  ) async {
    dynamic query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userSafePlaces');

    if (savedPlaceDocId != null) {
      query = query.doc(savedPlaceDocId);
    } else {
      query = query.doc();
    }

    await query.set(data, SetOptions(merge: true));
  }

  static Future<List<UserModel>> findUsersBy({
    required String field,
    required dynamic value,
  }) async {
    if (field == 'id') {
      final user = await getUserDoc(value);
      final userJson = user.data();
      if (userJson == null) {
        return [];
      }
      return [UserModel.fromJson(userJson)];
    }
    return FirebaseFirestore.instance
        .collection('users')
        .where(
          field,
          isEqualTo: value,
        )
        .get()
        .then((value) => firestoreCollectionToArray(value))
        .then((value) => value.map((e) => UserModel.fromJson(e)).toList());
  }

  static Stream getClosePersons(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFamily')
        .snapshots();
  }

  static Stream getClosePersonsByStatus(String userId, String status) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFamily')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  static Stream getRequestsInClosePersons(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('userFamilyRequests')
        .snapshots();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserNotification(
    String userId,
    String notificationId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .get();
  }

  static Future<void> setUserNotification({
    required String userId,
    required Map<String, dynamic> data,
    String? notificationId,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .set({...data, 'createdAt': DateTime.now()}, SetOptions(merge: true));
  }
}
