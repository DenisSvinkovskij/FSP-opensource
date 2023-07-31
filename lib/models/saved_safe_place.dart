import 'package:cloud_firestore/cloud_firestore.dart';

class SavedSafePlaceModel {
  late String address;
  late GeoPoint location;
  late String name;
  late String? id;
  late String? firstLetter;
  late String? placeId;
  late Map<String, dynamic>? additionalInfo;

  SavedSafePlaceModel({
    required this.address,
    required this.location,
    required this.name,
    this.id,
    this.firstLetter,
    this.placeId,
    this.additionalInfo,
  });

  SavedSafePlaceModel.fromJson(Map<String, dynamic> json) {
    address = json['address'] as String;
    location = json['location'] as GeoPoint;
    name = json['name'] as String;
    id = json['id'] as String;
    placeId = json['placeId'];
    firstLetter = (json['name'] as String).trimLeft()[0];
    additionalInfo = json['additionalInfo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['address'] = address;
    json['location'] = location;
    json['name'] = name;
    json['placeId'] = placeId;
    json['additionalInfo'] = additionalInfo;
    return json;
  }
}
