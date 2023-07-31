import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

Map<dynamic, dynamic> pick(object, keys) {
  Map<dynamic, dynamic> pickObject = {};
  for (var i = 0; i < keys.length; i++) {
    if (object[keys[i]] != null) {
      pickObject[keys[i]] = object[keys[i]];
    }
  }
  return pickObject;
}

List firestoreCollectionToArray(QuerySnapshot<Map<String, dynamic>>? snaps) {
  List data = [];

  if (snaps == null) return data;

  for (var element in snaps.docs) {
    data.add(getDocWithId(element));
  }
  return data;
}

Map<String, dynamic>? getDocWithId(snap) {
  return snap.exists
      ? {
          ...snap.data(),
          'id': snap.id,
        }
      : null;
}

Color hexToColorOrRandomColor(String? code) {
  if (code == null) {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}
