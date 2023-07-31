import 'package:dio/dio.dart';
import 'package:find_safe_places/constants/map.dart';
import 'package:find_safe_places/services/httpRequests/index.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

String baseUrlDirections = 'https://api.mapbox.com/directions/v5/mapbox';

Future getMapboxRoute(LatLng source, LatLng destination, String type) async {
  String url =
      '$baseUrlDirections/$type/${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&access_token=$kMapAccessToken';
  try {
    dio.options.contentType = Headers.jsonContentType;
    final response = await dio.get(url);
    return response.data;
  } catch (e) {
    debugPrint(e.toString());
  }
}
