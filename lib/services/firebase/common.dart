import 'package:cloud_firestore/cloud_firestore.dart';

class CommonFirebase {
  static Stream getEmergencies() {
    return FirebaseFirestore.instance.collection('emergencies').snapshots();
  }

  static Future createByStringReference({
    required String ref,
    required Map<String, dynamic> data,
  }) async {
    return FirebaseFirestore.instance
        .doc(ref)
        .set(data, SetOptions(merge: true))
        .then((value) => data);
  }

  static Future deleteDocByStringReference({required String ref}) async {
    return FirebaseFirestore.instance.doc(ref).delete();
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getEmergenciesInfo() {
    return FirebaseFirestore.instance
        .collection('data')
        .doc('emergenciesInfo')
        .get();
  }
}
