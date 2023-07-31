class SafePlacePointModel {
  late String id;
  late String geometry;
  late Map<String, dynamic>? coordinates;

  SafePlacePointModel({
    required this.id,
    required this.geometry,
    this.coordinates,
  });

  SafePlacePointModel.fromJson(Map<String, dynamic> json) {
    geometry = json['geometry'] as String;
    id = json['id'] as String;
    coordinates = json['coordinates'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['geometry'] = geometry;
    json['id'] = id;
    json['coordinates'] = coordinates;
    return json;
  }
}
