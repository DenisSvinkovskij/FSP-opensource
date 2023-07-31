import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

Dio dio = Dio();

Future<void> sendFamilyInvitation(Map<String, dynamic> payload) async {
  String url =
      'https://us-central1-find-safe-place.cloudfunctions.net/sendInviteToApp';

  try {
    dio.options.contentType = Headers.jsonContentType;
    await dio.post(url, data: payload);
    return;
  } catch (e) {
    debugPrint(e.toString());
  }
}

Future<Map<String, dynamic>?> getAllShelters() async {
  String url =
      'https://us-central1-find-safe-place-ed77a.cloudfunctions.net/api/all-shelters';

  try {
    dio.options.contentType = Headers.jsonContentType;
    final response = await dio.get(url);
    return response.data;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}
